// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// Input stuff
// 19 Nov 2014	Merged Johann Klasek's report listing generator patch
//  9 Jan 2018	Allowed "//" comments
#include "input.h"
#include "config.h"
#include "alu.h"
#include "dynabuf.h"
#include "global.h"
#include "platform.h"
#include "section.h"
#include "symbol.h"
#include "tree.h"


// Constants
const char	FILE_READBINARY[]	= "rb";
#define CHAR_LF		(10)	// line feed		(in file)
		//	(10)	// start of line	(in high-level format)
#define CHAR_CR		(13)	// carriage return	(in file)
		//	(13)	// end of file		(in high-level format)
// if the characters above are changed, don't forget to adjust byte_flags[]!

// fake input structure (for error msgs before any real input is established)
static struct input	outermost	= {
	"<none>",	// file name
	0,		// line number
	INPUTSRC_FILE,	// fake file access, so no RAM read
	INPUTSTATE_EOF,	// state of input
	{
		NULL	// RAM read pointer or file handle
	}
};


// variables
struct input	*Input_now	= &outermost;	// current input structure


// functions

// let current input point to start of file
void Input_new_file(const char *filename, FILE *fd)
{
	Input_now->original_filename	= filename;
	Input_now->line_number		= 1;
	Input_now->source		= INPUTSRC_FILE;
	Input_now->state		= INPUTSTATE_SOF;
	Input_now->src.fd		= fd;
}


// remember source code character for report generator
#define HEXBUFSIZE	9	// actually, 4+1 is enough, but for systems without snprintf(), let's be extra-safe.
#define IF_WANTED_REPORT_SRCCHAR(c)	do { if (report->fd) report_srcchar(c); } while(0)
static void report_srcchar(char new_char)
{
	static char	prev_char	= '\0';
	int		ii;
	char		hex_address[HEXBUFSIZE];
	char		hexdump[2 * REPORT_BINBUFSIZE + 2];	// +2 for '.' and terminator

	// if input has changed, insert explanation
	if (Input_now != report->last_input) {
		fprintf(report->fd, "\n; ******** Source: %s\n", Input_now->original_filename);
		report->last_input = Input_now;
		report->asc_used = 0;	// clear buffer
		prev_char = '\0';
	}
	if (prev_char == '\n') {
		// line start after line break detected and EOS processed,
		// build report line:
		// show line number...
		fprintf(report->fd, "%6d  ", Input_now->line_number - 1);
		// prepare outbytes' start address
		if (report->bin_used) {
#if _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
			snprintf(hex_address, HEXBUFSIZE, "%04x", report->bin_address);
#else
			sprintf(hex_address, "%04x", report->bin_address);
#endif
		} else {
			hex_address[0] = '\0';
		}
		// prepare outbytes
		hexdump[0] = '\0';
		for (ii = 0; ii < report->bin_used; ++ii)
			sprintf(hexdump + 2 * ii, "%02x", (unsigned int) (unsigned char) (report->bin_buf[ii]));
		// if binary buffer is full, overwrite last byte with "..."
		if (report->bin_used == REPORT_BINBUFSIZE)
			sprintf(hexdump + 2 * (REPORT_BINBUFSIZE - 1), "...");
		// show address and bytes
		fprintf(report->fd, "%-4s %-19s", hex_address, hexdump);
		// at this point the output should be a multiple of 8 characters
		// so far to preserve tabs of the source...
		if (report->asc_used == REPORT_ASCBUFSIZE)
			--report->asc_used;
		report->asc_buf[report->asc_used] = '\0';
		fprintf(report->fd, "%s\n", report->asc_buf);	// show source line
		report->asc_used = 0;	// reset buffers
		report->bin_used = 0;
	}
	if (new_char != '\n' && new_char != '\r') {	// detect line break
		if (report->asc_used < REPORT_ASCBUFSIZE)
			report->asc_buf[report->asc_used++] = new_char;
	}
	prev_char = new_char;
}


