// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Flow control stuff (loops, conditional assembly etc.)
//
// Macros, conditional assembly, loops and sourcefile-includes are all based on
// parsing blocks of code. When defining macros or using loops or conditional
// assembly, the block starts with "{" and ends with "}". In the case of
// "!source", the given file is treated like a block - the outermost assembler
// function uses the same technique to parse the top level file.
//
// 24 Nov 2007	Added "!ifndef"
#include "flow.h"
#include <string.h>
#include "acme.h"
#include "alu.h"
#include "config.h"
#include "dynabuf.h"
#include "global.h"
#include "input.h"
#include "mnemo.h"
#include "symbol.h"
#include "tree.h"


// helper functions for if/ifdef/ifndef/else/for/do/while


// parse symbol name and return if symbol has defined value (called by ifdef/ifndef)
boolean check_ifdef_condition(void)
{
	scope_t		scope;
	struct rwnode	*node;
	struct symbol	*symbol;

	// read symbol name
	if (Input_read_scope_and_keyword(&scope) == 0)	// skips spaces before
		return FALSE;	// there was an error, it has been reported, so return value is more or less meaningless anway

	// look for it
	Tree_hard_scan(&node, symbols_forest, scope, FALSE);
	if (!node)
		return FALSE;	// not found -> no, not defined

	symbol = (struct symbol *) node->body;
	symbol->has_been_read = TRUE;	// we did not really read the symbol's value, but checking for its existence still counts as "used it"
	if (symbol->object.type == NULL)
		Bug_found("ObjectHasNullType", 0);
	return symbol->object.type->is_defined(&symbol->object);
}


// parse a loop body (TODO - also use for macro body?)
static void parse_ram_block(struct block *block)
{
	Input_now->line_number = block->start;	// set line number to loop start
	Input_now->src.ram_ptr = block->body;	// set RAM read pointer to loop
	// parse block
	Parse_until_eob_or_eof();
	if (GotByte != CHAR_EOB)
		Bug_found("IllegalBlockTerminator", GotByte);
}


// function for "!for" with counter variable
static void counting_for(struct for_loop *loop)
{
	struct object	loop_var;

	// init counter
	loop_var.type = &type_number;
	loop_var.u.number.ntype = NUMTYPE_INT;
	loop_var.u.number.flags = 0;
	loop_var.u.number.val.intval = 0;	// SEE BELOW - default value if old algo skips loop entirely
	loop_var.u.number.addr_refs = loop->u.counter.addr_refs;
	// CAUTION: next line does not have power to change symbol type, but if
	// "symbol already defined" error is thrown, the type will still have
	// been changed. this was done so the code below has a counter var.
	symbol_set_object(loop->symbol, &loop_var, POWER_CHANGE_VALUE);
	// TODO: in versions before 0.97, force bit handling was broken
	// in both "!set" and "!for":
	// trying to change a force bit correctly raised an error, but
	// in any case, ALL FORCE BITS WERE CLEARED in symbol. only
	// cases like !set N=N+1 worked, because the force bit was
	// taken from result.
	// maybe support this behaviour via --dialect?
	if (loop->u.counter.force_bit)
		symbol_set_force_bit(loop->symbol, loop->u.counter.force_bit);
	loop_var = loop->symbol->object;	// update local copy with force bit
	loop->symbol->has_been_read = TRUE;	// lock force bit
	loop_var.u.number.val.intval = loop->u.counter.first;	// SEE ABOVE - this may be nonzero, but has not yet been copied to user symbol!
	while (loop->iterations_left) {
		loop->symbol->object = loop_var;	// overwrite whole struct, in case some joker has re-assigned loop counter var
		parse_ram_block(&loop->block);
		loop_var.u.number.val.intval += loop->u.counter.increment;
		loop->iterations_left--;
	}
	// new algo wants illegal value in loop counter after block:
	if (loop->algorithm == FORALGO_NEWCOUNT)
		loop->symbol->object = loop_var;	// overwrite whole struct, in case some joker has re-assigned loop counter var
}

// function for "!for" with iterating variable
static void iterating_for(struct for_loop *loop)
{
	intval_t	index	= 0;
	struct object	obj;

	while (loop->iterations_left) {
		loop->u.iter.obj.type->at(&loop->u.iter.obj, &obj, index++);
		symbol_set_object(loop->symbol, &obj, POWER_CHANGE_VALUE | POWER_CHANGE_OBJTYPE);
		parse_ram_block(&loop->block);
		loop->iterations_left--;
	}
}


