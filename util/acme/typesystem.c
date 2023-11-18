// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// type system stuff
#include "typesystem.h"
#include "config.h"
#include "alu.h"
#include "global.h"


static boolean	in_address_block	= FALSE;
static boolean	in_address_statement	= FALSE;

// Functions

// return whether explicit symbol definitions should force "address" mode
boolean typesystem_says_address(void)
{
	return in_address_block || in_address_statement;
}

// parse a block while forcing address mode
void typesystem_force_address_block(void)
{
	boolean	buffer	= in_address_block;

	in_address_block = TRUE;
	Parse_optional_block();
	in_address_block = buffer;
}

// force address mode on or off for the next statement
void typesystem_force_address_statement(boolean value)
{
	in_address_statement = value;
}

// warn if result is not integer
void typesystem_want_nonaddr(struct number *result)
{
	if (!config.warn_on_type_mismatch)
		return;

	if (result->ntype == NUMTYPE_UNDEFINED)
		return;

	if (result->addr_refs != 0) {
		Throw_warning("Wrong type - expected integer.");
		//printf("refcount should be 0, but is %d\n", result->addr_refs);
	}
}
// warn if result is not address
void typesystem_want_addr(struct number *result)
{
	if (!config.warn_on_type_mismatch)
		return;

	if (result->ntype == NUMTYPE_UNDEFINED)
		return;

	if (result->addr_refs != 1) {
		Throw_warning("Wrong type - expected address.");
		//printf("refcount should be 1, but is %d\n", result->addr_refs);
	}
}