// Deliver source code from current file (!) in shortened high-level format
static char get_processed_from_file(void)
{
	static int	from_file	= 0;

	for (;;) {
		switch (Input_now->state) {
		case INPUTSTATE_SOF:
			// fetch first byte from the current source file
			from_file = getc(Input_now->src.fd);
			IF_WANTED_REPORT_SRCCHAR(from_file);
			//TODO - check for bogus/malformed BOM and ignore?
			// check for hashbang line and ignore
			if (from_file == '#') {
				// remember to skip remainder of line
				Input_now->state = INPUTSTATE_COMMENT;
				return CHAR_EOS;	// end of statement
			}
			Input_now->state = INPUTSTATE_AGAIN;
			break;
		case INPUTSTATE_NORMAL:
			// fetch a fresh byte from the current source file
			from_file = getc(Input_now->src.fd);
			IF_WANTED_REPORT_SRCCHAR(from_file);
			// now process it
			/*FALLTHROUGH*/
		case INPUTSTATE_AGAIN:
			// Process the latest byte again. Of course, this only
			// makes sense if the loop has executed at least once,
			// otherwise the contents of from_file are undefined.
			// If the source is changed so there is a possibility
			// to enter INPUTSTATE_AGAIN mode without first having
			// defined "from_file", trouble may arise...
			Input_now->state = INPUTSTATE_NORMAL;
			// EOF must be checked first because it cannot be used
			// as an index into global_byte_flags[]
			if (from_file == EOF) {
				// remember to send an end-of-file
				Input_now->state = INPUTSTATE_EOF;
				return CHAR_EOS;	// end of statement
			}

			// check whether character is special one
			// if not, everything's cool and froody, so return it
			if (BYTE_IS_SYNTAX_CHAR(from_file) == 0)
				return (char) from_file;

			// check special characters ("0x00 TAB LF CR SPC / : ; }")
			switch (from_file) {
			case '\t':
			case ' ':
				// remember to skip all following blanks
				Input_now->state = INPUTSTATE_SKIPBLANKS;
				return ' ';

			case CHAR_LF:	// LF character
				// remember to send a start-of-line
				Input_now->state = INPUTSTATE_LF;
				return CHAR_EOS;	// end of statement

			case CHAR_CR:	// CR character
				// remember to check CRLF + send start-of-line
				Input_now->state = INPUTSTATE_CR;
				return CHAR_EOS;	// end of statement

			case CHAR_EOB:
				// remember to send an end-of-block
				Input_now->state = INPUTSTATE_EOB;
				return CHAR_EOS;	// end of statement

			case '/':
				// to check for "//", get another byte:
				from_file = getc(Input_now->src.fd);
				IF_WANTED_REPORT_SRCCHAR(from_file);
				if (from_file != '/') {
					// not "//", so:
					Input_now->state = INPUTSTATE_AGAIN;	// second byte must be parsed normally later on
					return '/';	// first byte is returned normally right now
				}
				// it's really "//", so act as if ';'
				/*FALLTHROUGH*/
			case ';':
				// remember to skip remainder of line
				Input_now->state = INPUTSTATE_COMMENT;
				return CHAR_EOS;	// end of statement

			case ':':	// statement delimiter
				// just deliver an EOS instead
				return CHAR_EOS;	// end of statement

			default:
				// complain if byte is 0
				Throw_error("Source file contains illegal character.");
				return (char) from_file;
			}
		case INPUTSTATE_SKIPBLANKS:
			// read until non-blank, then deliver that
			do {
				from_file = getc(Input_now->src.fd);
				IF_WANTED_REPORT_SRCCHAR(from_file);
			} while ((from_file == '\t') || (from_file == ' '));
			// re-process last byte
			Input_now->state = INPUTSTATE_AGAIN;
			break;
		case INPUTSTATE_LF:
			// return start-of-line, then continue in normal mode
			Input_now->state = INPUTSTATE_NORMAL;
			return CHAR_SOL;	// new line

		case INPUTSTATE_CR:
			// return start-of-line, remember to check for LF
			Input_now->state = INPUTSTATE_SKIPLF;
			return CHAR_SOL;	// new line

		case INPUTSTATE_SKIPLF:
			from_file = getc(Input_now->src.fd);
			IF_WANTED_REPORT_SRCCHAR(from_file);
			// if LF, ignore it and fetch another byte
			// otherwise, process current byte
			if (from_file == CHAR_LF)
				Input_now->state = INPUTSTATE_NORMAL;
			else
				Input_now->state = INPUTSTATE_AGAIN;
			break;
		case INPUTSTATE_COMMENT:
			// read until end-of-line or end-of-file
			do {
				from_file = getc(Input_now->src.fd);
				IF_WANTED_REPORT_SRCCHAR(from_file);
			} while ((from_file != EOF) && (from_file != CHAR_CR) && (from_file != CHAR_LF));
			// re-process last byte
			Input_now->state = INPUTSTATE_AGAIN;
			break;
		case INPUTSTATE_EOB:
			// deliver EOB
			Input_now->state = INPUTSTATE_NORMAL;
			return CHAR_EOB;	// end of block

		case INPUTSTATE_EOF:
			// deliver EOF
			Input_now->state = INPUTSTATE_NORMAL;
			return CHAR_EOF;	// end of file

		default:
			Bug_found("StrangeInputMode", Input_now->state);
		}
	}
}

