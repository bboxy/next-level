// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// mnemonic definitions
#ifndef mnemo_H
#define mnemo_H


#include "config.h"


// check whether mnemonic in GlobalDynaBuf is supported by standard 6502 cpu.
extern boolean keyword_is_6502_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by NMOS 6502 cpu (includes undocumented opcodes).
extern boolean keyword_is_nmos6502_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by C64DTV2 cpu.
extern boolean keyword_is_c64dtv2_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by 65C02 cpu.
extern boolean keyword_is_65c02_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by Rockwell 65C02 cpu.
extern boolean keyword_is_r65c02_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by WDC 65C02 cpu.
extern boolean keyword_is_w65c02_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by 65816 cpu.
extern boolean keyword_is_65816_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by CSG 65CE02 cpu.
extern boolean keyword_is_65ce02_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by CSG 4502 cpu.
extern boolean keyword_is_4502_mnemo(int length);
// check whether mnemonic in GlobalDynaBuf is supported by MEGA65 cpu.
extern boolean keyword_is_m65_mnemo(int length);


#endif
