// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2021 Marco Baye
// Have a look at "acme.c" for further info
//
// Arithmetic/logic unit
// 11 Oct 2006	Improved float reading in parse_number_literal()
// 24 Nov 2007	Now accepts floats starting with decimal point
// 31 Jul 2009	Changed ASR again, just to be on the safe side.
// 14 Jan 2014	Changed associativity of "power-of" operator,
//		so a^b^c now means a^(b^c).
//  7 May 2014	C-style "==" operators are now recognized.
// 31 May 2014	Added "0b" binary number prefix as alternative to "%".
// 28 Apr 2015	Added symbol name output to "value not defined" error.
//  1 Feb 2019	Prepared to make "honor leading zeroes" optionally (now done)

// the words "operand"/"operator"/"operation" are too similar, so:
//	"op" means operator/operation
//	"arg" means argument (used instead of "operand")

#include "alu.h"
#include <stdlib.h>
#include <math.h>	// only for fp support
#include <string.h>	// for memcpy()
#include "platform.h"
#include "dynabuf.h"
#include "encoding.h"
#include "global.h"
#include "input.h"
#include "output.h"
#include "section.h"
#include "symbol.h"
#include "tree.h"


// constants

#define ERRORMSG_INITIALSIZE	256	// ad hoc
#define FUNCTION_INITIALSIZE	8	// enough for "arctan"
#define HALF_INITIAL_STACK_SIZE	8
static const char	exception_div_by_zero[]	= "Division by zero.";
static const char	exception_no_value[]	= "No value given.";
static const char	exception_paren_open[]	= "Too many '('.";
static const char	exception_not_number[]	= "Expression did not return a number.";
static const char	exception_float_to_int[]= "Converted to integer for binary logic operator.";
static const char	exception_lengthnot1[]	= "String length is not 1.";

enum op_group {
	OPGROUP_SPECIAL,	// start/end of expression, and parentheses
	OPGROUP_MONADIC,	// {result} = {op} {arg}
	OPGROUP_DYADIC		// {result} = {arg1} {op} {arg2}
};
enum op_id {
	// special (pseudo) operators:
	OPID_TERMINATOR,	//		(preliminary) end of expression (quasi-dyadic)
	OPID_START_EXPRESSION,	//		start of expression
	OPID_SUBEXPR_PAREN,	//	(v	'(' starts subexpression (quasi-monadic)
	OPID_START_LIST,	//	[1,2]	'[' starts non-empty list literal (quasi-monadic, followed by dyadic OPID_LIST_APPEND)
	OPID_SUBEXPR_BRACKET,	//	v[	'[' starts subexpression (quasi-monadic, after dyadic OPID_ATINDEX)
	// monadic operators (including functions):
	OPID_NOT,		//	!v	NOT v		bit-wise NOT
	OPID_NEGATE,		//	-v			negation
	OPID_LOWBYTEOF,		//	<v			low byte of
	OPID_HIGHBYTEOF,	//	>v			high byte of
	OPID_BANKBYTEOF,	//	^v			bank byte of
	OPID_ADDRESS,		//	addr(v)				FIXME - add nonaddr()?
	OPID_INT,		//	int(v)
	OPID_FLOAT,		//	float(v)
	OPID_SIN,		//	sin(v)
	OPID_COS,		//	cos(v)
	OPID_TAN,		//	tan(v)
	OPID_ARCSIN,		//	arcsin(v)
	OPID_ARCCOS,		//	arccos(v)
	OPID_ARCTAN,		//	arctan(v)
	OPID_LEN,		//	len(v)
	OPID_ISNUMBER,		//	is_number(v)
	OPID_ISLIST,		//	is_list(v)
	OPID_ISSTRING,		//	is_string(v)
// add CHR function to create 1-byte string? or rather add \xAB escape sequence?
	// dyadic operators:
	OPID_POWEROF,		//	v^w
	OPID_MULTIPLY,		//	v*w
	OPID_DIVIDE,		//	v/w				division
	OPID_INTDIV,		//	v/w	v DIV w			integer division
	OPID_MODULO,		//	v%w	v MOD w			remainder
	OPID_SHIFTLEFT,		//	v<<w	v ASL w	v LSL w		shift left
	OPID_ASR,		//	v>>w	v ASR w			arithmetic shift right
	OPID_LSR,		//	v>>>w	v LSR w			logical shift right
	OPID_ADD,		//	v+w
	OPID_SUBTRACT,		//	v-w
	OPID_EQUALS,		//	v=w
	OPID_LESSOREQUAL,	//	v<=w
	OPID_LESSTHAN,		//	v< w
	OPID_GREATEROREQUAL,	//	v>=w
	OPID_GREATERTHAN,	//	v> w
	OPID_NOTEQUAL,		//	v!=w	v<>w	v><w
	OPID_AND,		//	v&w		v AND w
	OPID_OR,		//	v|w		v OR w
	OPID_EOR,		//	v EOR w		v XOR w		FIXME - remove
	OPID_XOR,		//	v XOR w
	OPID_LIST_APPEND,	//			used internally when building list literal
	OPID_ATINDEX,		//	v[w]
};
struct op {
	int		priority;
	enum op_group	group;
	enum op_id	id;
	const char	*text_version;
};
static struct op ops_terminating_char	= {0, OPGROUP_SPECIAL,	OPID_TERMINATOR,	"end of expression"	};
static struct op ops_start_expression	= {2, OPGROUP_SPECIAL,	OPID_START_EXPRESSION,	"start of expression"	};
static struct op ops_subexpr_paren	= {4, OPGROUP_SPECIAL,	OPID_SUBEXPR_PAREN,	"left parenthesis"	};
static struct op ops_start_list		= {6, OPGROUP_SPECIAL,	OPID_START_LIST,	"start list"	};
static struct op ops_subexpr_bracket	= {8, OPGROUP_SPECIAL,	OPID_SUBEXPR_BRACKET,	"open index"	};
static struct op ops_list_append	= {14, OPGROUP_DYADIC,	OPID_LIST_APPEND,	"append to list"	};
static struct op ops_or			= {16, OPGROUP_DYADIC,	OPID_OR,	"logical or"	};
static struct op ops_eor		= {18, OPGROUP_DYADIC,	OPID_EOR,	"exclusive or"	};	// FIXME - remove
static struct op ops_xor		= {18, OPGROUP_DYADIC,	OPID_XOR,	"exclusive or"	};
static struct op ops_and		= {20, OPGROUP_DYADIC,	OPID_AND,	"logical and"	};
static struct op ops_equals		= {22, OPGROUP_DYADIC,	OPID_EQUALS,		"test for equality"	};
static struct op ops_not_equal		= {24, OPGROUP_DYADIC,	OPID_NOTEQUAL,		"test for inequality"	};
	// same priority for all comparison operators
static struct op ops_less_or_equal	= {26, OPGROUP_DYADIC,	OPID_LESSOREQUAL,	"less than or equal"	};
static struct op ops_less_than		= {26, OPGROUP_DYADIC,	OPID_LESSTHAN,		"less than"	};
static struct op ops_greater_or_equal	= {26, OPGROUP_DYADIC,	OPID_GREATEROREQUAL,	"greater than or equal"	};
static struct op ops_greater_than	= {26, OPGROUP_DYADIC,	OPID_GREATERTHAN,	"greater than"	};
	// same priority for all byte extraction operators
static struct op ops_low_byte_of	= {28, OPGROUP_MONADIC,	OPID_LOWBYTEOF,		"low byte of"	};
static struct op ops_high_byte_of	= {28, OPGROUP_MONADIC,	OPID_HIGHBYTEOF,	"high byte of"	};
static struct op ops_bank_byte_of	= {28, OPGROUP_MONADIC,	OPID_BANKBYTEOF,	"bank byte of"	};
	// same priority for all shift operators (left-associative, though they could be argued to be made right-associative :))
static struct op ops_shift_left		= {30, OPGROUP_DYADIC,	OPID_SHIFTLEFT,	"shift left"	};
static struct op ops_asr		= {30, OPGROUP_DYADIC,	OPID_ASR,	"arithmetic shift right"	};
static struct op ops_lsr		= {30, OPGROUP_DYADIC,	OPID_LSR,	"logical shift right"	};
	// same priority for "+" and "-"
static struct op ops_add		= {32, OPGROUP_DYADIC,	OPID_ADD,	"addition"	};
static struct op ops_subtract		= {32, OPGROUP_DYADIC,	OPID_SUBTRACT,	"subtraction"	};
	// same priority for "*", "/" and "%"
static struct op ops_multiply		= {34, OPGROUP_DYADIC,	OPID_MULTIPLY,	"multiplication"	};
static struct op ops_divide		= {34, OPGROUP_DYADIC,	OPID_DIVIDE,	"division"	};
static struct op ops_intdiv		= {34, OPGROUP_DYADIC,	OPID_INTDIV,	"integer division"	};
static struct op ops_modulo		= {34, OPGROUP_DYADIC,	OPID_MODULO,	"modulo"	};
	// highest "real" priorities
static struct op ops_negate		= {36, OPGROUP_MONADIC,	OPID_NEGATE,	"negation"	};
#define PRIO_POWEROF			37	// the single right-associative operator, so this gets checked explicitly
static struct op ops_powerof		= {PRIO_POWEROF, OPGROUP_DYADIC,	OPID_POWEROF,	"power of"	};
static struct op ops_not		= {38, OPGROUP_MONADIC,	OPID_NOT,	"logical not"	};
static struct op ops_atindex		= {40, OPGROUP_DYADIC,	OPID_ATINDEX,	"indexing"	};
	// function calls act as if they were monadic operators.
	// they need high priorities to make sure they are evaluated once the
	// parentheses' content is known:
	// "sin(3 + 4) DYADIC_OPERATOR 5" becomes "sin 7 DYADIC_OPERATOR 5",
	// so function calls' priority must be higher than all dyadic operators.
static struct op ops_addr		= {42, OPGROUP_MONADIC, OPID_ADDRESS,	"address()"	};
static struct op ops_int		= {42, OPGROUP_MONADIC, OPID_INT,	"int()"	};
static struct op ops_float		= {42, OPGROUP_MONADIC, OPID_FLOAT,	"float()"	};
static struct op ops_sin		= {42, OPGROUP_MONADIC, OPID_SIN,	"sin()"	};
static struct op ops_cos		= {42, OPGROUP_MONADIC, OPID_COS,	"cos()"	};
static struct op ops_tan		= {42, OPGROUP_MONADIC, OPID_TAN,	"tan()"	};
static struct op ops_arcsin		= {42, OPGROUP_MONADIC, OPID_ARCSIN,	"arcsin()"	};
static struct op ops_arccos		= {42, OPGROUP_MONADIC, OPID_ARCCOS,	"arccos()"	};
static struct op ops_arctan		= {42, OPGROUP_MONADIC, OPID_ARCTAN,	"arctan()"	};
static struct op ops_len		= {42, OPGROUP_MONADIC, OPID_LEN,	"len()"	};
static struct op ops_isnumber		= {42, OPGROUP_MONADIC, OPID_ISNUMBER,	"is_number()"	};
static struct op ops_islist		= {42, OPGROUP_MONADIC, OPID_ISLIST,	"is_list()"	};
static struct op ops_isstring		= {42, OPGROUP_MONADIC, OPID_ISSTRING,	"is_string()"	};