// This function delivers the next byte from the currently active byte source
// in shortened high-level format. FIXME - use fn ptr?
// When inside quotes, use Input_quoted_to_dynabuf() instead!
char GetByte(void)
{
//	for (;;) {
		// If byte source is RAM, then no conversions are
		// necessary, because in RAM the source already has
		// high-level format
		// Otherwise, the source is a file. This means we will call
		// get_processed_from_file() which will do a shit load of conversions.
		switch (Input_now->source) {
		case INPUTSRC_RAM:
			GotByte = *(Input_now->src.ram_ptr++);
			break;
		case INPUTSRC_FILE:
			GotByte = get_processed_from_file();
			break;
		default:
			Bug_found("IllegalInputSrc", Input_now->source);
		}
//		// if start-of-line was read, increment line counter and repeat
//		if (GotByte != CHAR_SOL)
//			return GotByte;
//		Input_now->line_number++;
//	}
		if (GotByte == CHAR_SOL)
			Input_now->line_number++;
		return GotByte;
}

// This function delivers the next byte from the currently active byte source
// in un-shortened high-level format.
// This function complains if CHAR_EOS (end of statement) is read.
// TODO - check if return value is actually used
static char GetQuotedByte(void)
{
	int	from_file;	// must be an int to catch EOF

	switch (Input_now->source) {
	case INPUTSRC_RAM:
		// if byte source is RAM, then no conversion is necessary,
		// because in RAM the source already has high-level format
		GotByte = *(Input_now->src.ram_ptr++);
		break;
	case INPUTSRC_FILE:
		// fetch a fresh byte from the current source file
		from_file = getc(Input_now->src.fd);
		IF_WANTED_REPORT_SRCCHAR(from_file);
		switch (from_file) {
		case EOF:
			// remember to send an end-of-file
			Input_now->state = INPUTSTATE_EOF;
			GotByte = CHAR_EOS;	// end of statement
			break;
		case CHAR_LF:	// LF character
			// remember to send a start-of-line
			Input_now->state = INPUTSTATE_LF;
			GotByte = CHAR_EOS;	// end of statement
			break;
		case CHAR_CR:	// CR character
			// remember to check for CRLF + send a start-of-line
			Input_now->state = INPUTSTATE_CR;
			GotByte = CHAR_EOS;	// end of statement
			break;
		default:
			GotByte = from_file;
		}
		break;
	default:
		Bug_found("IllegalInputSrc", Input_now->source);
	}
	// now check for end of statement
	if (GotByte == CHAR_EOS)
		Throw_error("Quotes still open at end of line.");
	return GotByte;
}

// Skip remainder of statement, for example on error
// FIXME - check for quotes, otherwise this might treat a quoted colon like EOS!
void Input_skip_remainder(void)
{
	while (GotByte)
		GetByte();	// Read characters until end-of-statement
}

// Ensure that the remainder of the current statement is empty, for example
// after mnemonics using implied addressing.
void Input_ensure_EOS(void)	// Now GotByte = first char to test
{
	SKIPSPACE();
	if (GotByte) {
		char	buf[80];	// actually needed are 51
		char	quote;		// character before and after

		quote = (GotByte == '\'') ? '"' : '\'';	// use single quotes, unless byte is a single quote (then use double quotes)
		sprintf(buf, "Garbage data at end of statement (unexpected %c%c%c).", quote, GotByte, quote);
		Throw_error(buf);
		Input_skip_remainder();
	}
}

