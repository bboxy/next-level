// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Global stuff - things that are needed by several modules
//  4 Oct 2006	Fixed a typo in a comment
// 22 Nov 2007	Added warn_on_indented_labels
//  2 Jun 2014	Added warn_on_old_for and warn_on_type_mismatch
// 19 Nov 2014	Merged Johann Klasek's report listing generator patch
// 23 Nov 2014	Merged Martin Piper's "--msvc" error output patch
//  9 Jan 2018	Made '/' a syntax char to allow for "//" comments
// 14 Apr 2020	Added config vars for "ignore zeroes" and "segment warnings to errors"
#include "global.h"
#include <stdio.h>
#include "platform.h"
#include "acme.h"
#include "alu.h"
#include "cpu.h"
#include "dynabuf.h"
#include "encoding.h"
#include "input.h"
#include "macro.h"
#include "output.h"
#include "pseudoopcodes.h"
#include "section.h"
#include "symbol.h"
#include "tree.h"
#include "typesystem.h"


// constants
char		s_untitled[]	= "<untitled>";	// FIXME - this is actually const


// Exception messages during assembly
const char	exception_missing_string[]	= "No string given.";
const char	exception_negative_size[]	= "Negative size argument.";
const char	exception_no_left_brace[]	= "Missing '{'.";
const char	exception_no_memory_left[]	= "Out of memory.";
const char	exception_no_right_brace[]	= "Found end-of-file instead of '}'.";
//const char	exception_not_yet[]	= "Sorry, feature not yet implemented.";
// TODO - show actual value in error message
const char	exception_number_out_of_range[]	= "Number out of range.";
const char	exception_number_out_of_8b_range[]	= "Number does not fit in 8 bits.";
static const char	exception_number_out_of_16b_range[]	= "Number does not fit in 16 bits.";
static const char	exception_number_out_of_24b_range[]	= "Number does not fit in 24 bits.";
const char	exception_pc_undefined[]	= "Program counter undefined.";
const char	exception_symbol_defined[]	= "Symbol already defined.";
const char	exception_syntax[]		= "Syntax error.";
// default value for number of errors before exiting
#define MAXERRORS	10

// Flag table:
// This table contains flags for all the 256 possible byte values. The
// assembler reads the table whenever it needs to know whether a byte is
// allowed to be in a label name, for example.
//   Bits	Meaning when set
// 7.......	Byte allowed to start keyword
// .6......	Byte allowed in keyword
// ..5.....	Byte is upper case, can be lowercased by OR-ing this bit(!)
// ...4....	special character for input syntax: 0x00 TAB LF CR SPC / : ; }
// ....3...	preceding sequence of '-' characters is anonymous backward
//		label. Currently only set for ')', ',' and CHAR_EOS.
// .....210	currently unused
const char	global_byte_flags[256]	= {
/*$00*/	0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,// control characters
	0x00, 0x10, 0x10, 0x00, 0x00, 0x10, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
/*$20*/	0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,// " !"#$%&'"
	0x00, 0x08, 0x00, 0x00, 0x08, 0x00, 0x00, 0x10,// "()*+,-./"
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,// "01234567"
	0x40, 0x40, 0x10, 0x10, 0x00, 0x00, 0x00, 0x00,// "89:;<=>?"
/*$40*/	0x00, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0,// "@ABCDEFG"
	0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0,// "HIJKLMNO"
	0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0, 0xe0,// "PQRSTUVW"
	0xe0, 0xe0, 0xe0, 0x00, 0x00, 0x00, 0x00, 0xc0,// "XYZ[\]^_"
/*$60*/	0x00, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,// "`abcdefg"
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,// "hijklmno"
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,// "pqrstuvw"
	0xc0, 0xc0, 0xc0, 0x00, 0x00, 0x10, 0x00, 0x00,// "xyz{|}~" BACKSPACE
/*$80*/	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,// umlauts etc. ...
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
/*$a0*/	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
/*$c0*/	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
/*$e0*/	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0,
};


// variables
char		GotByte;			// Last byte read (processed)
struct report 	*report			= NULL;
struct config	config;
struct pass	pass;

