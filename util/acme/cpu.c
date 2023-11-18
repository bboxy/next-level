// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// CPU type stuff
#include "cpu.h"
#include "config.h"
#include "alu.h"
#include "dynabuf.h"
#include "global.h"
#include "input.h"
#include "mnemo.h"
#include "output.h"
#include "tree.h"


// constants
static struct cpu_type	cpu_type_6502	= {
	keyword_is_6502_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR | CPUFLAG_INDIRECTJMPBUGGY,	// warn about "XYZ ($ff),y" and "jmp ($XYff)"
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_nmos6502	= {
	keyword_is_nmos6502_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR | CPUFLAG_INDIRECTJMPBUGGY | CPUFLAG_8B_AND_AB_NEED_0_ARG,	// ANE/LXA #$xx are unstable unless arg is $00
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_c64dtv2	= {
	keyword_is_c64dtv2_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR | CPUFLAG_INDIRECTJMPBUGGY | CPUFLAG_8B_AND_AB_NEED_0_ARG,
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_65c02	= {
	keyword_is_65c02_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR,	// from WDC docs
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_r65c02	= {
	keyword_is_r65c02_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR,	// from WDC docs
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_w65c02	= {
	keyword_is_w65c02_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR,	// from WDC docs
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_65816	= {
	keyword_is_65816_mnemo,
	// TODO - what about CPUFLAG_WARN_ABOUT_FF_PTR? only needed for old opcodes in emulation mode!
	CPUFLAG_SUPPORTSLONGREGS,	// allows A and XY to be 16bits wide
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_65ce02	= {
	keyword_is_65ce02_mnemo,
	CPUFLAG_DECIMALSUBTRACTBUGGY,	// SBC does not work reliably in decimal mode
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_4502	= {
	keyword_is_4502_mnemo,
	CPUFLAG_DECIMALSUBTRACTBUGGY,	// SBC does not work reliably in decimal mode
	234	// !align fills with "NOP"
};
static struct cpu_type	cpu_type_m65	= {
	keyword_is_m65_mnemo,
	CPUFLAG_WARN_ABOUT_FF_PTR,	// TODO - remove this? check datasheets/realhw!
	234	// !align fills with "NOP"
};


// variables

// predefined stuff
static struct ronode	cputype_tree[]	= {
	PREDEF_START,
#define KNOWN_TYPES	"'6502', 'nmos6502', '6510', '65c02', 'r65c02', 'w65c02', '65816', '65ce02', '4502', 'm65', 'c64dtv2'"	// shown in CLI error message for unknown types
//	PREDEFNODE("z80",		&cpu_type_Z80),
	PREDEFNODE("6502",		&cpu_type_6502),
	PREDEFNODE("nmos6502",		&cpu_type_nmos6502),
	PREDEFNODE("6510",		&cpu_type_nmos6502),
	PREDEFNODE("65c02",		&cpu_type_65c02),
	PREDEFNODE("r65c02",		&cpu_type_r65c02),
	PREDEFNODE("w65c02",		&cpu_type_w65c02),
	PREDEFNODE("65816",		&cpu_type_65816),
	PREDEFNODE("65ce02",		&cpu_type_65ce02),
	PREDEFNODE("4502",		&cpu_type_4502),
	PREDEFNODE("m65",		&cpu_type_m65),
	PREDEF_END("c64dtv2",		&cpu_type_c64dtv2),
	//    ^^^^ this marks the last element
};
const char	cputype_names[]	= KNOWN_TYPES;	// string to show if cputype_find() returns NULL

// lookup cpu type held in DynaBuf and return its struct pointer (or NULL on failure)
const struct cpu_type *cputype_find(void)
{
	void	*node_body;

	// perform lookup
	if (!Tree_easy_scan(cputype_tree, &node_body, GlobalDynaBuf))
		return NULL;

	return node_body;
}


// if cpu type and value match, set register length variable to value.
// if cpu type and value don't match, complain instead.
// FIXME - error message might be confusing if it is thrown not because of
// initial change, but because of reverting back to old cpu type after "{}" block!
void vcpu_check_and_set_reg_length(boolean *var, boolean make_long)
{
	if (((CPU_state.type->flags & CPUFLAG_SUPPORTSLONGREGS) == 0) && make_long)
		Throw_error("Chosen CPU does not support long registers.");
	else
		*var = make_long;
}


// set default values for pass
void cputype_passinit(const struct cpu_type *cpu_type)
{
	// handle cpu type (default is 6502)
	CPU_state.type = cpu_type ? cpu_type : &cpu_type_6502;
	CPU_state.a_is_long = FALSE;	// short accu
	CPU_state.xy_are_long = FALSE;	// short index regs
}