// read string to dynabuf until closing quote is found
// returns 1 on errors (unterminated, escaping error)
int Input_quoted_to_dynabuf(char closing_quote)
{
	boolean	escaped	= FALSE;

	//DYNABUF_CLEAR(GlobalDynaBuf);	// do not clear, caller might want to append to existing contents (TODO - check!)
	for (;;) {
		GetQuotedByte();
		if (GotByte == CHAR_EOS)
			return 1;	// unterminated string constant; GetQuotedByte will have complained already

		if (escaped) {
			// previous byte was backslash, so do not check for terminator nor backslash
			escaped = FALSE;
			// do not actually _convert_ escape sequences to their target byte, that is done by Input_unescape_dynabuf() below!
			// TODO - but maybe check for illegal escape sequences?
			// at the moment checking is only done when the string
			// gets used for something...
		} else {
			// non-escaped: only terminator and backslash are of interest
			if (GotByte == closing_quote)
				return 0;	// ok

			if ((GotByte == '\\') && (config.wanted_version >= VER_BACKSLASHESCAPING))
				escaped = TRUE;
		}
		DYNABUF_APPEND(GlobalDynaBuf, GotByte);
	}
}

// process backslash escapes in GlobalDynaBuf (so size might shrink)
// returns 1 on errors (escaping errors)
// TODO - check: if this is only ever called directly after Input_quoted_to_dynabuf, integrate that call here?
int Input_unescape_dynabuf(int read_index)
{
	int	write_index;
	char	byte;
	boolean	escaped;

	if (config.wanted_version < VER_BACKSLASHESCAPING)
		return 0;	// ok

	write_index = read_index;
	escaped = FALSE;
	// CAUTION - contents of dynabuf are not terminated:
	while (read_index < GlobalDynaBuf->size) {
		byte = GLOBALDYNABUF_CURRENT[read_index++];
		if (escaped) {
			switch (byte) {
			case '\\':
			case '\'':
			case '"':
				break;
			case '0':	// NUL
				byte = 0;
				break;
			case 't':	// TAB
				byte = 9;
				break;
			case 'n':	// LF
				byte = 10;
				break;
			case 'r':	// CR
				byte = 13;
				break;
			// TODO - 'a' to BEL? others?
			default:
				Throw_error("Unsupported backslash sequence.");	// TODO - add unexpected character to error message?
			}
			GLOBALDYNABUF_CURRENT[write_index++] = byte;
			escaped = FALSE;
		} else {
			if (byte == '\\') {
				escaped = TRUE;
			} else {
				GLOBALDYNABUF_CURRENT[write_index++] = byte;
			}
		}
	}
	if (escaped)
		Bug_found("PartialEscapeSequence", 0);
	GlobalDynaBuf->size = write_index;
	return 0;	// ok
}

// Skip or store block (starting with next byte, so call directly after
// reading opening brace).
// the block is read into GlobalDynaBuf.
// If "Store" is TRUE, then a copy is made and a pointer to that is returned.
// If "Store" is FALSE, NULL is returned.
// After calling this function, GotByte holds '}'. Unless EOF was found first,
// but then a serious error would have been thrown.
// FIXME - use a struct block *ptr argument!
char *Input_skip_or_store_block(boolean store)
{
	char	byte;
	int	depth	= 1;	// to find matching block end

	// prepare global dynamic buffer
	DYNABUF_CLEAR(GlobalDynaBuf);
	do {
		byte = GetByte();
		// store
		DYNABUF_APPEND(GlobalDynaBuf, byte);
		// now check for some special characters
		switch (byte) {
		case CHAR_EOF:	// End-of-file in block? Sorry, no way.
			Throw_serious_error(exception_no_right_brace);

		case '"':	// Quotes? Okay, read quoted stuff.
		case '\'':
			Input_quoted_to_dynabuf(byte);
			DYNABUF_APPEND(GlobalDynaBuf, GotByte);	// add closing quote
			break;
		case CHAR_SOB:
			++depth;
			break;
		case CHAR_EOB:
			--depth;
			break;
		}
	} while (depth);
	// in case of skip, return now
	if (!store)
		return NULL;

	// otherwise, prepare to return copy of block
	// add EOF, just to make sure block is never read too far
	DynaBuf_append(GlobalDynaBuf, CHAR_EOS);
	DynaBuf_append(GlobalDynaBuf, CHAR_EOF);
	// return pointer to copy
	return DynaBuf_get_copy(GlobalDynaBuf);
}