// set configuration to default values
void config_default(struct config *conf)
{
	conf->pseudoop_prefix		= '!';	// can be changed to '.' by CLI switch
	conf->process_verbosity		= 0;	// level of additional output
	conf->warn_on_indented_labels	= TRUE;	// warn if indented label is encountered
	conf->warn_on_type_mismatch	= FALSE;	// use type-checking system
	conf->warn_bin_mask		= 3;  // %11 -> warn if not divisible by four
	conf->max_errors		= MAXERRORS;	// errors before giving up
	conf->format_msvc		= FALSE;	// enabled by --msvc
	conf->format_color		= FALSE;	// enabled by --color
	conf->msg_stream		= stderr;	// set to stdout by --use-stdout
	conf->honor_leading_zeroes	= TRUE;		// disabled by --ignore-zeroes
	conf->segment_warning_is_error	= FALSE;	// enabled by --strict-segments		TODO - toggle default?
	conf->test_new_features		= FALSE;	// enabled by --test
	conf->wanted_version		= VER_CURRENT;	// changed by --dialect
}

// memory allocation stuff

// allocate memory and die if not available
void *safe_malloc(size_t size)
{
	void	*block;

	if ((block = malloc(size)) == NULL)
		Throw_serious_error(exception_no_memory_left);
	return block;
}


// Parser stuff


// Check and return whether first label of statement. Complain if not.
static int first_label_of_statement(bits *statement_flags)
{
	if ((*statement_flags) & SF_IMPLIED_LABEL) {
		Throw_error(exception_syntax);
		Input_skip_remainder();
		return FALSE;
	}
	(*statement_flags) |= SF_IMPLIED_LABEL;	// now there has been one
	return TRUE;
}


// parse label definition (can be either global or local).
// name must be held in GlobalDynaBuf.
// called by parse_symbol_definition, parse_backward_anon_def, parse_forward_anon_def
// "powers" is used by backward anons to allow changes
static void set_label(scope_t scope, bits stat_flags, bits force_bit, bits powers)
{
	struct symbol	*symbol;
	struct number	pc;
	struct object	result;

	if ((stat_flags & SF_FOUND_BLANK) && config.warn_on_indented_labels)
		Throw_first_pass_warning("Label name not in leftmost column.");
	symbol = symbol_find(scope);
	vcpu_read_pc(&pc);	// FIXME - if undefined, check pass.complain_about_undefined and maybe throw "value not defined"!
	result.type = &type_number;
	result.u.number.ntype = NUMTYPE_INT;	// FIXME - if undefined, use NUMTYPE_UNDEFINED!
	result.u.number.flags = 0;
	result.u.number.val.intval = pc.val.intval;
	result.u.number.addr_refs = pc.addr_refs;
	symbol_set_object(symbol, &result, powers);
	if (force_bit)
		symbol_set_force_bit(symbol, force_bit);
	symbol->pseudopc = pseudopc_get_context();
	// global labels must open new scope for cheap locals
	if (scope == SCOPE_GLOBAL)
		section_new_cheap_scope(section_now);
}


// call with symbol name in GlobalDynaBuf and GotByte == '='
// "powers" is for "!set" pseudo opcode so changes are allowed (see symbol.h for powers)
void parse_assignment(scope_t scope, bits force_bit, bits powers)
{
	struct symbol	*symbol;
	struct object	result;

	GetByte();	// eat '='
	symbol = symbol_find(scope);
	ALU_any_result(&result);
	// if wanted, mark as address reference
	if (typesystem_says_address()) {
		// FIXME - checking types explicitly is ugly...
		if (result.type == &type_number)
			result.u.number.addr_refs = 1;
	}
	symbol_set_object(symbol, &result, powers);
	if (force_bit)
		symbol_set_force_bit(symbol, force_bit);
}


// parse symbol definition (can be either global or local, may turn out to be a label).
// name must be held in GlobalDynaBuf.
static void parse_symbol_definition(scope_t scope, bits stat_flags)
{
	bits	force_bit;

	force_bit = Input_get_force_bit();	// skips spaces after	(yes, force bit is allowed for label definitions)
	if (GotByte == '=') {
		// explicit symbol definition (symbol = <something>)
		parse_assignment(scope, force_bit, POWER_NONE);
		Input_ensure_EOS();
	} else {
		// implicit symbol definition (label)
		set_label(scope, stat_flags, force_bit, POWER_NONE);
	}
}