// variables
static	STRUCT_DYNABUF_REF(errormsg_dyna_buf, ERRORMSG_INITIALSIZE);	// to build variable-length error messages
static	STRUCT_DYNABUF_REF(function_dyna_buf, FUNCTION_INITIALSIZE);	// for fn names
// operator stack, current size and stack pointer:
static struct op	**op_stack	= NULL;
static int		opstack_size	= HALF_INITIAL_STACK_SIZE;
static int		op_sp;
// argument stack, current size and stack pointer:
static struct object	*arg_stack	= NULL;
static int		argstack_size	= HALF_INITIAL_STACK_SIZE;
static int		arg_sp;
enum alu_state {
	STATE_EXPECT_ARG_OR_MONADIC_OP,
	STATE_EXPECT_DYADIC_OP,
	STATE_MAX_GO_ON,	// "border value" to find the stoppers:
	STATE_ERROR,		// error has occurred
	STATE_END		// standard end
};
static enum alu_state	alu_state;	// deterministic finite automaton
// predefined stuff
static struct ronode	op_tree[]	= {
	PREDEF_START,
	PREDEFNODE("asr",	&ops_asr),
	PREDEFNODE("lsr",	&ops_lsr),
	PREDEFNODE("asl",	&ops_shift_left),
	PREDEFNODE("lsl",	&ops_shift_left),
	PREDEFNODE("div",	&ops_intdiv),
	PREDEFNODE("mod",	&ops_modulo),
	PREDEFNODE("and",	&ops_and),
	PREDEFNODE("or",	&ops_or),
	PREDEFNODE("eor",	&ops_eor),		// FIXME - remove
	PREDEF_END("xor",	&ops_xor),
	//    ^^^^ this marks the last element
};
static struct ronode	function_tree[]	= {
	PREDEF_START,
	PREDEFNODE("addr",	&ops_addr),
	PREDEFNODE("address",	&ops_addr),
	PREDEFNODE("int",	&ops_int),
	PREDEFNODE("float",	&ops_float),
	PREDEFNODE("len",	&ops_len),
	PREDEFNODE("is_number",	&ops_isnumber),
	PREDEFNODE("is_list",	&ops_islist),
	PREDEFNODE("is_string",	&ops_isstring),
	PREDEFNODE("arcsin",	&ops_arcsin),
	PREDEFNODE("arccos",	&ops_arccos),
	PREDEFNODE("arctan",	&ops_arctan),
	PREDEFNODE("sin",	&ops_sin),
	PREDEFNODE("cos",	&ops_cos),
	PREDEF_END("tan",	&ops_tan),
	//    ^^^^ this marks the last element
};

#define PUSH_OP(x)				\
do {						\
	op_stack[op_sp] = (x);			\
	if (++op_sp >= opstack_size)		\
		enlarge_operator_stack();	\
} while (0)

#define PUSH_INT_ARG(i, f, r)				\
do {							\
	arg_stack[arg_sp].type = &type_number;		\
	arg_stack[arg_sp].u.number.ntype = NUMTYPE_INT;	\
	arg_stack[arg_sp].u.number.flags = (f);		\
	arg_stack[arg_sp].u.number.val.intval = (i);	\
	arg_stack[arg_sp++].u.number.addr_refs = (r);	\
} while (0)
#define PUSH_FP_ARG(fp, f)				\
do {							\
	arg_stack[arg_sp].type = &type_number;		\
	arg_stack[arg_sp].u.number.ntype = NUMTYPE_FLOAT;\
	arg_stack[arg_sp].u.number.flags = (f);		\
	arg_stack[arg_sp].u.number.val.fpval = (fp);	\
	arg_stack[arg_sp++].u.number.addr_refs = 0;	\
} while (0)


// double the size of the operator stack
static void enlarge_operator_stack(void)
{
	opstack_size *= 2;
	//printf("Doubling op stack size to %d.\n", opstack_size);
	op_stack = realloc(op_stack, opstack_size * sizeof(*op_stack));
	if (op_stack == NULL)
		Throw_serious_error(exception_no_memory_left);
}


// double the size of the argument stack
static void enlarge_argument_stack(void)
{
	argstack_size *= 2;
	//printf("Doubling arg stack size to %d.\n", argstack_size);
	arg_stack = realloc(arg_stack, argstack_size * sizeof(*arg_stack));
	if (arg_stack == NULL)
		Throw_serious_error(exception_no_memory_left);
}


// not-so-braindead algorithm for calculating "to the power of" function for
// integer arguments.
// my_pow(whatever, 0) returns 1.
// my_pow(0, whatever_but_zero) returns 0.
static intval_t my_pow(intval_t mantissa, intval_t exponent)
{
	intval_t	result	= 1;

	while (exponent) {
		// handle exponent's lowmost bit
		if (exponent & 1)
			result *= mantissa;
		// square the mantissa, halve the exponent
		mantissa *= mantissa;
		exponent >>= 1;
	}
	return result;
}


// arithmetic shift right (works even if C compiler does not support it)
static intval_t my_asr(intval_t left, intval_t right)
{
	// if first argument is positive or zero, ASR and LSR are equivalent,
	// so just do it and return the result:
	if (left >= 0)
		return left >> right;

	// However, if the first argument is negative, the result is
	// implementation-defined: While most compilers will do ASR, some others
	// might do LSR instead, and *theoretically*, it is even possible for a
	// compiler to define silly stuff like "shifting a negative value to the
	// right will always return -1".
	// Therefore, in case of a negative argument, we'll use this quick and
	// simple workaround:
	return ~((~left) >> right);
}


// if wanted, throw "Value not defined" error
// This function is not allowed to change DynaBuf because the symbol's name
// might be stored there!
static void is_not_defined(struct symbol *optional_symbol, char optional_prefix_char, char *name, size_t length)
{
	if (!pass.complain_about_undefined)
		return;

	// only complain once per symbol
	if (optional_symbol) {
		if (optional_symbol->has_been_reported)
			return;

		optional_symbol->has_been_reported = TRUE;
	}

	DYNABUF_CLEAR(errormsg_dyna_buf);
	DynaBuf_add_string(errormsg_dyna_buf, "Value not defined (");
	length += errormsg_dyna_buf->size;

	if (optional_prefix_char) {
		DynaBuf_append(errormsg_dyna_buf, optional_prefix_char);
		++length;
	}
	DynaBuf_add_string(errormsg_dyna_buf, name);
	if (errormsg_dyna_buf->size < length) {
		Bug_found("IllegalSymbolNameLength", errormsg_dyna_buf->size - length);
	} else {
		errormsg_dyna_buf->size = length;
	}
	DynaBuf_add_string(errormsg_dyna_buf, ").");
	DynaBuf_append(errormsg_dyna_buf, '\0');
	Throw_error(errormsg_dyna_buf->buffer);
}


// Lookup (and create, if necessary) symbol tree item and return its value.
// DynaBuf holds the symbol's name and "scope" its scope.
// The name length must be given explicitly because of anonymous forward labels;
// their internal name is different (longer) than their displayed name.
// This function is not allowed to change DynaBuf because that's where the
// symbol name is stored!
static void get_symbol_value(scope_t scope, char optional_prefix_char, size_t name_length, unsigned int unpseudo_count)
{
	struct symbol	*symbol;
	struct object	*arg;

	symbol = symbol_find(scope);
	symbol->has_been_read = TRUE;
	if (symbol->object.type == NULL) {
		// finish symbol item by making it an undefined number
		symbol->object.type = &type_number;
		symbol->object.u.number.ntype = NUMTYPE_UNDEFINED;
		symbol->object.u.number.flags = NUMBER_EVER_UNDEFINED;	// reading undefined taints it
		symbol->object.u.number.addr_refs = 0;
	} else {
		// FIXME - add sanity check for UNDEFINED where EVER_UNDEFINED is false -> Bug_found()!
		// (because the only way to have UNDEFINED is the block above, and EVER_UNDEFINED taints everything it touches)
	}
	// first push on arg stack, so we have a local copy we can "unpseudopc"
	arg = &arg_stack[arg_sp++];
	*arg = symbol->object;
	if (unpseudo_count) {
		if (arg->type == &type_number) {
			pseudopc_unpseudo(&arg->u.number, symbol->pseudopc, unpseudo_count);
		} else {
			Throw_error("Un-pseudopc operator '&' can only be applied to labels.");
		}
	}
	// if needed, output "value not defined" error
	// FIXME - in case of unpseudopc, error message should include the correct number of '&' characters
//	if (!(arg->type->is_defined(arg)))
// FIXME - now that lists with undefined items are "undefined", this fails in
// case of "!if len(some_list) {", so check for undefined _numbers_ explicitly:
	if ((arg->type == &type_number) && (arg->u.number.ntype == NUMTYPE_UNDEFINED))
		is_not_defined(symbol, optional_prefix_char, GLOBALDYNABUF_CURRENT, name_length);
	// FIXME - if arg is list, increment ref count!
}


// Parse program counter ('*')
static void parse_program_counter(unsigned int unpseudo_count)	// Now GotByte = "*"
{
	struct number	pc;

	GetByte();
	vcpu_read_pc(&pc);
	// if needed, output "value not defined" error
	if (pc.ntype == NUMTYPE_UNDEFINED)
		is_not_defined(NULL, 0, "*", 1);
	if (unpseudo_count)
		pseudopc_unpseudo(&pc, pseudopc_get_context(), unpseudo_count);
	PUSH_INT_ARG(pc.val.intval, pc.flags, pc.addr_refs);	// FIXME - when undefined pc is allowed, this must be changed for numtype!
}


// make new string object
static void string_prepare_string(struct object *self, int len)
{
	self->type = &type_string;
	self->u.string = safe_malloc(sizeof(*(self->u.string)) + len);
	self->u.string->payload[len] = 0;	// terminate, to facilitate string_print()
	self->u.string->length = len;	// length does not include the added terminator
	self->u.string->refs = 1;
}
// parse string or character
// characters will be converted using the current encoding, strings are kept as-is.
static void parse_quoted(char closing_quote)
{
	intval_t	value;

	DYNABUF_CLEAR(GlobalDynaBuf);
	if (Input_quoted_to_dynabuf(closing_quote))
		goto fail;	// unterminated or escaping error

	// eat closing quote
	GetByte();
	// now convert to unescaped version
	if (Input_unescape_dynabuf(0))
		goto fail;	// escaping error

	// without backslash escaping, both ' and " are used for single
	// characters.
	// with backslash escaping, ' is for characters and " is for strings:
	if ((closing_quote == '"') && (config.wanted_version >= VER_BACKSLASHESCAPING)) {
		// string //////////////////////////////////
		string_prepare_string(&arg_stack[arg_sp], GlobalDynaBuf->size);	// create string object and put on arg stack
		memcpy(arg_stack[arg_sp].u.string->payload, GLOBALDYNABUF_CURRENT, GlobalDynaBuf->size);	// copy payload
		++arg_sp;
	} else {
		// single character ////////////////////////
		// too short?
		if (GlobalDynaBuf->size == 0) {
			Throw_error(exception_missing_string);
			goto fail;
		}

		// too long?
		if (GlobalDynaBuf->size != 1)
			Throw_error("There's more than one character.");
		// parse character
		value = encoding_encode_char(GLOBALDYNABUF_CURRENT[0]);
		PUSH_INT_ARG(value, 0, 0);	// no flags, no addr refs
	}
	// Now GotByte = char following closing quote (or CHAR_EOS on error)
	return;

fail:
	PUSH_INT_ARG(0, 0, 0);	// dummy, no flags, no addr refs
	alu_state = STATE_ERROR;
}


// Parse binary value. Apart from '0' and '1', it also accepts the characters
// '.' and '#', this is much more readable. The current value is stored as soon
// as a character is read that is none of those given above.
static void parse_binary_literal(void)	// Now GotByte = "%" or "b"
{
	intval_t	value	= 0;
	bits		flags	= 0;
	int		digits	= -1;	// digit counter

	for (;;) {
		++digits;
		switch (GetByte()) {
		case '0':
		case '.':
			value <<= 1;
			continue;
		case '1':
		case '#':
			value = (value << 1) | 1;
			continue;
		}
		break;	// found illegal character
	}
	if (!digits)
		Throw_error("Binary literal without any digits.");
	if (digits & config.warn_bin_mask)
		Throw_first_pass_warning("Binary literal with strange number of digits.");
	// set force bits
	if (config.honor_leading_zeroes) {
		if (digits > 8) {
			if (digits > 16) {
				if (value < 65536)
					flags |= NUMBER_FORCES_24;
			} else {
				if (value < 256)
					flags |= NUMBER_FORCES_16;
			}
		}
	}
	PUSH_INT_ARG(value, flags, 0);
	// Now GotByte = non-binary char
}


