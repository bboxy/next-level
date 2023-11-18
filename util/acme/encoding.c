// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Character encoding stuff
#include "encoding.h"
#include <stdio.h>
#include <string.h>
#include "alu.h"
#include "acme.h"
#include "dynabuf.h"
#include "global.h"
#include "output.h"
#include "input.h"
#include "tree.h"


// struct definition
struct encoder {
	unsigned char	(*fn)(unsigned char);
	// maybe add table pointer?
};


// variables
static unsigned char	outermost_table[256];	// space for encoding table...
const struct encoder	*encoder_current;	// gets set before each pass
unsigned char		*encoding_loaded_table	= outermost_table;	// ...loaded from file


// encoder functions:


// convert raw to raw (do not convert at all)
static unsigned char encoderfn_raw(unsigned char byte)
{
	return byte;
}
// convert raw to petscii
static unsigned char encoderfn_pet(unsigned char byte)
{
	if ((byte >= (unsigned char) 'A') && (byte <= (unsigned char) 'Z'))
		return byte | 0x80;
	if ((byte >= (unsigned char) 'a') && (byte <= (unsigned char) 'z'))
		return byte - 32;
	return byte;
}
// convert raw to C64 screencode
static unsigned char encoderfn_scr(unsigned char byte)
{
	if ((byte >= (unsigned char) 'a') && (byte <= (unsigned char) 'z'))
		return byte - 96;	// shift uppercase down
	if ((byte >= (unsigned char) '[') && (byte <= (unsigned char) '_'))
		return byte - 64;	// shift [\]^_ down
	if (byte == '`')
		return 64;	// shift ` down
	if (byte == '@')
		return 0;	// shift @ down
	return byte;
}
// convert raw to whatever is defined in table
static unsigned char encoderfn_file(unsigned char byte)
{
	return encoding_loaded_table[byte];
}


// predefined encoder structs:


const struct encoder	encoder_raw	= {
	encoderfn_raw
};
const struct encoder	encoder_pet	= {
	encoderfn_pet
};
const struct encoder	encoder_scr	= {
	encoderfn_scr
};
const struct encoder	encoder_file	= {
	encoderfn_file
};


// keywords for "!convtab" pseudo opcode
static struct ronode	encoder_tree[]	= {
	PREDEF_START,
//no!	PREDEFNODE("file",	&encoder_file),	"!ct file" is not needed; just use {} after initial loading of table!
	PREDEFNODE("pet",	&encoder_pet),
	PREDEFNODE("raw",	&encoder_raw),
	PREDEF_END("scr",	&encoder_scr),
	//    ^^^^ this marks the last element
};


// exported functions


// convert character using current encoding (exported for use by alu.c and pseudoopcodes.c)
unsigned char encoding_encode_char(unsigned char byte)
{
	return encoder_current->fn(byte);
}

// set "raw" as default encoding
void encoding_passinit(void)
{
	encoder_current = &encoder_raw;
}

// try to load encoding table from given file
void encoding_load_from_file(unsigned char target[256], FILE *stream)
{
	if (fread(target, sizeof(char), 256, stream) != 256)
		Throw_error("Conversion table incomplete.");
}

// lookup encoder held in DynaBuf and return its struct pointer (or NULL on failure)
const struct encoder *encoding_find(void)
{
	void	*node_body;

	// perform lookup
	if (!Tree_easy_scan(encoder_tree, &node_body, GlobalDynaBuf)) {
		Throw_error("Unknown encoding.");
		return NULL;
	}

	return node_body;
}