// Parse global symbol definition or assembler mnemonic
static void parse_mnemo_or_global_symbol_def(bits *statement_flags)
{
	boolean	is_mnemonic;

	is_mnemonic = CPU_state.type->keyword_is_mnemonic(Input_read_keyword());
	// It is only a label if it isn't a mnemonic
	if ((!is_mnemonic)
	&& first_label_of_statement(statement_flags)) {
		// Now GotByte = illegal char
		// 04 Jun 2005: this fix should help to explain "strange" error messages.
		// 17 May 2014: now it works for UTF-8 as well.
		if ((*GLOBALDYNABUF_CURRENT == (char) 0xa0)
		|| ((GlobalDynaBuf->size >= 2) && (GLOBALDYNABUF_CURRENT[0] == (char) 0xc2) && (GLOBALDYNABUF_CURRENT[1] == (char) 0xa0)))
			Throw_first_pass_warning("Label name starts with a shift-space character.");
		parse_symbol_definition(SCOPE_GLOBAL, *statement_flags);
	}
}


// parse (cheap) local symbol definition
static void parse_local_symbol_def(bits *statement_flags, scope_t scope)
{
	if (!first_label_of_statement(statement_flags))
		return;

	GetByte();	// start after '.'/'@'
	if (Input_read_keyword())
		parse_symbol_definition(scope, *statement_flags);
}


// parse anonymous backward label definition. Called with GotByte == '-'
static void parse_backward_anon_def(bits *statement_flags)
{
	if (!first_label_of_statement(statement_flags))
		return;

	DYNABUF_CLEAR(GlobalDynaBuf);
	do
		DYNABUF_APPEND(GlobalDynaBuf, '-');
	while (GetByte() == '-');
	DynaBuf_append(GlobalDynaBuf, '\0');
	// backward anons change their value!
	set_label(section_now->local_scope, *statement_flags, NO_FORCE_BIT, POWER_CHANGE_VALUE);
}


// parse anonymous forward label definition. called with GotByte == ?
static void parse_forward_anon_def(bits *statement_flags)
{
	if (!first_label_of_statement(statement_flags))
		return;

	DYNABUF_CLEAR(GlobalDynaBuf);
	DynaBuf_append(GlobalDynaBuf, '+');
	while (GotByte == '+') {
		DYNABUF_APPEND(GlobalDynaBuf, '+');
		GetByte();
	}
	symbol_fix_forward_anon_name(TRUE);	// TRUE: increment counter
	DynaBuf_append(GlobalDynaBuf, '\0');
	//printf("[%d, %s]\n", section_now->local_scope, GlobalDynaBuf->buffer);
	set_label(section_now->local_scope, *statement_flags, NO_FORCE_BIT, POWER_NONE);
}