// Append to GlobalDynaBuf while characters are legal for keywords.
// Throws "missing string" error if none.
// Returns number of characters added.
int Input_append_keyword_to_global_dynabuf(void)
{
	int	length	= 0;

	// add characters to buffer until an illegal one comes along
	while (BYTE_CONTINUES_KEYWORD(GotByte)) {
		DYNABUF_APPEND(GlobalDynaBuf, GotByte);
		++length;
		GetByte();
	}
	if (length == 0)
		Throw_error(exception_missing_string);
	return length;
}

// Check GotByte.
// If LOCAL_PREFIX ('.'), store current local scope value and read next byte.
// If CHEAP_PREFIX ('@'), store current cheap scope value and read next byte.
// Otherwise, store global scope value.
// Then jump to Input_read_keyword(), which returns length of keyword.
int Input_read_scope_and_keyword(scope_t *scope)
{
	SKIPSPACE();
	if (GotByte == LOCAL_PREFIX) {
		GetByte();
		*scope = section_now->local_scope;
	} else if (GotByte == CHEAP_PREFIX) {
		GetByte();
		*scope = section_now->cheap_scope;
	} else {
		*scope = SCOPE_GLOBAL;
	}
	return Input_read_keyword();
}

// Clear dynamic buffer, then append to it until an illegal (for a keyword)
// character is read. Zero-terminate the string. Return its length (without
// terminator).
// Zero lengths will produce a "missing string" error.
int Input_read_keyword(void)
{
	int	length;

	DYNABUF_CLEAR(GlobalDynaBuf);
	length = Input_append_keyword_to_global_dynabuf();
	// add terminator to buffer (increments buffer's length counter)
	DynaBuf_append(GlobalDynaBuf, '\0');
	return length;
}

// Clear dynamic buffer, then append to it until an illegal (for a keyword)
// character is read. Zero-terminate the string, then convert to lower case.
// Return its length (without terminator).
// Zero lengths will produce a "missing string" error.
int Input_read_and_lower_keyword(void)
{
	int	length;

	DYNABUF_CLEAR(GlobalDynaBuf);
	length = Input_append_keyword_to_global_dynabuf();
	// add terminator to buffer (increments buffer's length counter)
	DynaBuf_append(GlobalDynaBuf, '\0');
	DynaBuf_to_lower(GlobalDynaBuf, GlobalDynaBuf);	// convert to lower case
	return length;
}

// Try to read a file name.
// If "allow_library" is TRUE, library access by using <...> quoting
// is possible as well. If "uses_lib" is non-NULL, info about library
// usage is stored there.
// The file name given in the assembler source code is converted from
// UNIX style to platform style.
// Returns nonzero on error. Filename in GlobalDynaBuf.
// Errors are handled and reported, but caller should call
// Input_skip_remainder() then.
int Input_read_filename(boolean allow_library, boolean *uses_lib)
{
	int	start_of_string;
	char	*lib_prefix,
		terminator;

	DYNABUF_CLEAR(GlobalDynaBuf);
	SKIPSPACE();
	switch (GotByte) {
	case '<':	// library access
		if (uses_lib)
			*uses_lib = TRUE;
		// if library access forbidden, complain
		if (!allow_library) {
			Throw_error("Writing to library not supported.");
			return 1;	// error
		}

		// read platform's lib prefix
		lib_prefix = PLATFORM_LIBPREFIX;
#ifndef NO_NEED_FOR_ENV_VAR
		// if lib prefix not set, complain
		if (lib_prefix == NULL) {
			Throw_error("\"ACME\" environment variable not found.");
			return 1;	// error
		}
#endif
		// copy lib path and set quoting char
		DynaBuf_add_string(GlobalDynaBuf, lib_prefix);
		terminator = '>';
		break;
	case '"':	// normal access
		if (uses_lib)
			*uses_lib = FALSE;
		terminator = '"';
		break;
	default:	// none of the above
		Throw_error("File name quotes not found (\"\" or <>).");
		return 1;	// error
	}
	// remember border between optional library prefix and string from assembler source file
	start_of_string = GlobalDynaBuf->size;
	// read file name string
	if (Input_quoted_to_dynabuf(terminator))
		return 1;	// unterminated or escaping error

	GetByte();	// eat terminator
	// check length
	if (GlobalDynaBuf->size == start_of_string) {
		Throw_error("No file name given.");
		return 1;	// error
	}

	// resolve backslash escapes
	if (Input_unescape_dynabuf(start_of_string))
		return 1;	// escaping error

	// terminate string
	DynaBuf_append(GlobalDynaBuf, '\0');
#ifdef PLATFORM_CONVERTPATH
	// platform-specific path name conversion
	PLATFORM_CONVERTPATH(GLOBALDYNABUF_CURRENT + start_of_string);
#endif
	return 0;	// ok
}

