// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Dynamic buffer stuff
#include "dynabuf.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "acme.h"
#include "global.h"
#include "input.h"


// Constants and macros

// macro to grow dynabuf (CAUTION - fails if a < 1)
#define MAKE_LARGER_THAN(a)		(2 * (a))
// if someone requests a dynabuf smaller than this, use this size instead
#define DYNABUF_MINIMUM_INITIALSIZE	128	// should be >0 (see above)
// initial size for global dynabuf
// (as it holds macros, loop bodies, etc., make it large to begin with)
#define GLOBALDYNABUF_INITIALSIZE	1024	// should be >0 (see above)
// TODO - get rid of this, or move to global.c


// Variables
STRUCT_DYNABUF_REF(GlobalDynaBuf, GLOBALDYNABUF_INITIALSIZE);	// global dynamic buffer
// TODO - get rid of this, or move to global.c


// Functions

// get new buffer of given size
static void resize(struct dynabuf *db, size_t new_size)
{
	char	*new_buf;

	//printf("Growing dynabuf to size %d.\n", new_size);
	new_buf = realloc(db->buffer, new_size);
	if (new_buf == NULL)
		Throw_serious_error(exception_no_memory_left);
	db->reserved = new_size;
	db->buffer = new_buf;
}
// get buffer mem and fill in struct
static void initstruct(struct dynabuf *db, size_t initial_size)
{
	//printf("dynabuf-init: %d.\n", initial_size);
	if (initial_size < DYNABUF_MINIMUM_INITIALSIZE)
		initial_size = DYNABUF_MINIMUM_INITIALSIZE;
	db->size = 0;
	db->reserved = initial_size;
	db->buffer = malloc(initial_size);
	if (db->buffer == NULL) {
		// scream and die because there is not enough memory 
		fputs("Error: No memory for dynamic buffer.\n", stderr);
		exit(EXIT_FAILURE);
	}
}


// Exported functions

// (ensure buffer is ready to use, then) clear dynamic buffer
void dynabuf_clear(struct dynabuf *db)
{
	if (db->buffer == NULL)
		initstruct(db, db->reserved);	// get initial buffer
	db->size = 0;	// clear buffer
}

// Enlarge buffer
void dynabuf_enlarge(struct dynabuf *db)
{
	resize(db, MAKE_LARGER_THAN(db->reserved));
}

// Claim enough memory to hold a copy of the current buffer contents,
// make that copy and return it.
// The copy must be released by calling free().
char *DynaBuf_get_copy(struct dynabuf *db)
{
	char	*copy;

	copy = safe_malloc(db->size);
	memcpy(copy, db->buffer, db->size);
	return copy;
}

// add char to buffer
void DynaBuf_append(struct dynabuf *db, char byte)
{
	DYNABUF_APPEND(db, byte);
}

// Append string to buffer (without terminator)
void DynaBuf_add_string(struct dynabuf *db, const char *string)
{
	char	byte;

	while ((byte = *string++))
		DYNABUF_APPEND(db, byte);
}
/*
// make sure DynaBuf is large enough to take "size" more bytes
// return pointer to end of current contents
static char *ensure_free_space(struct dynabuf *db, int size)
{
	while ((db->reserved - db->size) < size)
		resize(db, MAKE_LARGER_THAN(db->reserved));
	return db->buffer + db->size;
}*/

// Convert buffer contents to lower case (target and source may be identical)
void DynaBuf_to_lower(struct dynabuf *target, struct dynabuf *source)
{
	char	*read,
		*write,
		byte;

	// if target has not been initialised yet, do it now
	// (do not clear it unconditionally, because it may equal source!)
	if (target->buffer == NULL)
		initstruct(target, target->reserved);	// get initial buffer

	// make sure target can take it
	if (source->size > target->reserved)
		resize(target, source->size);
	// convert to lower case
	read = source->buffer;	// CAUTION - ptr may change when buf grows!
	write = target->buffer;	// CAUTION - ptr may change when buf grows!
	while ((byte = *read++)) {
		// we want to keep underscore, so this check restricts:
		if (byte <= 'Z')
			byte |= 32;
		*write++ = byte;
	}
	// Okay, so this method of converting to lowercase is lousy.
	// But actually it doesn't matter, because only pre-defined
	// keywords are converted, and all of those are plain
	// old-fashioned 7-bit ASCII anyway. So I guess it'll do.
	// FIXME - use BYTE_ macro from global.h
	*write = '\0';	// terminate
}