// Parse hexadecimal value. It accepts "0" to "9", "a" to "f" and "A" to "F".
// The current value is stored as soon as a character is read that is none of
// those given above.
static void parse_hex_literal(void)	// Now GotByte = "$" or "x"
{
	char		byte;
	int		digits	= -1;	// digit counter
	bits		flags	= 0;
	intval_t	value	= 0;

	for (;;) {
		++digits;
		byte = GetByte();
		// if digit or legal character, add value
		if ((byte >= '0') && (byte <= '9')) {
			value = (value << 4) + (byte - '0');
			continue;
		}
		if ((byte >= 'a') && (byte <= 'f')) {
			value = (value << 4) + (byte - 'a') + 10;
			continue;
		}
		if ((byte >= 'A') && (byte <= 'F')) {
			value = (value << 4) + (byte - 'A') + 10;
			continue;
		}
		break;	// found illegal character
	}
	if (!digits)
		Throw_error("Hex literal without any digits.");
	// set force bits
	if (config.honor_leading_zeroes) {
		if (digits > 2) {
			if (digits > 4) {
				if (value < 65536)
					flags |= NUMBER_FORCES_24;
			} else {
				if (value < 256)
					flags |= NUMBER_FORCES_16;
			}
		}
	}
	PUSH_INT_ARG(value, flags, 0);
	// Now GotByte = non-hexadecimal char
}


// parse fractional part of a floating-point value
static void parse_frac_part(int integer_part)	// Now GotByte = first digit after decimal point
{
	double	denominator	= 1,
		fpval		= integer_part;

	// parse digits until no more
	while ((GotByte >= '0') && (GotByte <= '9')) {
		fpval = 10 * fpval + (GotByte & 15);	// this works. it's ASCII.
		denominator *= 10;
		GetByte();
	}
	// FIXME - add possibility to read 'e' and exponent!
	PUSH_FP_ARG(fpval / denominator, 0);
}


// Parse a decimal value. As decimal values don't use any prefixes, this
// function expects the first digit to be read already.
// If the first two digits are "0x", this function branches to the one for
// parsing hexadecimal values.
// If the first two digits are "0b", this function branches to the one for
// parsing binary values.
// If a decimal point is read, this function branches to the one for parsing
// floating-point values.
// This function accepts '0' through '9' and one dot ('.') as the decimal
// point. The current value is stored as soon as a character is read that is
// none of those given above. Float usage is only activated when a decimal
// point has been found, so don't expect "100000000000000000000" to work.
// CAUTION: "100000000000000000000.0" won't work either, because when the
// decimal point gets parsed, the integer value will have overflown already.
static void parse_number_literal(void)	// Now GotByte = first digit
{
	intval_t	intval	= (GotByte & 15);	// this works. it's ASCII.

	GetByte();
	// check for "0b" (binary) and "0x" (hexadecimal) prefixes
	if (intval == 0) {
		if (GotByte == 'b') {
			parse_binary_literal();
			return;
		}
		if (GotByte == 'x') {
			parse_hex_literal();
			return;
		}
	}
	// parse digits until no more
	while ((GotByte >= '0') && (GotByte <= '9')) {
		intval = 10 * intval + (GotByte & 15);	// ASCII, see above
		GetByte();
	}
	// check whether it's a float
	if (GotByte == '.') {
		// read fractional part
		GetByte();
		parse_frac_part(intval);
	} else {
		PUSH_INT_ARG(intval, 0, 0);
	}
	// Now GotByte = non-decimal char
}


// Parse octal value. It accepts "0" to "7". The current value is stored as
// soon as a character is read that is none of those given above.
static void parse_octal_literal(void)	// Now GotByte = first octal digit
{
	intval_t	value	= 0;
	bits		flags	= 0;
	int		digits	= 0;	// digit counter

	while ((GotByte >= '0') && (GotByte <= '7')) {
		value = (value << 3) + (GotByte & 7);	// this works. it's ASCII.
		++digits;
		GetByte();
	}
	// set force bits
	if (config.honor_leading_zeroes) {
		if (digits > 3) {
			if (digits > 6) {
				if (value < 65536)
					flags |= NUMBER_FORCES_24;
			} else {
				if (value < 256)
					flags |= NUMBER_FORCES_16;
			}
		}
	}
	PUSH_INT_ARG(value, flags, 0);
	// Now GotByte = non-octal char
}


// Parse function call (sin(), cos(), arctan(), ...)
static void parse_function_call(void)
{
	void	*node_body;

	// make lower case version of name in local dynamic buffer
	DynaBuf_to_lower(function_dyna_buf, GlobalDynaBuf);
	// search for tree item
	if (Tree_easy_scan(function_tree, &node_body, function_dyna_buf)) {
		PUSH_OP((struct op *) node_body);
	} else {
		Throw_error("Unknown function.");
		alu_state = STATE_ERROR;
	}
}


// make empty list
static void list_init_list(struct object *self)
{
	self->type = &type_list;
	self->u.listhead = safe_malloc(sizeof(*(self->u.listhead)));
	self->u.listhead->next = self->u.listhead;
	self->u.listhead->prev = self->u.listhead;
	self->u.listhead->u.listinfo.length = 0;
	self->u.listhead->u.listinfo.refs = 1;
}
// extend list by appending a single object
static void list_append_object(struct listitem *head, const struct object *obj)
{
	struct listitem	*item;

	item = safe_malloc(sizeof(*item));
	item->u.payload = *obj;
	item->next = head;
	item->prev = head->prev;
	item->next->prev = item;
	item->prev->next = item;
	head->u.listinfo.length++;
}
// extend list by appending all items of a list
static void list_append_list(struct listitem *selfhead, struct listitem *otherhead)
{
	struct listitem	*item;

	if (selfhead == otherhead)
		Bug_found("ExtendingListWithItself", 0);
	item = otherhead->next;
	while (item != otherhead) {
		list_append_object(selfhead, &item->u.payload);
		item = item->next;
	}
}


// helper function for "monadic &" (either octal value or "unpseudo" operator)
// returns nonzero on error
static int parse_octal_or_unpseudo(void)	// now GotByte = '&'
{
	unsigned int	unpseudo_count	= 1;

	while (GetByte() == '&')
		++unpseudo_count;
	if ((unpseudo_count == 1) && (GotByte >= '0') & (GotByte <= '7')) {
		parse_octal_literal();	// now GotByte = non-octal char
		return 0;	// ok
	}

	// TODO - support anonymous labels as well?
	if (GotByte == '*') {
		parse_program_counter(unpseudo_count);
	} else if (GotByte == '.') {
		GetByte();
		if (Input_read_keyword() == 0)	// now GotByte = illegal char
			return 1;	// error (no string given)

		get_symbol_value(section_now->local_scope, LOCAL_PREFIX, GlobalDynaBuf->size - 1, unpseudo_count);	// -1 to not count terminator
	} else if (GotByte == CHEAP_PREFIX) {
		GetByte();
		if (Input_read_keyword() == 0)	// now GotByte = illegal char
			return 1;	// error (no string given)

		get_symbol_value(section_now->cheap_scope, CHEAP_PREFIX, GlobalDynaBuf->size - 1, unpseudo_count);	// -1 to not count terminator
	} else if (BYTE_STARTS_KEYWORD(GotByte)) {
		Input_read_keyword();	// now GotByte = illegal char
		get_symbol_value(SCOPE_GLOBAL, '\0', GlobalDynaBuf->size - 1, unpseudo_count);	// no prefix, -1 to not count terminator
	} else {
                Throw_error(exception_missing_string);	// FIXME - create some "expected octal value or symbol name" error instead!
		return 1;	// error
	}
	return 0;	// ok
}


// expression parser


// handler for special operators like parentheses and start/end of expression
#define PREVIOUS_ARGUMENT	(arg_stack[arg_sp - 2])
#define NEWEST_ARGUMENT		(arg_stack[arg_sp - 1])
#define PREVIOUS_OPERATOR	(op_stack[op_sp - 2])
#define NEWEST_OPERATOR		(op_stack[op_sp - 1])
static void handle_special_operator(struct expression *expression, enum op_id previous)
{
	// when this gets called, "current" operator is OPID_TERMINATOR
	switch (previous) {
	case OPID_START_EXPRESSION:
		alu_state = STATE_END;	// we are done
		// don't touch "is_parenthesized", because start/end are obviously not "real" operators
		// not really needed, but there are sanity checks for stack pointers:
		// remove previous operator by overwriting with newest one...
		PREVIOUS_OPERATOR = NEWEST_OPERATOR;
		--op_sp;	// ...and shrinking operator stack
		break;
	case OPID_SUBEXPR_PAREN:
		expression->is_parenthesized = TRUE;	// found parentheses. if this is not the outermost level, the outermost level will fix this flag later on.
		if (GotByte == ')') {
			// matching parenthesis
			GetByte();	// eat ')'
			op_sp -= 2;	// remove both SUBEXPR_PAREN and TERMINATOR
			alu_state = STATE_EXPECT_DYADIC_OP;
		} else {
			// unmatched parenthesis, as in "lda ($80,x)"
			++(expression->open_parentheses);	// count
			// remove previous operator by overwriting with newest one...
			PREVIOUS_OPERATOR = NEWEST_OPERATOR;
			--op_sp;	// ...and shrinking operator stack
		}
		break;
	case OPID_START_LIST:
		if (GotByte == ',') {
			GetByte();	// eat ','
			NEWEST_OPERATOR = &ops_list_append;	// change "end of expression" to "append"
		} else if (GotByte == ']') {
			GetByte();	// eat ']'
			op_sp -= 2;	// remove both START_LIST and TERMINATOR
			alu_state = STATE_EXPECT_DYADIC_OP;
		} else {
			// unmatched bracket
			Throw_error("Unterminated list.");
			alu_state = STATE_ERROR;
			// remove previous operator by overwriting with newest one...
			PREVIOUS_OPERATOR = NEWEST_OPERATOR;
			--op_sp;	// ...and shrinking operator stack
		}
		break;
	case OPID_SUBEXPR_BRACKET:
		if (GotByte == ']') {
			GetByte();	// eat ']'
			op_sp -= 2;	// remove both SUBEXPR_BRACKET and TERMINATOR
			alu_state = STATE_EXPECT_DYADIC_OP;
		} else {
			// unmatched bracket
			Throw_error("Unterminated index spec.");
			alu_state = STATE_ERROR;
			// remove previous operator by overwriting with newest one...
			PREVIOUS_OPERATOR = NEWEST_OPERATOR;
			--op_sp;	// ...and shrinking operator stack
		}
		break;
	default:
		Bug_found("IllegalOperatorId", previous);
	}
}
// put dyadic operator on stack and try to reduce stacks by performing
// high-priority operations: as long as the second-to-last operator
// has a higher priority than the last one, perform the operation of
// that second-to-last one and remove it from stack.
static void push_dyadic_and_check(struct expression *expression, struct op *op)
{
	PUSH_OP(op);	// put newest operator on stack
	if (alu_state < STATE_MAX_GO_ON)
		alu_state = STATE_EXPECT_ARG_OR_MONADIC_OP;
	while (alu_state == STATE_EXPECT_ARG_OR_MONADIC_OP) {
		// if there is only one operator left on op stack, it must be
		// "start of expression", so there isn't anything to do here:
		if (op_sp < 2)
			return;

		// if previous operator has lower piority, nothing to do here:
		if (PREVIOUS_OPERATOR->priority < NEWEST_OPERATOR->priority)
			return;

		// if priorities are the same, check associativity:
		if ((PREVIOUS_OPERATOR->priority == NEWEST_OPERATOR->priority)
		&& (NEWEST_OPERATOR->priority == PRIO_POWEROF)
		&& (config.wanted_version >= VER_RIGHTASSOCIATIVEPOWEROF))
			return;

		// ok, so now perform operation indicated by previous operator!
		switch (PREVIOUS_OPERATOR->group) {
		case OPGROUP_MONADIC:
			// stacks:	...	...	previous op(monadic)	newest arg	newest op(dyadic)
			if (arg_sp < 1)
				Bug_found("ArgStackEmpty", arg_sp);
			NEWEST_ARGUMENT.type->monadic_op(&NEWEST_ARGUMENT, PREVIOUS_OPERATOR);
			expression->is_parenthesized = FALSE;	// operation was something other than parentheses
			// now remove previous operator by overwriting with newest one...
			PREVIOUS_OPERATOR = NEWEST_OPERATOR;
			--op_sp;	// ...and shrinking operator stack
			break;
		case OPGROUP_DYADIC:
			// stacks:	previous arg	previous op(dyadic)	newest arg	newest op(dyadic)
			if (arg_sp < 2)
				Bug_found("NotEnoughArgs", arg_sp);
			PREVIOUS_ARGUMENT.type->dyadic_op(&PREVIOUS_ARGUMENT, PREVIOUS_OPERATOR, &NEWEST_ARGUMENT);
			expression->is_parenthesized = FALSE;	// operation was something other than parentheses
			// now remove previous operator by overwriting with newest one...
			PREVIOUS_OPERATOR = NEWEST_OPERATOR;
			--op_sp;	// ...and shrinking operator stack
			--arg_sp;	// and then shrink argument stack because two arguments just became one
			break;
		case OPGROUP_SPECIAL:
			// stacks:	...	...	previous op(special)	newest arg	newest op(dyadic)
			if (NEWEST_OPERATOR->id != OPID_TERMINATOR)
				Bug_found("StrangeOperator", NEWEST_OPERATOR->id);
			handle_special_operator(expression, PREVIOUS_OPERATOR->id);
			// the function above fixes both stacks and "is_parenthesized"!
			break;
		default:
			Bug_found("IllegalOperatorGroup", PREVIOUS_OPERATOR->group);
		}
	}
}