// Try to read a comma, skipping spaces before and after. Return TRUE if comma
// found, otherwise FALSE.
int Input_accept_comma(void)
{
	SKIPSPACE();
	if (GotByte != ',')
		return FALSE;

	NEXTANDSKIPSPACE();
	return TRUE;
}

// read optional info about parameter length
// FIXME - move to different file!
bits Input_get_force_bit(void)
{
	char	byte;
	bits	force_bit	= 0;

	if (GotByte == '+') {
		byte = GetByte();
		if (byte == '1')
			force_bit = NUMBER_FORCES_8;
		else if (byte == '2')
			force_bit = NUMBER_FORCES_16;
		else if (byte == '3')
			force_bit = NUMBER_FORCES_24;
		if (force_bit)
			GetByte();
		else
			Throw_error("Illegal postfix.");
	}
	SKIPSPACE();
	return force_bit;
}


// include path stuff - should be moved to its own file:

// ring list struct
struct ipi {
	struct ipi	*next,
			*prev;
	const char	*path;
};
static struct ipi	ipi_head	= {&ipi_head, &ipi_head, NULL};	// head element
static	STRUCT_DYNABUF_REF(pathbuf, 256);	// to combine search path and file spec

// add entry
void includepaths_add(const char *path)
{
	struct ipi	*ipi;

	ipi = safe_malloc(sizeof(*ipi));
	ipi->path = path;
	ipi->next = &ipi_head;
	ipi->prev = ipi_head.prev;
	ipi->next->prev = ipi;
	ipi->prev->next = ipi;
}
// open file for reading (trying list entries as prefixes)
// "uses_lib" tells whether to access library or to make use of include paths
// file name is expected in GlobalDynaBuf
FILE *includepaths_open_ro(boolean uses_lib)
{
	FILE		*stream;
	struct ipi	*ipi;

	// first try directly, regardless of whether lib or not:
	stream = fopen(GLOBALDYNABUF_CURRENT, FILE_READBINARY);
	// if failed and not lib, try include paths:
	if ((stream == NULL) && !uses_lib) {
		for (ipi = ipi_head.next; ipi != &ipi_head; ipi = ipi->next) {
			DYNABUF_CLEAR(pathbuf);
			// add first part
			DynaBuf_add_string(pathbuf, ipi->path);
			// if wanted and possible, ensure last char is directory separator
			if (DIRECTORY_SEPARATOR
			&& pathbuf->size
			&& (pathbuf->buffer[pathbuf->size - 1] != DIRECTORY_SEPARATOR))
				DynaBuf_append(pathbuf, DIRECTORY_SEPARATOR);
			// add second part
			DynaBuf_add_string(pathbuf, GLOBALDYNABUF_CURRENT);
			// terminate
			DynaBuf_append(pathbuf, '\0');
			// try
			stream = fopen(pathbuf->buffer, FILE_READBINARY);
			//printf("trying <<%s>> - ", pathbuf->buffer);
			if (stream) {
				//printf("ok\n");
				break;
			} else {
				//printf("failed\n");
			}
		}
	}
	if (stream == NULL) {
		// CAUTION, I'm re-using the path dynabuf to assemble the error message:
		DYNABUF_CLEAR(pathbuf);
		DynaBuf_add_string(pathbuf, "Cannot open input file \"");
		DynaBuf_add_string(pathbuf, GLOBALDYNABUF_CURRENT);
		DynaBuf_add_string(pathbuf, "\".");
		DynaBuf_append(pathbuf, '\0');
		Throw_error(pathbuf->buffer);
	}
	//fprintf(stderr, "File is [%s]\n", GLOBALDYNABUF_CURRENT);
	return stream;
}
