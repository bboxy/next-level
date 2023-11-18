// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Output stuff (FIXME - split into outbuf, outfile/format and vcpu parts)
#ifndef output_H
#define output_H


#include <stdio.h>
#include "config.h"


// constants
#define MEMINIT_USE_DEFAULT	256
// segment flags
#define	SEGMENT_FLAG_OVERLAY	(1u << 0)	// do not warn about this segment overwriting another one
#define	SEGMENT_FLAG_INVISIBLE	(1u << 1)	// do not warn about other segments overwriting this one


// current CPU state
// FIXME - move vcpu struct definition to .c file and change other .c files' accesses to fn calls. then replace "struct number" with minimized version.
struct vcpu {
	const struct cpu_type	*type;		// current CPU type (default 6502)	(FIXME - move out of struct again?)
	struct number		pc;		// current program counter (pseudo value)
	int			add_to_pc;	// add to PC after statement
	boolean			a_is_long;
	boolean			xy_are_long;
};


// variables
extern struct vcpu	CPU_state;	// current CPU state	FIXME - restrict visibility to .c file


// Prototypes

// clear segment list and disable output
//TODO - does this belong to outbuf stuff?
extern void Output_passinit(void);

// outbuf stuff:

// alloc and init mem buffer (done later)
extern void Output_init(signed long fill_value, boolean use_large_buf);
// skip over some bytes in output buffer without starting a new segment
// (used by "!skip", and also called by "!binary" if really calling
// Output_byte would be a waste of time)
extern void output_skip(int size);
// Send low byte of arg to output buffer and advance pointer
// FIXME - replace by output_sequence(char *src, size_t size)
extern void (*Output_byte)(intval_t);
// define default value for empty memory ("!initmem" pseudo opcode)
// returns zero if ok, nonzero if already set
extern int output_initmem(char content);

// outfile stuff:

// try to set output format held in DynaBuf. Returns zero on success.
extern int outputfile_set_format(void);
extern const char	outputfile_formats[];	// string to show if outputfile_set_format() returns nonzero
// if file format was already chosen, returns zero.
// if file format isn't set, chooses CBM and returns 1.
extern int outputfile_prefer_cbm_format(void);
// try to set output file name held in DynaBuf. Returns zero on success.
extern int outputfile_set_filename(void);
// write smallest-possible part of memory buffer to file
extern void Output_save_file(FILE *fd);
// change output pointer and enable output
extern void Output_start_segment(intval_t address_change, bits segment_flags);
// Show start and end of current segment
extern void Output_end_segment(void);
extern char output_get_xor(void);
extern void output_set_xor(char xor);

// set program counter to defined value (TODO - allow undefined!)
extern void vcpu_set_pc(intval_t new_pc, bits flags);
// get program counter
extern void vcpu_read_pc(struct number *target);
// get size of current statement (until now) - needed for "!bin" verbose output
extern int vcpu_get_statement_size(void);
// adjust program counter (called at end of each statement)
extern void vcpu_end_statement(void);

struct pseudopc;
// start offset assembly
extern void pseudopc_start(struct number *new_pc);
// end offset assembly
extern void pseudopc_end(void);
// this is only for old, deprecated, obsolete, stupid "realpc":
extern void pseudopc_end_all(void);
// un-pseudopc a label value by given number of levels
// returns nonzero on error (if level too high)
extern int pseudopc_unpseudo(struct number *target, struct pseudopc *context, unsigned int levels);
// return pointer to current "pseudopc" struct (may be NULL!)
// this gets called when parsing label definitions
extern struct pseudopc *pseudopc_get_context(void);


#endif