// Expect argument or monadic operator (hopefully inlined)
// returns TRUE if it ate any non-space (-> so expression isn't empty)
// returns FALSE if first non-space is delimiter (-> end of expression)
static boolean expect_argument_or_monadic_operator(struct expression *expression)
{
	struct op	*op;
	int		ugly_length_kluge;
	boolean		perform_negation;

	SKIPSPACE();
	switch (GotByte) {
	case '+':	// anonymous forward label
		// count plus signs to build name of anonymous label
		DYNABUF_CLEAR(GlobalDynaBuf);
		do
			DYNABUF_APPEND(GlobalDynaBuf, '+');
		while (GetByte() == '+');
		ugly_length_kluge = GlobalDynaBuf->size;	// FIXME - get rid of this!
		symbol_fix_forward_anon_name(FALSE);	// FALSE: do not increment counter
		get_symbol_value(section_now->local_scope, '\0', ugly_length_kluge, 0);	// no prefix, no unpseudo
		goto now_expect_dyadic_op;

	case '-':	// NEGATION operator or anonymous backward label
		// count minus signs in case it's an anonymous backward label
		perform_negation = FALSE;
		DYNABUF_CLEAR(GlobalDynaBuf);
		do {
			DYNABUF_APPEND(GlobalDynaBuf, '-');
			perform_negation = !perform_negation;
		} while (GetByte() == '-');
		SKIPSPACE();
		if (BYTE_FOLLOWS_ANON(GotByte)) {
			DynaBuf_append(GlobalDynaBuf, '\0');
			get_symbol_value(section_now->local_scope, '\0', GlobalDynaBuf->size - 1, 0);	// no prefix, -1 to not count terminator, no unpseudo
			goto now_expect_dyadic_op;
		}

		if (perform_negation)
			PUSH_OP(&ops_negate);
		// State doesn't change
		break;//goto done;
// Real monadic operators (state doesn't change, still ExpectMonadic)
	case '!':	// NOT operator
		op = &ops_not;
		goto get_byte_and_push_monadic;

	case '<':	// LOWBYTE operator
		op = &ops_low_byte_of;
		goto get_byte_and_push_monadic;

	case '>':	// HIGHBYTE operator
		op = &ops_high_byte_of;
		goto get_byte_and_push_monadic;

	case '^':	// BANKBYTE operator
		op = &ops_bank_byte_of;
		goto get_byte_and_push_monadic;

// special operators
	case '[':	// start of list literal
		list_init_list(&arg_stack[arg_sp++]);	// put empty list on arg stack
		NEXTANDSKIPSPACE();
		if (GotByte == ']') {
			// list literal is empty, so we're basically done
			GetByte();
			goto now_expect_dyadic_op;

		} else {
			// non-empty list literal
			PUSH_OP(&ops_start_list);	// quasi-monadic "start of list", makes sure earlier ops do not process empty list
			push_dyadic_and_check(expression, &ops_list_append);	// dyadic "append to list", so next arg will be appended to list
			//now we're back in STATE_EXPECT_ARG_OR_MONADIC_OP
		}
		break;//goto done;

	case '(':	// left parenthesis
		op = &ops_subexpr_paren;
		goto get_byte_and_push_monadic;

// arguments (state changes to ExpectDyadic)
	case '"':	// character (old) or string (new)
	case '\'':	// character
		// Character will be converted using current encoding
		parse_quoted(GotByte);
		// Now GotByte = char following closing quote
		goto now_expect_dyadic_op;

	case '%':	// Binary value
		parse_binary_literal();	// Now GotByte = non-binary char
		goto now_expect_dyadic_op;

	case '&':	// octal value or "unpseudo" operator applied to label
		if (parse_octal_or_unpseudo() == 0)
			goto now_expect_dyadic_op;

		// if we're here, there was an error (like "no string given"):
		alu_state = STATE_ERROR;
		break;//goto done;
	case '$':	// Hexadecimal value
		parse_hex_literal();
		// Now GotByte = non-hexadecimal char
		goto now_expect_dyadic_op;

	case '*':	// Program counter
		parse_program_counter(0);
		// Now GotByte = char after closing quote
		goto now_expect_dyadic_op;

// FIXME - find a way to tell decimal point and LOCAL_PREFIX apart!
	case '.':	// local symbol or fractional part of float value
		GetByte();	// start after '.'
		// check for fractional part of float value
		if ((GotByte >= '0') && (GotByte <= '9')) {
			parse_frac_part(0);	// now GotByte = non-decimal char
			goto now_expect_dyadic_op;
		}

		if (Input_read_keyword()) {	// now GotByte = illegal char
			get_symbol_value(section_now->local_scope, LOCAL_PREFIX, GlobalDynaBuf->size - 1, 0);	// -1 to not count terminator, no unpseudo
			goto now_expect_dyadic_op;	// ok
		}

		// if we're here, Input_read_keyword() will have thrown an error (like "no string given"):
		alu_state = STATE_ERROR;
		break;//goto done;
	case CHEAP_PREFIX:	// cheap local symbol
		//printf("looking in cheap scope %d\n", section_now->cheap_scope);
		GetByte();	// start after '@'
		if (Input_read_keyword()) {	// now GotByte = illegal char
			get_symbol_value(section_now->cheap_scope, CHEAP_PREFIX, GlobalDynaBuf->size - 1, 0);	// -1 to not count terminator, no unpseudo
			goto now_expect_dyadic_op;	// ok
		}

		// if we're here, Input_read_keyword() will have thrown an error (like "no string given"):
		alu_state = STATE_ERROR;
		break;//goto done;
	// decimal values and global symbols
	default:	// all other characters
		if ((GotByte >= '0') && (GotByte <= '9')) {
			parse_number_literal();
			// Now GotByte = non-decimal char
			goto now_expect_dyadic_op;
		}

		if (BYTE_STARTS_KEYWORD(GotByte)) {
			register int	length;

			// Read global label (or "NOT")
			length = Input_read_keyword();
			// Now GotByte = illegal char
			// Check for NOT. Okay, it's hardcoded,
			// but so what? Sue me...
			if ((length == 3)
			&& ((GlobalDynaBuf->buffer[0] | 32) == 'n')
			&& ((GlobalDynaBuf->buffer[1] | 32) == 'o')
			&& ((GlobalDynaBuf->buffer[2] | 32) == 't')) {
				PUSH_OP(&ops_not);
				// state doesn't change
			} else {
				if (GotByte == '(') {
					parse_function_call();
// i thought about making the parentheses optional, so you can write "a = sin b"
// just like "a = not b". but then each new function name would have to be made
// a reserved keyword, otherwise stuff like "a = sin * < b" would be ambiguous:
// it could mean either "compare sine of PC to b" or "multiply 'sin' by low byte
// of b".
// however, apart from that check above, function calls have nothing to do with
// parentheses: "sin(x+y)" gets parsed just like "not(x+y)".
				} else {
					get_symbol_value(SCOPE_GLOBAL, '\0', GlobalDynaBuf->size - 1, 0);	// no prefix, -1 to not count terminator, no unpseudo
					goto now_expect_dyadic_op;
				}
			}
		} else {
			// illegal character read - so don't go on
			// we found end-of-expression instead of an argument,
			// that's either an empty expression or an erroneous one!
			PUSH_INT_ARG(0, 0, 0);	// push dummy argument so stack checking code won't bark	FIXME - use undefined?
			if (op_stack[op_sp - 1] == &ops_start_expression) {
				push_dyadic_and_check(expression, &ops_terminating_char);
			} else {
				Throw_error(exception_syntax);
				alu_state = STATE_ERROR;
			}
			return FALSE;	// found delimiter
		}
		break;//goto done;

// no other possibilities, so here are the shared endings

get_byte_and_push_monadic:
		GetByte();
		PUSH_OP(op);
		// State doesn't change
		break;

now_expect_dyadic_op:
		// bugfix: if in error state, do not change state back to valid one
		if (alu_state < STATE_MAX_GO_ON)
			alu_state = STATE_EXPECT_DYADIC_OP;
		break;
	}
//done:
	return TRUE;	// parsed something
}


// Expect dyadic operator (hopefully inlined)
static void expect_dyadic_operator(struct expression *expression)
{
	void		*node_body;
	struct op	*op;

	SKIPSPACE();
	switch (GotByte) {
// Single-character dyadic operators
	case '^':	// "to the power of"
		op = &ops_powerof;
		goto get_byte_and_push_dyadic;

	case '+':	// add
		op = &ops_add;
		goto get_byte_and_push_dyadic;

	case '-':	// subtract
		op = &ops_subtract;
		goto get_byte_and_push_dyadic;

	case '*':	// multiply
		op = &ops_multiply;
		goto get_byte_and_push_dyadic;

	case '/':	// divide
		op = &ops_divide;
		goto get_byte_and_push_dyadic;

	case '%':	// modulo
		op = &ops_modulo;
		goto get_byte_and_push_dyadic;

	case '&':	// bitwise AND
		op = &ops_and;
		goto get_byte_and_push_dyadic;

	case '|':	// bitwise OR
		op = &ops_or;
		goto get_byte_and_push_dyadic;

// This part is commented out because there is no XOR character defined
//	case ???:	// bitwise exclusive OR
//		op = &ops_xor;
//		goto get_byte_and_push_dyadic;

	case '=':	// is equal
		op = &ops_equals;
		// atm, accept both "=" and "==". in future, prefer "=="!
		if (GetByte() == '=') {
			//Throw_first_pass_warning("C-style \"==\" comparison detected.");	REMOVE!
			GetByte();	// eat second '=' character
		} else {
			//Throw_first_pass_warning("old-style \"=\" comparison detected, please use \"==\" instead.");	ACTIVATE!
		}
		goto push_dyadic_op;

	case '[':	// indexing operator
		GetByte();	// eat char
		// first put high-priority dyadic on stack,
		// then low-priority special ops_subexpr_bracket
		push_dyadic_and_check(expression, &ops_atindex);
		// now we're in STATE_EXPECT_ARG_OR_MONADIC_OP
		PUSH_OP(&ops_subexpr_bracket);
		return;

// Multi-character dyadic operators
	case '!':	// "!="
		if (GetByte() == '=') {
			op = &ops_not_equal;
			goto get_byte_and_push_dyadic;
		}

		Throw_error(exception_syntax);
		alu_state = STATE_ERROR;
		break;//goto end;
	case '<':	// "<", "<=", "<<" and "<>"
		switch (GetByte()) {
		case '=':	// "<=", less or equal
			op = &ops_less_or_equal;
			goto get_byte_and_push_dyadic;

		case '<':	// "<<", shift left
			op = &ops_shift_left;
			goto get_byte_and_push_dyadic;

		case '>':	// "<>", not equal
			op = &ops_not_equal;
			goto get_byte_and_push_dyadic;

		default:	// "<", less than
			op = &ops_less_than;
			goto push_dyadic_op;

		}
		//break; unreachable
	case '>':	// ">", ">=", ">>", ">>>" and "><"
		switch (GetByte()) {
		case '=':	// ">=", greater or equal
			op = &ops_greater_or_equal;
			goto get_byte_and_push_dyadic;

		case '<':	// "><", not equal
			op = &ops_not_equal;
			goto get_byte_and_push_dyadic;

		case '>':	// ">>" or ">>>", shift right
			op = &ops_asr;	// arithmetic shift right
			if (GetByte() != '>')
				goto push_dyadic_op;

			op = &ops_lsr;	// logical shift right
			goto get_byte_and_push_dyadic;

		default:	// ">", greater than
			op = &ops_greater_than;
			goto push_dyadic_op;

		}
		//break; unreachable
// end of expression or text version of dyadic operator
	default:
		// check string versions of operators
		if (BYTE_STARTS_KEYWORD(GotByte)) {
			Input_read_and_lower_keyword();
			// Now GotByte = illegal char
			// search for tree item
			if (Tree_easy_scan(op_tree, &node_body, GlobalDynaBuf)) {
				op = node_body;
				goto push_dyadic_op;
			}

			Throw_error("Unknown operator.");
			alu_state = STATE_ERROR;
			//goto end;
		} else {
			// we found end-of-expression when expecting an operator, that's ok.
			op = &ops_terminating_char;
			goto push_dyadic_op;
		}
	}
//end:
	return;	// TODO - change the two points that go here and add a Bug_found() instead

// shared endings
get_byte_and_push_dyadic:
	GetByte();
push_dyadic_op:
	push_dyadic_and_check(expression, op);
}


