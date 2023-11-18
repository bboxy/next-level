// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// symbol stuff
#ifndef symbol_H
#define symbol_H


#include <stdio.h>
#include "config.h"


struct symbol {
	struct object	object;	// number/list/string
	int		pass;	// pass of creation (for anon counters)
	boolean		has_been_read;	// to find out if actually used
	boolean		has_been_reported;	// indicates "has been reported as undefined"
	struct pseudopc	*pseudopc;	// NULL when defined outside of !pseudopc block
	// add file ref + line num of last definition
};


// Constants
#define SCOPE_GLOBAL	0	// number of "global zone"


// variables
extern struct rwnode	*symbols_forest[];	// trees (because of 8-bit hash)


// search for symbol. if it does not exist, create with NULL type object (CAUTION!).
// the symbol name must be held in GlobalDynaBuf.
extern struct symbol *symbol_find(scope_t scope);
// assign object to symbol. function acts upon the symbol's flag bits and
// produces an error if needed.
// using "power" bits, caller can state which changes are ok.
#define POWER_NONE		0
#define POWER_CHANGE_VALUE	(1u << 0)	// e.g. change 3 to 5 or 2.71
#define POWER_CHANGE_OBJTYPE	(1u << 1)	// e.g. change 3 to "somestring"
extern void symbol_set_object(struct symbol *symbol, struct object *new_obj, bits powers);
// set force bit of symbol. trying to change to a different one will raise error.
extern void symbol_set_force_bit(struct symbol *symbol, bits force_bit);
// set global symbol to value, no questions asked (for "-D" switch)
// name must be held in GlobalDynaBuf.
extern void symbol_define(intval_t value);
// dump global symbols to file
extern void symbols_list(FILE *fd);
// dump global labels to file in VICE format
extern void symbols_vicelabels(FILE *fd);
// fix name of anonymous forward label (held in GlobalDynaBuf, NOT TERMINATED!)
// so it references the *next* anonymous forward label definition.
extern void symbol_fix_forward_anon_name(boolean increment);


#endif