// Parse block, beginning with next byte.
// End reason (either CHAR_EOB or CHAR_EOF) can be found in GotByte afterwards
// Has to be re-entrant.
void Parse_until_eob_or_eof(void)
{
	bits	statement_flags;

//	// start with next byte, don't care about spaces
//	NEXTANDSKIPSPACE();
	// start with next byte
	GetByte();
	// loop until end of block or end of file
	while ((GotByte != CHAR_EOB) && (GotByte != CHAR_EOF)) {
		// process one statement
		statement_flags = 0;	// no "label = pc" definition yet
		typesystem_force_address_statement(FALSE);
		// Parse until end of statement. Only loops if statement
		// contains implicit label definition (=pc) and something else; or
		// if "!ifdef/ifndef" is true/false, or if "!addr" is used without block.
		do {
			// check for pseudo opcodes was moved out of switch,
			// because prefix character is now configurable.
			if (GotByte == config.pseudoop_prefix) {
				pseudoopcode_parse();
			} else {
				switch (GotByte) {
				case CHAR_EOS:	// end of statement
					// Ignore now, act later
					// (stops from being "default")
					break;
				case ' ':	// space
					statement_flags |= SF_FOUND_BLANK;
					/*FALLTHROUGH*/
				case CHAR_SOL:	// start of line
					GetByte();	// skip
					break;
				case '-':
					parse_backward_anon_def(&statement_flags);
					break;
				case '+':
					GetByte();
					if ((GotByte == LOCAL_PREFIX)	// TODO - allow "cheap macros"?!
					|| (BYTE_CONTINUES_KEYWORD(GotByte)))
						Macro_parse_call();
					else
						parse_forward_anon_def(&statement_flags);
					break;
				case '*':
					notreallypo_setpc();	// define program counter (fn is in pseudoopcodes.c)
					break;
				case LOCAL_PREFIX:
					parse_local_symbol_def(&statement_flags, section_now->local_scope);
					break;
				case CHEAP_PREFIX:
					parse_local_symbol_def(&statement_flags, section_now->cheap_scope);
					break;
				default:
					if (BYTE_STARTS_KEYWORD(GotByte)) {
						parse_mnemo_or_global_symbol_def(&statement_flags);
					} else {
						Throw_error(exception_syntax);
						Input_skip_remainder();
					}
				}
			}
		} while (GotByte != CHAR_EOS);	// until end-of-statement
		vcpu_end_statement();	// adjust program counter
		// go on with next byte
		GetByte();	//NEXTANDSKIPSPACE();
	}
}


// Skip space. If GotByte is CHAR_SOB ('{'), parse block and return TRUE.
// Otherwise (if there is no block), return FALSE.
// Don't forget to call EnsureEOL() afterwards.
int Parse_optional_block(void)
{
	SKIPSPACE();
	if (GotByte != CHAR_SOB)
		return FALSE;
	Parse_until_eob_or_eof();
	if (GotByte != CHAR_EOB)
		Throw_serious_error(exception_no_right_brace);
	GetByte();
	return TRUE;
}


// Error handling

// error/warning counter so macro calls can find out whether to show a call stack
static int	throw_counter	= 0;
int Throw_get_counter(void)
{
	return throw_counter;
}

// This function will do the actual output for warnings, errors and serious
// errors. It shows the given message string, as well as the current
// context: file name, line number, source type and source title.
// TODO: make un-static so !info and !debug can use this.
static void throw_message(const char *message, const char *type)
{
	++throw_counter;
	if (config.format_msvc)
		fprintf(config.msg_stream, "%s(%d) : %s (%s %s): %s\n",
			Input_now->original_filename, Input_now->line_number,
			type, section_now->type, section_now->title, message);
	else
		fprintf(config.msg_stream, "%s - File %s, line %d (%s %s): %s\n",
			type, Input_now->original_filename, Input_now->line_number,
			section_now->type, section_now->title, message);
}


// Output a warning.
// This means the produced code looks as expected. But there has been a
// situation that should be reported to the user, for example ACME may have
// assembled a 16-bit parameter with an 8-bit value.
void Throw_warning(const char *message)
{
	PLATFORM_WARNING(message);
	if (config.format_color)
		throw_message(message, "\033[33mWarning\033[0m");
	else
		throw_message(message, "Warning");
}
// Output a warning if in first pass. See above.
void Throw_first_pass_warning(const char *message)
{
	if (FIRST_PASS)
		Throw_warning(message);
}


// Output an error.
// This means something went wrong in a way that implies that the output
// almost for sure won't look like expected, for example when there was a
// syntax error. The assembler will try to go on with the assembly though, so
// the user gets to know about more than one of his typos at a time.
void Throw_error(const char *message)
{
	PLATFORM_ERROR(message);
	if (config.format_color)
		throw_message(message, "\033[31mError\033[0m");
	else
		throw_message(message, "Error");
	++pass.error_count;
	if (pass.error_count >= config.max_errors)
		exit(ACME_finalize(EXIT_FAILURE));
}