// helper function: create and output error message about (argument/)operator/argument combination
static void unsupported_operation(const struct object *optional, const struct op *op, const struct object *arg)
{
	if (optional) {
		if (op->group != OPGROUP_DYADIC)
			Bug_found("OperatorIsNotDyadic", op->id);
	} else {
		if (op->group != OPGROUP_MONADIC)
			Bug_found("OperatorIsNotMonadic", op->id);
	}
	DYNABUF_CLEAR(errormsg_dyna_buf);
	DynaBuf_add_string(errormsg_dyna_buf, "Operation not supported: Cannot apply \"");
	DynaBuf_add_string(errormsg_dyna_buf, op->text_version);
	DynaBuf_add_string(errormsg_dyna_buf, "\" to \"");
	if (optional) {
		DynaBuf_add_string(errormsg_dyna_buf, optional->type->name);
		DynaBuf_add_string(errormsg_dyna_buf, "\" and \"");
	}
	DynaBuf_add_string(errormsg_dyna_buf, arg->type->name);
	DynaBuf_add_string(errormsg_dyna_buf, "\".");
	DynaBuf_append(errormsg_dyna_buf, '\0');
	Throw_error(errormsg_dyna_buf->buffer);
}


// int/float

// int:
// create byte-sized int object (for comparison results, converted characters, ...)
static void int_create_byte(struct object *self, intval_t byte)
{
	self->type = &type_number;
	self->u.number.ntype = NUMTYPE_INT;
	self->u.number.flags = 0;
	self->u.number.val.intval = byte;
	self->u.number.addr_refs = 0;
}

// int:
// convert to float
inline static void int_to_float(struct object *self)
{
	self->u.number.ntype = NUMTYPE_FLOAT;
	self->u.number.val.fpval = self->u.number.val.intval;
}

// float:
// convert to int
inline static void float_to_int(struct object *self)
{
	self->u.number.ntype = NUMTYPE_INT;
	self->u.number.val.intval = self->u.number.val.fpval;
}

// list:
// replace with item at index
static void list_to_item(struct object *self, int index)
{
	struct listitem	*item;

	item = self->u.listhead->next;
	while (index) {
		item = item->next;
		--index;
	}
	self->u.listhead->u.listinfo.refs--;	// FIXME - call some fn for this (and do _after_ next line)
	*self = item->u.payload;	// FIXME - if item is a list, it would gain a ref by this...
}

// string:
// replace with char at index
static void string_to_byte(struct object *self, int index)
{
	intval_t	byte;

	byte = encoding_encode_char(self->u.string->payload[index]);
	self->u.string->refs--;	// FIXME - call a function for this...
	int_create_byte(self, byte);
}

// int/float:
// return DEFINED flag
static boolean number_is_defined(const struct object *self)
{
	return self->u.number.ntype != NUMTYPE_UNDEFINED;
}

// list:
// return TRUE only if completely defined
static boolean list_is_defined(const struct object *self)
{
	struct listitem	*item;

	// iterate over items: if an undefined one is found, return FALSE
	item = self->u.listhead->next;
	while (item != self->u.listhead) {
		if (!(item->u.payload.type->is_defined(&item->u.payload)))
			return FALSE;	// we found something undefined

		item = item->next;
	}
	// otherwise, list is defined
	return TRUE;
}

// string:
// ...is always considered "defined"
static boolean object_return_true(const struct object *self)
{
	return TRUE;
}

// int/float:
// check if new value differs from old
// returns FALSE in case of undefined value(s), because undefined is not necessarily different!
static boolean number_differs(const struct object *self, const struct object *other)
{
	if (self->u.number.ntype == NUMTYPE_UNDEFINED)
		return FALSE;

	if (other->u.number.ntype == NUMTYPE_UNDEFINED)
		return FALSE;

	if (self->u.number.ntype == NUMTYPE_INT) {
		if (other->u.number.ntype == NUMTYPE_INT)
			return self->u.number.val.intval != other->u.number.val.intval;
		else
			return self->u.number.val.intval != other->u.number.val.fpval;
	} else {
		if (other->u.number.ntype == NUMTYPE_INT)
			return self->u.number.val.fpval != other->u.number.val.intval;
		else
			return self->u.number.val.fpval != other->u.number.val.fpval;
	}
}
// list:
// check if new value differs from old
static boolean list_differs(const struct object *self, const struct object *other)
{
	struct listitem	*arthur,
			*ford;

	if (self->u.listhead->u.listinfo.length != other->u.listhead->u.listinfo.length)
		return TRUE;	// lengths differ

	// same length, so iterate over lists and check items
	arthur = self->u.listhead->next;
	ford = other->u.listhead->next;
	while (arthur != self->u.listhead) {
		if (ford == other->u.listhead)
			Bug_found("ListLengthError", 0);
		if (arthur->u.payload.type != ford->u.payload.type)
			return TRUE;	// item types differ

		if (arthur->u.payload.type->differs(&arthur->u.payload, &ford->u.payload))
			return TRUE;	// item values differ

		arthur = arthur->next;
		ford = ford->next;
	}
	if (ford != other->u.listhead)
		Bug_found("ListLengthError", 1);
	return FALSE;	// no difference found
}
// string:
// check if new value differs from old
static boolean string_differs(const struct object *self, const struct object *other)
{
	if (self->u.string->length != other->u.string->length)
		return TRUE;

	return !!memcmp(self->u.string->payload, other->u.string->payload, self->u.string->length);
}

// int/float:
// assign new value
static void number_assign(struct object *self, const struct object *new_value, boolean accept_change)
{
	bits	own_flags	= self->u.number.flags,
		other_flags	= new_value->u.number.flags;
	// local copies of the flags are used because
	//	self->...flags might get overwritten when copying struct over, and
	//	new_value-> is const so shouldn't be touched.

	// accepting a different value is easily done by just forgetting the old one:
	if (accept_change) {
		self->u.number.ntype = NUMTYPE_UNDEFINED;
		own_flags &= ~(NUMBER_FITS_BYTE);
	}

	// copy struct over?
	if (self->u.number.ntype == NUMTYPE_UNDEFINED) {
		// symbol is undefined OR redefinitions are allowed, so use new value:
		*self = *new_value;	// copy type and flags/value/addr_refs
		// flags will be fixed, see below
	} else {
		// symbol is already defined, so compare new and old values
		// if values differ, complain and return
		if (number_differs(self, new_value)) {
			Throw_error(exception_symbol_defined);
			return;
		}
		// values are the same, so only fiddle with flags
	}

	// if symbol has no force bits of its own, use the ones from new value:
	if ((own_flags & NUMBER_FORCEBITS) == 0)
		own_flags = (own_flags & ~NUMBER_FORCEBITS) | (other_flags & NUMBER_FORCEBITS);

	// tainted symbols without "fits byte" flag must never get that flag
	if ((own_flags & (NUMBER_EVER_UNDEFINED | NUMBER_FITS_BYTE)) == NUMBER_EVER_UNDEFINED)
		other_flags &= ~NUMBER_FITS_BYTE;
	// now OR together "fits byte", "defined" and "tainted"
	// (any hypothetical problems like "what if new value is later found out
	// to _not_ fit byte?" would be detected in a later pass because trying
	// to assign that new value would throw an error)
	own_flags |= other_flags & (NUMBER_FITS_BYTE | NUMBER_EVER_UNDEFINED);

	self->u.number.flags = own_flags;
}


// list:
// assign new value
static void list_assign(struct object *self, const struct object *new_value, boolean accept_change)
{
	if ((!accept_change) && list_differs(self, new_value)) {
		Throw_error(exception_symbol_defined);
		return;
	}
	*self = *new_value;
}

// string:
// assign new value
static void string_assign(struct object *self, const struct object *new_value, boolean accept_change)
{
	if ((!accept_change) && string_differs(self, new_value)) {
		Throw_error(exception_symbol_defined);
		return;
	}
	*self = *new_value;
}


// undefined:
// handle monadic operator (includes functions)
static void undef_handle_monadic_operator(struct object *self, const struct op *op)
{
	switch (op->id) {
	case OPID_INT:
	case OPID_FLOAT:
		self->u.number.addr_refs = 0;
		break;
	case OPID_SIN:
	case OPID_COS:
	case OPID_TAN:
	case OPID_ARCSIN:
	case OPID_ARCCOS:
	case OPID_ARCTAN:
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		self->u.number.addr_refs = 0;
		break;
	case OPID_NOT:
	case OPID_NEGATE:
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		self->u.number.addr_refs = -(self->u.number.addr_refs);	// negate address ref count
		break;
	case OPID_LOWBYTEOF:
	case OPID_HIGHBYTEOF:
	case OPID_BANKBYTEOF:
		self->u.number.flags |= NUMBER_FITS_BYTE;
		self->u.number.flags &= ~NUMBER_FORCEBITS;
		self->u.number.addr_refs = 0;
		break;
// add new monadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(NULL, op, self);
	}
}