// back end function for "!for" pseudo opcode
void flow_forloop(struct for_loop *loop)
{
	struct input	loop_input,
			*outer_input;

	// switching input makes us lose GotByte. But we know it's '}' anyway!
	// set up new input
	loop_input = *Input_now;	// copy current input structure into new
	loop_input.source = INPUTSRC_RAM;	// set new byte source
	// remember old input
	outer_input = Input_now;
	// activate new input
	// (not yet useable; pointer and line number are still missing)
	Input_now = &loop_input;
	// fix line number (not for block, but in case symbol handling throws errors)
	Input_now->line_number = loop->block.start;
	switch (loop->algorithm) {
	case FORALGO_OLDCOUNT:
	case FORALGO_NEWCOUNT:
		counting_for(loop);
		break;
	case FORALGO_ITERATE:
		iterating_for(loop);
		break;
	default:
		Bug_found("IllegalLoopAlgo", loop->algorithm);
	}
	// restore previous input:
	Input_now = outer_input;
}


// read condition, make copy, link to struct
static void copy_condition(struct condition *condition, char terminator)
{
	int	err;

	SKIPSPACE();
	DYNABUF_CLEAR(GlobalDynaBuf);
	while ((GotByte != terminator) && (GotByte != CHAR_EOS)) {
		// append to GlobalDynaBuf and check for quotes
		DYNABUF_APPEND(GlobalDynaBuf, GotByte);
		if ((GotByte == '"') || (GotByte == '\'')) {
			err = Input_quoted_to_dynabuf(GotByte);
			// here GotByte changes, it might become CHAR_EOS
			DYNABUF_APPEND(GlobalDynaBuf, GotByte);	// add closing quotes (or CHAR_EOS) as well
			if (err)
				break;	// on error, exit before eating CHAR_EOS via GetByte()
		}
		GetByte();
	}
	DynaBuf_append(GlobalDynaBuf, CHAR_EOS);	// ensure terminator
	condition->body = DynaBuf_get_copy(GlobalDynaBuf);
}

// try to read a condition into DynaBuf and store pointer to copy in
// given loop_condition structure.
// if no condition given, NULL is written to structure.
// call with GotByte = first interesting character
void flow_store_doloop_condition(struct condition *condition, char terminator)
{
	// write line number
	condition->line = Input_now->line_number;
	// set defaults
	condition->invert = FALSE;
	condition->body = NULL;
	// check for empty condition
	if (GotByte == terminator)
		return;

	// seems as if there really *is* a condition, so check for until/while
	if (Input_read_and_lower_keyword()) {
		if (strcmp(GlobalDynaBuf->buffer, "while") == 0) {
			//condition.invert = FALSE;
		} else if (strcmp(GlobalDynaBuf->buffer, "until") == 0) {
			condition->invert = TRUE;
		} else {
			Throw_error(exception_syntax);
			return;
		}
		// write given condition into buffer
		copy_condition(condition, terminator);
	}
}


// read a condition into DynaBuf and store pointer to copy in
// given loop_condition structure.
// call with GotByte = first interesting character
void flow_store_while_condition(struct condition *condition)
{
	condition->line = Input_now->line_number;
	condition->invert = FALSE;
	copy_condition(condition, CHAR_SOB);
}


// check a condition expression
static boolean check_condition(struct condition *condition)
{
	struct number	intresult;

	// first, check whether there actually *is* a condition
	if (condition->body == NULL)
		return TRUE;	// non-existing conditions are always true

	// set up input for expression evaluation
	Input_now->line_number = condition->line;
	Input_now->src.ram_ptr = condition->body;
	GetByte();	// proceed with next char
	ALU_defined_int(&intresult);
	if (GotByte)
		Throw_serious_error(exception_syntax);
	return condition->invert ? !intresult.val.intval : !!intresult.val.intval;
}


// back end function for "!do" and "!while" pseudo opcodes
void flow_do_while(struct do_while *loop)
{
	struct input	loop_input;
	struct input	*outer_input;

	// set up new input
	loop_input = *Input_now;	// copy current input structure into new
	loop_input.source = INPUTSRC_RAM;	// set new byte source
	// remember old input
	outer_input = Input_now;
	// activate new input (not useable yet, as pointer and
	// line number are not yet set up)
	Input_now = &loop_input;
	for (;;) {
		// check head condition
		if (!check_condition(&loop->head_cond))
			break;
		parse_ram_block(&loop->block);
		// check tail condition
		if (!check_condition(&loop->tail_cond))
			break;
	}
	// restore previous input:
	Input_now = outer_input;
	GotByte = CHAR_EOS;	// CAUTION! Very ugly kluge.
	// But by switching input, we lost the outer input's GotByte. We know
	// it was CHAR_EOS. We could just call GetByte() to get real input, but
	// then the main loop could choke on unexpected bytes. So we pretend
	// that we got the outer input's GotByte value magically back.
}


// parse a whole source code file
void flow_parse_and_close_file(FILE *fd, const char *filename)
{
	// be verbose
	if (config.process_verbosity > 2)
		printf("Parsing source file '%s'\n", filename);
	// set up new input
	Input_new_file(filename, fd);
	// Parse block and check end reason
	Parse_until_eob_or_eof();
	if (GotByte != CHAR_EOF)
		Throw_error("Found '}' instead of end-of-file.");
	// close sublevel src
	fclose(Input_now->src.fd);
}