// Output a serious error, stopping assembly.
// Serious errors are those that make it impossible to go on with the
// assembly. Example: "!fill" without a parameter - the program counter cannot
// be set correctly in this case, so proceeding would be of no use at all.
void Throw_serious_error(const char *message)
{
	PLATFORM_SERIOUS(message);
	if (config.format_color)
		throw_message(message, "\033[1m\033[31mSerious error\033[0m");
	else
		throw_message(message, "Serious error");
	// FIXME - exiting immediately inhibits output of macro call stack!
	exit(ACME_finalize(EXIT_FAILURE));
}


// Handle bugs
void Bug_found(const char *message, int code)
{
	Throw_warning("Bug in ACME, code follows");
	fprintf(stderr, "(0x%x:)", code);
	Throw_serious_error(message);
}


// insert object (in case of list, will iterate/recurse until done)
void output_object(struct object *object, struct iter_context *iter)
{
	struct listitem	*item;
	int		length;
	char		*read;

	if (object->type == &type_number) {
		if (object->u.number.ntype == NUMTYPE_UNDEFINED)
			iter->fn(0);
		else if (object->u.number.ntype == NUMTYPE_INT)
			iter->fn(object->u.number.val.intval);
		else if (object->u.number.ntype == NUMTYPE_FLOAT)
			iter->fn(object->u.number.val.fpval);
		else
			Bug_found("IllegalNumberType0", object->u.number.ntype);
	} else if (object->type == &type_list) {
		// iterate over list
		item = object->u.listhead->next;
		while (item != object->u.listhead) {
			output_object(&item->u.payload, iter);
			item = item->next;
		}
	} else if (object->type == &type_string) {
		// iterate over string
		read = object->u.string->payload;
		length = object->u.string->length;
		// single-char strings are accepted, to be more compatible with
		// versions before 0.97 (and empty strings are not really a problem...)
		if (iter->accept_long_strings || (length < 2)) {
			while (length--)
				iter->fn(iter->stringxor ^ encoding_encode_char(*(read++)));
		} else {
			Throw_error("There's more than one character.");	// see alu.c for the original of this error
		}
	} else {
		Bug_found("IllegalObjectType", 0);
	}
}


// output 8-bit value with range check
void output_8(intval_t value)
{
	if ((value < -0x80) || (value > 0xff))
		Throw_error(exception_number_out_of_8b_range);
	Output_byte(value);
}


// output 16-bit value with range check big-endian
void output_be16(intval_t value)
{
	if ((value < -0x8000) || (value > 0xffff))
		Throw_error(exception_number_out_of_16b_range);
	Output_byte(value >> 8);
	Output_byte(value);
}


// output 16-bit value with range check little-endian
void output_le16(intval_t value)
{
	if ((value < -0x8000) || (value > 0xffff))
		Throw_error(exception_number_out_of_16b_range);
	Output_byte(value);
	Output_byte(value >> 8);
}


// output 24-bit value with range check big-endian
void output_be24(intval_t value)
{
	if ((value < -0x800000) || (value > 0xffffff))
		Throw_error(exception_number_out_of_24b_range);
	Output_byte(value >> 16);
	Output_byte(value >> 8);
	Output_byte(value);
}


// output 24-bit value with range check little-endian
void output_le24(intval_t value)
{
	if ((value < -0x800000) || (value > 0xffffff))
		Throw_error(exception_number_out_of_24b_range);
	Output_byte(value);
	Output_byte(value >> 8);
	Output_byte(value >> 16);
}


// FIXME - the range checks below are commented out because 32-bit
// signed integers cannot exceed the range of 32-bit signed integers.
// But now that 64-bit machines are the norm, "intval_t" might be a
// 64-bit int. I need to address this problem one way or another.


// output 32-bit value (without range check) big-endian
void output_be32(intval_t value)
{
//	if ((value < -0x80000000) || (value > 0xffffffff))
//		Throw_error(exception_number_out_of_32b_range);
	Output_byte(value >> 24);
	Output_byte(value >> 16);
	Output_byte(value >> 8);
	Output_byte(value);
}


// output 32-bit value (without range check) little-endian
void output_le32(intval_t value)
{
//	if ((value < -0x80000000) || (value > 0xffffffff))
//		Throw_error(exception_number_out_of_32b_range);
	Output_byte(value);
	Output_byte(value >> 8);
	Output_byte(value >> 16);
	Output_byte(value >> 24);
}