// prototype for int/float passing
static void float_handle_monadic_operator(struct object *self, const struct op *op);
// int:
// handle monadic operator (includes functions)
static void int_handle_monadic_operator(struct object *self, const struct op *op)
{
	int	refs	= 0;	// default for "addr_refs", shortens this fn

	switch (op->id) {
	case OPID_INT:
		break;
	case OPID_FLOAT:
		int_to_float(self);
		break;
	case OPID_SIN:
	case OPID_COS:
	case OPID_TAN:
	case OPID_ARCSIN:
	case OPID_ARCCOS:
	case OPID_ARCTAN:
		// convert int to fp and ask fp handler to do the work
		int_to_float(self);
		float_handle_monadic_operator(self, op);	// TODO - put recursion check around this?
		return;	// float handler has done everything

	case OPID_NOT:
		self->u.number.val.intval = ~(self->u.number.val.intval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		refs = -(self->u.number.addr_refs);	// negate address ref count
		break;
	case OPID_NEGATE:
		self->u.number.val.intval = -(self->u.number.val.intval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		refs = -(self->u.number.addr_refs);	// negate address ref count as well
		break;
	case OPID_LOWBYTEOF:
		self->u.number.val.intval = (self->u.number.val.intval) & 255;
		self->u.number.flags |= NUMBER_FITS_BYTE;
		self->u.number.flags &= ~NUMBER_FORCEBITS;
		break;
	case OPID_HIGHBYTEOF:
		self->u.number.val.intval = ((self->u.number.val.intval) >> 8) & 255;
		self->u.number.flags |= NUMBER_FITS_BYTE;
		self->u.number.flags &= ~NUMBER_FORCEBITS;
		break;
	case OPID_BANKBYTEOF:
		self->u.number.val.intval = ((self->u.number.val.intval) >> 16) & 255;
		self->u.number.flags |= NUMBER_FITS_BYTE;
		self->u.number.flags &= ~NUMBER_FORCEBITS;
		break;
// add new monadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(NULL, op, self);
	}
	self->u.number.addr_refs = refs;	// update address refs with local copy
}

// float:
// helper function for asin/acos:
// make sure arg is in [-1, 1] range before calling function
static void float_ranged_fn(double (*fn)(double), struct object *self)
{
	if ((self->u.number.val.fpval >= -1) && (self->u.number.val.fpval <= 1)) {
		self->u.number.val.fpval = fn(self->u.number.val.fpval);
	} else {
		Throw_error("Argument out of range.");	// TODO - add number output to error message
		self->u.number.val.fpval = 0;
	}
}

// float:
// handle monadic operator (includes functions)
static void float_handle_monadic_operator(struct object *self, const struct op *op)
{
	int	refs	= 0;	// default for "addr_refs", shortens this fn

	switch (op->id) {
	case OPID_INT:
		float_to_int(self);
		break;
	case OPID_FLOAT:
		break;
	case OPID_SIN:
		self->u.number.val.fpval = sin(self->u.number.val.fpval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_COS:
		self->u.number.val.fpval = cos(self->u.number.val.fpval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_TAN:
		self->u.number.val.fpval = tan(self->u.number.val.fpval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_ARCSIN:
		float_ranged_fn(asin, self);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_ARCCOS:
		float_ranged_fn(acos, self);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_ARCTAN:
		self->u.number.val.fpval = atan(self->u.number.val.fpval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		break;
	case OPID_NEGATE:
		self->u.number.val.fpval = -(self->u.number.val.fpval);
		self->u.number.flags &= ~NUMBER_FITS_BYTE;
		refs = -(self->u.number.addr_refs);	// negate address ref count as well
		break;
	case OPID_NOT:
	case OPID_LOWBYTEOF:
	case OPID_HIGHBYTEOF:
	case OPID_BANKBYTEOF:
		// convert fp to int and ask int handler to do the work
		float_to_int(self);
		int_handle_monadic_operator(self, op);	// TODO - put recursion check around this?
		return;	// int handler has done everything

// add new monadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(NULL, op, self);
	}
	self->u.number.addr_refs = refs;	// update address refs with local copy
}

// num:
// handle monadic operator (includes functions)
static void number_handle_monadic_operator(struct object *self, const struct op *op)
{
	// first check operators where we don't care about number type or value
	switch (op->id) {
	case OPID_ADDRESS:
		self->u.number.addr_refs = 1;	// result now is an address
		return;

	case OPID_ISNUMBER:
		int_create_byte(self, TRUE);
		return;

	case OPID_ISLIST:
	case OPID_ISSTRING:
		int_create_byte(self, FALSE);
		return;

	default:
		break;
	}
	// it's none of those, so split according to number type
	switch (self->u.number.ntype) {
	case NUMTYPE_UNDEFINED:
		undef_handle_monadic_operator(self, op);
		break;
	case NUMTYPE_INT:
		int_handle_monadic_operator(self, op);
		break;
	case NUMTYPE_FLOAT:
		float_handle_monadic_operator(self, op);
		break;
	default:
		Bug_found("IllegalNumberType1", self->u.number.ntype);
	}
}

// list:
// handle monadic operator (includes functions)
static void list_handle_monadic_operator(struct object *self, const struct op *op)
{
	int	length;

	switch (op->id) {
	case OPID_LEN:
		length = self->u.listhead->u.listinfo.length;
		self->u.listhead->u.listinfo.refs--;	// FIXME - call some list_decrement_refs() instead...
		self->type = &type_number;
		self->u.number.ntype = NUMTYPE_INT;
		self->u.number.flags = 0;
		self->u.number.val.intval = length;
		self->u.number.addr_refs = 0;
		break;
	case OPID_ISLIST:
		int_create_byte(self, TRUE);
		break;
	case OPID_ISNUMBER:
	case OPID_ISSTRING:
		int_create_byte(self, FALSE);
		break;
	default:
		unsupported_operation(NULL, op, self);
	}
}

// string:
// handle monadic operator (includes functions)
static void string_handle_monadic_operator(struct object *self, const struct op *op)
{
	int	length;

	switch (op->id) {
	case OPID_LEN:
		length = self->u.string->length;
		self->u.string->refs--;	// FIXME - call some string_decrement_refs() instead...
		self->type = &type_number;
		self->u.number.ntype = NUMTYPE_INT;
		self->u.number.flags = 0;
		self->u.number.val.intval = length;
		self->u.number.addr_refs = 0;
		break;
	case OPID_ISNUMBER:
	case OPID_ISLIST:
		int_create_byte(self, FALSE);
		break;
	case OPID_ISSTRING:
		int_create_byte(self, TRUE);
		break;
	default:
		unsupported_operation(NULL, op, self);
	}
}

// int/float:
// merge result flags
// (used by both int and float handlers for comparison operators)
static void intfloat_fix_result_after_comparison(struct object *self, const struct object *other, intval_t result)
{
	bits	flags;

	self->type = &type_number;
	self->u.number.ntype = NUMTYPE_INT;
	self->u.number.val.intval = result;
	self->u.number.addr_refs = 0;
	flags = (self->u.number.flags | other->u.number.flags) & NUMBER_EVER_UNDEFINED;	// EVER_UNDEFINED flags are ORd together
	flags |= NUMBER_FITS_BYTE;	// comparison results are either 0 or 1, so fit in byte
	// (FORCEBITS are cleared)
	self->u.number.flags = flags;
}
// (used by both int and float handlers for all other dyadic operators)
static void intfloat_fix_result_after_dyadic(struct object *self, const struct object *other)
{
	self->u.number.flags |= other->u.number.flags & (NUMBER_EVER_UNDEFINED | NUMBER_FORCEBITS);	// EVER_UNDEFINED and FORCEBITs are ORd together
	self->u.number.flags &= ~NUMBER_FITS_BYTE;	// clear FITS_BYTE because result could be anything
}

// undefined/int/float:
// handle dyadic operator
// (both args are numbers, but at least one of them is undefined!)
static void undef_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	int	refs	= 0;	// default for "addr_refs", shortens this fn

	switch (op->id) {
	case OPID_POWEROF:
	case OPID_MULTIPLY:
	case OPID_DIVIDE:
	case OPID_INTDIV:
	case OPID_MODULO:
	case OPID_SHIFTLEFT:
	case OPID_ASR:
	case OPID_LSR:
		break;

	case OPID_SUBTRACT:
		refs = self->u.number.addr_refs - other->u.number.addr_refs;	// subtract address references
		break;

	case OPID_LESSOREQUAL:
	case OPID_LESSTHAN:
	case OPID_GREATEROREQUAL:
	case OPID_GREATERTHAN:
	case OPID_NOTEQUAL:
	case OPID_EQUALS:
		// only for comparisons:
		self->u.number.flags |= NUMBER_FITS_BYTE;	// result is either 0 or 1, so fits in byte
		self->u.number.flags &= ~NUMBER_FORCEBITS;	// FORCEBITS are cleared
		goto shared;

	case OPID_EOR:
		Throw_first_pass_warning("\"EOR\" is deprecated; use \"XOR\" instead.");
		/*FALLTHROUGH*/
	case OPID_XOR:
	case OPID_AND:
	case OPID_OR:
	case OPID_ADD:
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
// add new dyadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(self, op, other);
		return;
	}
	// CAUTION: comparisons goto label below instead of jumping here
	self->u.number.flags |= (other->u.number.flags & NUMBER_FORCEBITS);	// FORCEBITs are ORd together
	self->u.number.flags &= ~NUMBER_FITS_BYTE;	// clear FITS_BYTE because result could be anything
shared:
	self->u.number.flags |= (other->u.number.flags & NUMBER_EVER_UNDEFINED);	// EVER_UNDEFINED flags are ORd together
	self->u.number.ntype = NUMTYPE_UNDEFINED;
	self->u.number.addr_refs = refs;	// update address refs with local copy
}

// prototype for int/float passing
static void float_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other);
// int:
// handle dyadic operator
static void int_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	int	refs	= 0;	// default for "addr_refs", shortens this fn

	// first check type of second arg:
	if (other->u.number.ntype == NUMTYPE_INT) {
		// ok
	} else if (other->u.number.ntype == NUMTYPE_FLOAT) {
		// handle according to operation
		switch (op->id) {
		case OPID_POWEROF:
		case OPID_MULTIPLY:
		case OPID_DIVIDE:
		case OPID_INTDIV:
		case OPID_ADD:
		case OPID_SUBTRACT:
		case OPID_EQUALS:
		case OPID_LESSOREQUAL:
		case OPID_LESSTHAN:
		case OPID_GREATEROREQUAL:
		case OPID_GREATERTHAN:
		case OPID_NOTEQUAL:
			// become float, delegate to float handler
			int_to_float(self);
			float_handle_dyadic_operator(self, op, other);	// TODO - put recursion check around this?
			return;	// float handler has done everything

		case OPID_LSR:
		case OPID_AND:
		case OPID_OR:
		case OPID_EOR:
		case OPID_XOR:
			// convert other to int, warning user
			Throw_first_pass_warning(exception_float_to_int);	// FIXME - warning is never seen if arguments are undefined in first pass!
			/*FALLTHROUGH*/
		case OPID_MODULO:
		case OPID_SHIFTLEFT:
		case OPID_ASR:
			// convert other to int
			float_to_int(other);
			break;
// add new dyadic operators here:
//		case OPID_:
//			break;
		default:
			unsupported_operation(self, op, other);
			return;
		}
// add new types here:
//	} else if (other->u.number.ntype == NUMTYPE_) {
//		...
	} else {
		unsupported_operation(self, op, other);
		return;
	}
	// maybe put this into an extra "int_dyadic_int" function?
	// sanity check, now "other" must be an int
	if (other->u.number.ntype != NUMTYPE_INT)
		Bug_found("SecondArgIsNotAnInt", op->id);

	// part 2: now we got rid of non-ints, perform actual operation:
	switch (op->id) {
	case OPID_POWEROF:
		if (other->u.number.val.intval >= 0) {
			self->u.number.val.intval = my_pow(self->u.number.val.intval, other->u.number.val.intval);
		} else {
			Throw_error("Exponent is negative.");
			self->u.number.val.intval = 0;
		}
		break;
	case OPID_MULTIPLY:
		self->u.number.val.intval *= other->u.number.val.intval;
		break;
	case OPID_DIVIDE:
	case OPID_INTDIV:
		if (other->u.number.val.intval) {
			self->u.number.val.intval /= other->u.number.val.intval;
			break;
		}
		// "division by zero" output is below
		/*FALLTHROUGH*/
	case OPID_MODULO:
		if (other->u.number.val.intval) {
			self->u.number.val.intval %= other->u.number.val.intval;
		} else {
			Throw_error(exception_div_by_zero);
			self->u.number.val.intval = 0;
		}
		break;
	case OPID_ADD:
		self->u.number.val.intval += other->u.number.val.intval;
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
	case OPID_SUBTRACT:
		self->u.number.val.intval -= other->u.number.val.intval;
		refs = self->u.number.addr_refs - other->u.number.addr_refs;	// subtract address references
		break;
	case OPID_SHIFTLEFT:
		self->u.number.val.intval <<= other->u.number.val.intval;
		break;
	case OPID_ASR:
		self->u.number.val.intval = my_asr(self->u.number.val.intval, other->u.number.val.intval);
		break;
	case OPID_LSR:
		self->u.number.val.intval = ((uintval_t) (self->u.number.val.intval)) >> other->u.number.val.intval;
		break;
	case OPID_LESSOREQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval <= other->u.number.val.intval);
		return;

	case OPID_LESSTHAN:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval < other->u.number.val.intval);
		return;

	case OPID_GREATEROREQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval >= other->u.number.val.intval);
		return;

	case OPID_GREATERTHAN:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval > other->u.number.val.intval);
		return;

	case OPID_NOTEQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval != other->u.number.val.intval);
		return;

	case OPID_EQUALS:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.intval == other->u.number.val.intval);
		return;

	case OPID_AND:
		self->u.number.val.intval &= other->u.number.val.intval;
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
	case OPID_OR:
		self->u.number.val.intval |= other->u.number.val.intval;
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
	case OPID_EOR:
		Throw_first_pass_warning("\"EOR\" is deprecated; use \"XOR\" instead.");
		/*FALLTHROUGH*/
	case OPID_XOR:
		self->u.number.val.intval ^= other->u.number.val.intval;
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
// add new dyadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(self, op, other);
		return;
	}
	// CAUTION: comparisons call intfloat_fix_result_after_comparison instead of jumping here
	self->u.number.addr_refs = refs;	// update address refs with local copy
	intfloat_fix_result_after_dyadic(self, other);	// fix result flags
}

