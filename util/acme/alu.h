// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// ALU stuff (the expression parser)
#ifndef alu_H
#define alu_H


#include "config.h"


struct op;
struct dynabuf;
struct type {
	const char	*name;
	boolean		(*is_defined)(const struct object *self);
	boolean		(*differs)(const struct object *self, const struct object *other);
	void		(*assign)(struct object *self, const struct object *new_value, boolean accept_change);
	void		(*monadic_op)(struct object *self, const struct op *op);
	void		(*dyadic_op)(struct object *self, const struct op *op, struct object *other);
	void		(*fix_result)(struct object *self);
	void		(*print)(const struct object *self, struct dynabuf *db);
	int		(*length)(const struct object *self);	// returns -1 if not iterable
	void		(*at)(const struct object *self, struct object *target, int index);
};
extern struct type	type_number;
extern struct type	type_list;
extern struct type	type_string;

struct expression {
	struct object	result;
	boolean		is_empty;		// nothing parsed (first character was a delimiter)
	int		open_parentheses;	// number of parentheses still open
	boolean		is_parenthesized;	// whole expression was in parentheses (indicating indirect addressing)
	// TODO - how to return reserved cpu constant (register names)?
};


// constants

// flag bits in number struct:
#define NO_FORCE_BIT		0		// (just to make source more readable)
#define NUMBER_FORCES_8		(1u << 0)	// value usage forces 8-bit usage
#define NUMBER_FORCES_16	(1u << 1)	// value usage forces 16-bit usage
#define NUMBER_FORCES_24	(1u << 2)	// value usage forces 24-bit usage
#define NUMBER_FORCEBITS	(NUMBER_FORCES_8 | NUMBER_FORCES_16 | NUMBER_FORCES_24)
#define NUMBER_FITS_BYTE	(1u << 3)	// value is guaranteed to fit in one byte
#define NUMBER_EVER_UNDEFINED	(1u << 4)	// value once was related to
	// undefined expression. Needed for producing the same addresses in all
	// passes; because in the first pass there will almost for sure be
	// labels that are undefined, we can't simply get the addressing mode
	// from looking at the parameter's value.	FIXME - rename to TAINTED :)

/*
// FIXME - replace all the functions below with a single one using a "flags" arg!
// its return value would then be "error"/"ok".
// input flags:
#define ACCEPT_UNDEFINED	(1u << 0)	// if not given, undefined throws serious error
#define ACCEPT_INT		(1u << 1)
#define ACCEPT_FLOAT		(1u << 2)	// if not given, floats are converted to integer
#define ACCEPT_OPENPARENTHESIS	(1u << 3)	// if not given, throws syntax error
#define ACCEPT_STRING		(1u << 4)	// if not given, convert 1-char strings to int?
#define ACCEPT_LIST		(1u << 5)
// do I need ACCEPT_NONADDR and/or ACCEPT_ADDRESS?
*/

// stores int value (0 if result was undefined)
extern void ALU_any_int(intval_t *target);
// stores int value and flags (floats are transformed to int)
// if result was undefined, serious error is thrown
extern void ALU_defined_int(struct number *intresult);
// stores int value and flags, allowing for "paren" '(' too many (x-indirect addr).
extern void ALU_addrmode_int(struct expression *expression, int paren);
// stores resulting object
extern void ALU_any_result(struct object *result);


#endif