// float:
// handle dyadic operator
static void float_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	int	refs	= 0;	// default for "addr_refs", shortens this fn

	// first check type of second arg:
	if (other->u.number.ntype == NUMTYPE_FLOAT) {
		// ok
	} else if (other->u.number.ntype == NUMTYPE_INT) {
		// handle according to operation
		switch (op->id) {
		// these want two floats
		case OPID_POWEROF:
		case OPID_MULTIPLY:
		case OPID_DIVIDE:
		case OPID_INTDIV:
		case OPID_ADD:
		case OPID_SUBTRACT:
		case OPID_LESSOREQUAL:
		case OPID_LESSTHAN:
		case OPID_GREATEROREQUAL:
		case OPID_GREATERTHAN:
		case OPID_NOTEQUAL:
		case OPID_EQUALS:
			// convert other to float
			int_to_float(other);
			break;
		// these jump to int handler anyway
		case OPID_MODULO:
		case OPID_LSR:
		case OPID_AND:
		case OPID_OR:
		case OPID_EOR:
		case OPID_XOR:
		// these actually want a float and an int
		case OPID_SHIFTLEFT:
		case OPID_ASR:
			break;
// add new dyadic operators here
//		case OPID_:
//			break;
		default:
			unsupported_operation(self, op, other);
			return;
		}
// add new types here
//	} else if (other->u.number.ntype == NUMTYPE_) {
//		...
	} else {
		unsupported_operation(self, op, other);
		return;
	}

	switch (op->id) {
	case OPID_POWEROF:
		self->u.number.val.fpval = pow(self->u.number.val.fpval, other->u.number.val.fpval);
		break;
	case OPID_MULTIPLY:
		self->u.number.val.fpval *= other->u.number.val.fpval;
		break;
	case OPID_DIVIDE:
		if (other->u.number.val.fpval) {
			self->u.number.val.fpval /= other->u.number.val.fpval;
		} else {
			Throw_error(exception_div_by_zero);
			self->u.number.val.fpval = 0;
		}
		break;
	case OPID_INTDIV:
		if (other->u.number.val.fpval) {
			self->u.number.val.intval = self->u.number.val.fpval / other->u.number.val.fpval;	// fp becomes int!
		} else {
			Throw_error(exception_div_by_zero);
			self->u.number.val.intval = 0;
		}
		self->u.number.ntype = NUMTYPE_INT;	// result is int
		break;
	case OPID_LSR:
	case OPID_AND:
	case OPID_OR:
	case OPID_EOR:
	case OPID_XOR:
		Throw_first_pass_warning(exception_float_to_int);	// FIXME - warning is never seen if arguments are undefined in first pass!
		/*FALLTHROUGH*/
	case OPID_MODULO:
		float_to_int(self);
		// int handler will check other and, if needed, convert to int
		int_handle_dyadic_operator(self, op, other);	// TODO - put recursion check around this?
		return;	// int handler has done everything

	case OPID_ADD:
		self->u.number.val.fpval += other->u.number.val.fpval;
		refs = self->u.number.addr_refs + other->u.number.addr_refs;	// add address references
		break;
	case OPID_SUBTRACT:
		self->u.number.val.fpval -= other->u.number.val.fpval;
		refs = self->u.number.addr_refs - other->u.number.addr_refs;	// subtract address references
		break;
	case OPID_SHIFTLEFT:
		if (other->u.number.ntype == NUMTYPE_FLOAT)
			float_to_int(other);
		self->u.number.val.fpval *= pow(2.0, other->u.number.val.intval);
		break;
	case OPID_ASR:
		if (other->u.number.ntype == NUMTYPE_FLOAT)
			float_to_int(other);
		self->u.number.val.fpval /= (1 << other->u.number.val.intval);	// FIXME - why not use pow() as in SL above?
		break;
	case OPID_LESSOREQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval <= other->u.number.val.fpval);
		return;

	case OPID_LESSTHAN:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval < other->u.number.val.fpval);
		return;

	case OPID_GREATEROREQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval >= other->u.number.val.fpval);
		return;

	case OPID_GREATERTHAN:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval > other->u.number.val.fpval);
		return;

	case OPID_NOTEQUAL:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval != other->u.number.val.fpval);
		return;

	case OPID_EQUALS:
		intfloat_fix_result_after_comparison(self, other, self->u.number.val.fpval == other->u.number.val.fpval);
		return;

// add new dyadic operators here
//	case OPID_:
//		break;
	default:
		unsupported_operation(self, op, other);
		return;
	}
	// CAUTION: comparisons call intfloat_fix_result_after_comparison instead of jumping here
	self->u.number.addr_refs = refs;	// update address refs with local copy
	intfloat_fix_result_after_dyadic(self, other);	// fix result flags
}

// num:
// handle dyadic operator
static void number_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	// first check type of second arg:
	if (other->type != &type_number) {
		unsupported_operation(self, op, other);
		return;
	}

	if ((self->u.number.ntype == NUMTYPE_UNDEFINED)
	|| (other->u.number.ntype == NUMTYPE_UNDEFINED))
		undef_handle_dyadic_operator(self, op, other);
	else if (self->u.number.ntype == NUMTYPE_INT)
		int_handle_dyadic_operator(self, op, other);
	else if (self->u.number.ntype == NUMTYPE_FLOAT)
		float_handle_dyadic_operator(self, op, other);
	else
		Bug_found("IllegalNumberType2", self->u.number.ntype);
}


// helper function for lists and strings, check index
// return zero on success, nonzero on error
static int get_valid_index(int *target, int length, const struct object *self, const struct op *op, struct object *other)
{
	int	index;

	if (other->type != &type_number) {
		unsupported_operation(self, op, other);
		return 1;
	}
	if (other->u.number.ntype == NUMTYPE_UNDEFINED) {
		Throw_error("Index is undefined.");
		return 1;
	}
	if (other->u.number.ntype == NUMTYPE_FLOAT)
		float_to_int(other);
	if (other->u.number.ntype != NUMTYPE_INT)
		Bug_found("IllegalNumberType3", other->u.number.ntype);

	index = other->u.number.val.intval;
	// negative indices access from the end
	if (index < 0)
		index += length;
	if ((index < 0) || (index >= length)) {
		Throw_error("Index out of range.");
		return 1;
	}
	*target = index;
	return 0;	// ok
}

// list:
// handle dyadic operator
static void list_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	struct listitem	*item;
	int		length;
	int		index;

	length = self->u.listhead->u.listinfo.length;
	switch (op->id) {
	case OPID_LIST_APPEND:
		list_append_object(self->u.listhead, other);
		// no need to check/update ref count of "other": it loses the ref on the stack and gains one in the list
		return;

	case OPID_ATINDEX:
		if (get_valid_index(&index, length, self, op, other))
			return;	// error has been thrown

		list_to_item(self, index);
		return;	// ok

	case OPID_ADD:
		if (other->type != &type_list)
			break;	// complain
		item = self->u.listhead;	// get ref to first list
		list_init_list(self);	// replace first list on arg stack with new one
		list_append_list(self->u.listhead, item);
		item->u.listinfo.refs--;	// FIXME - call a function for this...
		item = other->u.listhead;
		list_append_list(self->u.listhead, item);
		item->u.listinfo.refs--;	// FIXME - call a function for this...
		return;

	case OPID_EQUALS:
		if (other->type != &type_list)
			break;	// complain	FIXME - return FALSE?
		int_create_byte(self, !list_differs(self, other));
		// FIXME - call function to decrement refs!
		return;

	case OPID_NOTEQUAL:
		if (other->type != &type_list)
			break;	// complain	FIXME - return TRUE?
		int_create_byte(self, list_differs(self, other));
		// FIXME - call function to decrement refs!
		return;

	//case ...:	// maybe comparisons?
	default:
		break;	// complain
	}
	unsupported_operation(self, op, other);
}

// string:
// handle dyadic operator
static void string_handle_dyadic_operator(struct object *self, const struct op *op, struct object *other)
{
	int		length;
	int		index;
	struct string	*arthur,
			*ford;

	length = self->u.string->length;
	switch (op->id) {
	case OPID_ATINDEX:
		if (get_valid_index(&index, length, self, op, other))
			return;	// error has already been reported

		string_to_byte(self, index);
		return;	// ok

	case OPID_ADD:
		if (other->type != &type_string)
			break;	// complain
		arthur = self->u.string;
		ford = other->u.string;
		string_prepare_string(self, arthur->length + ford->length);	// create string object and put on arg stack
		memcpy(self->u.string->payload, arthur->payload, arthur->length);
		memcpy(self->u.string->payload + arthur->length, ford->payload, ford->length);
		arthur->refs--;	// FIXME - call a function for this...
		ford->refs--;	// FIXME - call a function for this...
		return;
		
	case OPID_EQUALS:
		if (other->type != &type_string)
			break;	// complain	FIXME - return FALSE?
		arthur = self->u.string;
		ford = other->u.string;
		int_create_byte(self, !string_differs(self, other));
		arthur->refs--;	// FIXME - call a function for this...
		ford->refs--;	// FIXME - call a function for this...
		return;

	case OPID_NOTEQUAL:
		if (other->type != &type_string)
			break;	// complain	FIXME - return TRUE?
		arthur = self->u.string;
		ford = other->u.string;
		int_create_byte(self, string_differs(self, other));
		arthur->refs--;	// FIXME - call a function for this...
		ford->refs--;	// FIXME - call a function for this...
		return;

	//case ...:	// maybe comparisons?
	default:
		break;	// complain
	}
	unsupported_operation(self, op, other);
}

// int/float:
// set flags according to result
static void number_fix_result(struct object *self)
{
	// only allow a single force bit
	if (self->u.number.flags & NUMBER_FORCES_24)
		self->u.number.flags &= ~(NUMBER_FORCES_16 | NUMBER_FORCES_8);
	else if (self->u.number.flags & NUMBER_FORCES_16)
		self->u.number.flags &= ~NUMBER_FORCES_8;
}

// list/string:
// no need to fix results
static void object_no_op(struct object *self)
{
}

// int/float:
// print value for user message
#define NUMBUFSIZE	64	// large enough(tm) even for 64bit systems
static void number_print(const struct object *self, struct dynabuf *db)
{
	char	buffer[NUMBUFSIZE];

	if (self->u.number.ntype == NUMTYPE_UNDEFINED) {
		DynaBuf_add_string(db, "<UNDEFINED NUMBER>");
	} else if (self->u.number.ntype == NUMTYPE_INT) {
#if _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
		snprintf(buffer, NUMBUFSIZE, "%ld (0x%lx)", (long) self->u.number.val.intval, (long) self->u.number.val.intval);
#else
		sprintf(buffer, "%ld (0x%lx)", (long) self->u.number.val.intval, (long) self->u.number.val.intval);
#endif
		DynaBuf_add_string(db, buffer);
	} else if (self->u.number.ntype == NUMTYPE_FLOAT) {
		// write up to 30 significant characters.
		// remaining 10 should suffice for sign,
		// decimal point, exponent, terminator etc.
		sprintf(buffer, "%.30g", self->u.number.val.fpval);
		DynaBuf_add_string(db, buffer);
	} else {
		Bug_found("IllegalNumberType5", self->u.number.ntype);
	}
}

// list:
// print value for user message
static void list_print(const struct object *self, struct dynabuf *db)
{
	struct listitem	*item;
	int		length;
	struct object	*obj;
	const char	*prefix	= "";	// first item does not get a prefix

	DynaBuf_append(db, '[');
	length = self->u.listhead->u.listinfo.length;
	item = self->u.listhead->next;
	while (length--) {
		obj = &item->u.payload;
		DynaBuf_add_string(db, prefix);
		obj->type->print(obj, db);
		item = item->next;
		prefix = ", ";	// following items are prefixed
	}
	DynaBuf_append(db, ']');
}

// string:
// print value for user message
static void string_print(const struct object *self, struct dynabuf *db)
{
	DynaBuf_add_string(db, self->u.string->payload);	// there is a terminator after the actual payload, so this works
}

// number:
// is not iterable
static int has_no_length(const struct object *self)
{
	return -1;	// not iterable
}

// list:
// return length
static int list_get_length(const struct object *self)
{
	return self->u.listhead->u.listinfo.length;
}

// string:
// return length
static int string_get_length(const struct object *self)
{
	return self->u.string->length;
}

// number:
// cannot be indexed
static void cannot_be_indexed(const struct object *self, struct object *target, int index)
{
	Bug_found("TriedToIndexNumber", index);
}

// list:
// return item at index
static void list_at(const struct object *self, struct object *target, int index)
{
	*target = *self;
	list_to_item(target, index);
}

// string:
// return char at index
static void string_at(const struct object *self, struct object *target, int index)
{
	*target = *self;
	string_to_byte(target, index);
}

// "class" definitions
struct type	type_number	= {
	"number",
	number_is_defined,
	number_differs,
	number_assign,
	number_handle_monadic_operator,
	number_handle_dyadic_operator,
	number_fix_result,
	number_print,
	has_no_length,
	cannot_be_indexed
};
struct type	type_list	= {
	"list",
	list_is_defined,
	list_differs,
	list_assign,
	list_handle_monadic_operator,
	list_handle_dyadic_operator,
	object_no_op,	// no need to fix list results
	list_print,
	list_get_length,
	list_at
};
struct type	type_string	= {
	"string",
	object_return_true,	// strings are always defined
	string_differs,
	string_assign,
	string_handle_monadic_operator,
	string_handle_dyadic_operator,
	object_no_op,	// no need to fix string results
	string_print,
	string_get_length,
	string_at
};


// this is what the exported functions call
// returns nonzero on parse error
static int parse_expression(struct expression *expression)
{
	struct object	*result	= &expression->result;

	// make sure stacks are ready (if not yet initialised, do it now)
	if (arg_stack == NULL)
		enlarge_argument_stack();
	if (op_stack == NULL)
		enlarge_operator_stack();

	// init
	expression->is_empty = TRUE;	// becomes FALSE when first valid char gets parsed
	expression->open_parentheses = 0;
	expression->is_parenthesized = FALSE;	// '(' operator sets this to TRUE, all others to FALSE. outermost operator wins!
	//expression->number will be overwritten later, so no need to init

	op_sp = 0;	// operator stack pointer
	arg_sp = 0;	// argument stack pointer
	// begin by reading an argument (or a monadic operator)
	PUSH_OP(&ops_start_expression);
	alu_state = STATE_EXPECT_ARG_OR_MONADIC_OP;
	do {
		// check arg stack size. enlarge if needed
		if (arg_sp >= argstack_size)
			enlarge_argument_stack();
		// (op stack size is checked whenever pushing an operator)
		switch (alu_state) {
		case STATE_EXPECT_ARG_OR_MONADIC_OP:
			if (expect_argument_or_monadic_operator(expression))
				expression->is_empty = FALSE;
			break;
		case STATE_EXPECT_DYADIC_OP:
			expect_dyadic_operator(expression);
			break;
		case STATE_MAX_GO_ON:	// suppress
		case STATE_ERROR:	// compiler
		case STATE_END:		// warnings
			break;
		}
	} while (alu_state < STATE_MAX_GO_ON);
	// done. check state.
	if (alu_state == STATE_END) {
		// check for bugs
		if (arg_sp != 1)
			Bug_found("ArgStackNotEmpty", arg_sp);
		if (op_sp != 1)
			Bug_found("OperatorStackNotEmpty", op_sp);
		// copy result
		*result = arg_stack[0];
		// if there was nothing to parse, mark as undefined	FIXME - change this! make "nothing" its own result type; only numbers may be undefined
		// (so ALU_defined_int() can react)
		if (expression->is_empty) {
			result->type = &type_number;
			result->u.number.ntype = NUMTYPE_UNDEFINED;
			result->u.number.flags = NUMBER_EVER_UNDEFINED;
			result->u.number.addr_refs = 0;
		} else {
			// not empty. undefined?
			if (!(result->type->is_defined(result))) {
				// then count (in all passes)
				++pass.undefined_count;
			}
		}
		// do some checks depending on int/float
		result->type->fix_result(result);
		return 0;	// ok
	} else {
		// State is STATE_ERROR. Errors have already been reported,
		// but we must make sure not to pass bogus data to caller.
		// FIXME - just use the return value to indicate "there were errors, do not use result!"
		result->type = &type_number;
		result->u.number.ntype = NUMTYPE_UNDEFINED;	// maybe use NUMTYPE_INT to suppress follow-up errors?
		result->u.number.flags = 0;
		//result->u.number.val.intval = 0;
		result->u.number.addr_refs = 0;
		// make sure no additional (spurious) errors are reported:
		Input_skip_remainder();
		// FIXME - remove this when new function interface gets used:
		// callers must decide for themselves what to do when expression
		// parser returns error (and may decide to call Input_skip_remainder)
		return 1;	// error
	}
}


// store int value (if undefined, store zero)
// For empty expressions, an error is thrown.
// OPEN_PARENTHESIS: complain
// EMPTY: complain
// UNDEFINED: allow
// FLOAT: convert to int
void ALU_any_int(intval_t *target)	// ACCEPT_UNDEFINED
{
	struct expression	expression;

	parse_expression(&expression);	// FIXME - check return value and pass to caller!
	if (expression.open_parentheses)
		Throw_error(exception_paren_open);
	if (expression.is_empty)
		Throw_error(exception_no_value);
	if (expression.result.type == &type_number) {
		if (expression.result.u.number.ntype == NUMTYPE_UNDEFINED)
			*target = 0;
		else if (expression.result.u.number.ntype == NUMTYPE_INT)
			*target = expression.result.u.number.val.intval;
		else if (expression.result.u.number.ntype == NUMTYPE_FLOAT)
			*target = expression.result.u.number.val.fpval;
		else
			Bug_found("IllegalNumberType6", expression.result.u.number.ntype);
	} else if (expression.result.type == &type_string) {
		// accept single-char strings, to be more
		// compatible with versions before 0.97:
		if (expression.result.u.string->length != 1) {
			Throw_error(exception_lengthnot1);
		} else {
			// FIXME - throw a warning?
		}
		string_to_byte(&(expression.result), 0);
		*target = expression.result.u.number.val.intval;
	} else {
		*target = 0;
		Throw_error(exception_not_number);
	}
}


// stores int value and flags (floats are transformed to int)
// if result is empty or undefined, serious error is thrown
// OPEN_PARENTHESIS: complain
// EMPTY: complain _seriously_
// UNDEFINED: complain _seriously_
// FLOAT: convert to int
// FIXME - only very few callers actually _need_ a serious error to be thrown,
// so throw a normal one here and pass ok/fail as return value, so caller can react.
void ALU_defined_int(struct number *intresult)	// no ACCEPT constants?
{
	struct expression	expression;
	boolean			buf	= pass.complain_about_undefined;

	pass.complain_about_undefined = TRUE;
	parse_expression(&expression);	// FIXME - check return value and pass to caller!
	pass.complain_about_undefined = buf;
/*
FIXME - that "buffer COMPLAIN status" thing no longer works: now that we have
lists, stuff like
	[2, 3, undefined][0]
or
	len([2,3,undefined])
throws errors even though the result is defined!
*/
	if (expression.open_parentheses)
		Throw_error(exception_paren_open);
	if (expression.is_empty)
		Throw_serious_error(exception_no_value);
	if (expression.result.type == &type_number) {
		if (expression.result.u.number.ntype == NUMTYPE_UNDEFINED) {
			Throw_serious_error("Value not defined.");
			expression.result.u.number.val.intval = 0;
		} else if (expression.result.u.number.ntype == NUMTYPE_INT) {
			// ok
		} else if (expression.result.u.number.ntype == NUMTYPE_FLOAT) {
			float_to_int(&expression.result);
		} else {
			Bug_found("IllegalNumberType7", expression.result.u.number.ntype);
		}
	} else if (expression.result.type == &type_string) {
		// accept single-char strings, to be more
		// compatible with versions before 0.97:
		if (expression.result.u.string->length != 1) {
			Throw_error(exception_lengthnot1);
		} else {
			// FIXME - throw a warning?
		}
		string_to_byte(&(expression.result), 0);
	} else {
		Throw_serious_error(exception_not_number);
	}
	*intresult = expression.result.u.number;
}


// Store int value and flags.
// This function allows for "paren" '(' too many. Needed when parsing indirect
// addressing modes where internal indices have to be possible.
// For empty expressions, an error is thrown.
// OPEN_PARENTHESIS: depends on arg
// UNDEFINED: allow
// EMPTY: complain
// FLOAT: convert to int
void ALU_addrmode_int(struct expression *expression, int paren)	// ACCEPT_UNDEFINED | ACCEPT_OPENPARENTHESIS
{
	parse_expression(expression);	// FIXME - check return value and pass to caller!
	if (expression->result.type == &type_number) {
		// convert float to int
		if (expression->result.u.number.ntype == NUMTYPE_FLOAT)
			float_to_int(&(expression->result));
		else if (expression->result.u.number.ntype == NUMTYPE_UNDEFINED)
			expression->result.u.number.val.intval = 0;
	} else if (expression->result.type == &type_string) {
		// accept single-char strings, to be more
		// compatible with versions before 0.97:
		if (expression->result.u.string->length != 1) {
			Throw_error(exception_lengthnot1);
		} else {
			// FIXME - throw a warning?
		}
		string_to_byte(&(expression->result), 0);
	} else {
		Throw_error(exception_not_number);
	}
	if (expression->open_parentheses > paren) {
		expression->open_parentheses = 0;
		Throw_error(exception_paren_open);
	}
	if (expression->is_empty)
		Throw_error(exception_no_value);
}


// Store resulting object
// For empty expressions, an error is thrown.
// OPEN_PARENTHESIS: complain
// EMPTY: complain
// UNDEFINED: allow
// FLOAT: keep
void ALU_any_result(struct object *result)	// ACCEPT_UNDEFINED | ACCEPT_FLOAT
{
	struct expression	expression;

	parse_expression(&expression);	// FIXME - check return value and pass to caller!
	*result = expression.result;
	if (expression.open_parentheses)
		Throw_error(exception_paren_open);
	if (expression.is_empty)
		Throw_error(exception_no_value);
}


/* TODO

maybe move
	if (expression.is_empty)
		Throw_error(exception_no_value);
to end of parse_expression()


// stores int value and flags, allowing for "paren" '(' too many (x-indirect addr).
void ALU_addrmode_int(struct expression *expression, int paren)
	mnemo.c
		when parsing addressing modes						needvalue!

// store resulting object
void ALU_any_result(struct object *result)
	macro.c
		macro call, when parsing call-by-value arg				don't care
	pseudoopcodes.c
		!set									don't care
		when throwing user-specified errors					don't care
		iterator for !by, !wo, etc.						needvalue!
		byte values in !raw, !tx, etc.						needvalue!
		!scrxor									needvalue!
	symbol.c
		explicit symbol definition						don't care

// stores int value and flags (floats are transformed to int)
// if result was undefined, serious error is thrown
void ALU_defined_int(struct number *intresult)
	flow.c
		when parsing loop conditions		make bool			serious
	pseudoopcodes.c
		*=					(FIXME, allow undefined)	needvalue!
		!initmem								error
		!fill (1st arg)				(maybe allow undefined?)	needvalue!
		!skip					(maybe allow undefined?)	needvalue!
		!align (1st + 2nd arg)			(maybe allow undefined?)	needvalue!
		!pseudopc				(FIXME, allow undefined)	needvalue!
		!if					make bool			serious
		twice in !for								serious
		twice for !binary			(maybe allow undefined?)	needvalue!
		//!enum

// store int value (0 if result was undefined)
void ALU_any_int(intval_t *target)
	pseudoopcodes.c
		!xor									needvalue!
		!fill (2nd arg)								needvalue!
		!align (3rd arg)							needvalue!
*/
