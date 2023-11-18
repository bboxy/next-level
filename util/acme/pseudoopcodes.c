// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2020 Marco Baye
// Have a look at "acme.c" for further info
//
// pseudo opcode stuff
#include "pseudoopcodes.h"
#include <stdlib.h>
#include <stdio.h>
#include "acme.h"
#include "config.h"
#include "cpu.h"
#include "alu.h"
#include "dynabuf.h"
#include "encoding.h"
#include "flow.h"
#include "input.h"
#include "macro.h"
#include "global.h"
#include "output.h"
#include "section.h"
#include "symbol.h"
#include "tree.h"
#include "typesystem.h"


// different ways to handle end-of-statement:
enum eos {
	SKIP_REMAINDER,		// skip remainder of line - (after errors)
	ENSURE_EOS,		// make sure there's nothing left in statement
	PARSE_REMAINDER,	// parse what's left
	AT_EOS_ANYWAY		// actually, same as PARSE_REMAINDER
};

// constants
static const char	exception_unknown_pseudo_opcode[]	= "Unknown pseudo opcode.";


// this is not really a pseudo opcode, but similar enough to be put here:
// called when "*= EXPRESSION" is parsed, to set the program counter
void notreallypo_setpc(void)	// GotByte is '*'
{
	bits		segment_flags	= 0;
	struct number	intresult;

	// next non-space must be '='
	NEXTANDSKIPSPACE();
	if (GotByte != '=') {
		Throw_error(exception_syntax);
		goto fail;
	}

	GetByte();
	ALU_defined_int(&intresult);	// read new address
	// check for modifiers
	while (Input_accept_comma()) {
		// parse modifier. if no keyword given, give up
		if (Input_read_and_lower_keyword() == 0)
			goto fail;

		if (strcmp(GlobalDynaBuf->buffer, "overlay") == 0) {
			segment_flags |= SEGMENT_FLAG_OVERLAY;
		} else if (strcmp(GlobalDynaBuf->buffer, "invisible") == 0) {
			segment_flags |= SEGMENT_FLAG_INVISIBLE;
/*TODO		} else if (strcmp(GlobalDynaBuf->buffer, "limit") == 0) {
			skip '='
			read memory limit
		} else if (strcmp(GlobalDynaBuf->buffer, "stay" or "same" or something like that) == 0) {
			mutually exclusive with all other arguments!
			this would mean to keep all previous segment data,
			so it could be used with "*=*-5" or "*=*+3"
		} else if (strcmp(GlobalDynaBuf->buffer, "name") == 0) {
			skip '='
			read segment name (quoted string!)	*/
		} else {
			Throw_error("Unknown \"*=\" segment modifier.");
			goto fail;
		}
	}
	vcpu_set_pc(intresult.val.intval, segment_flags);
	// TODO - allow block syntax, so it is possible to put data "somewhere else" and then return to old position?
	Input_ensure_EOS();
	return;

fail:
	Input_skip_remainder();
}


// define default value for empty memory ("!initmem" pseudo opcode)
static enum eos po_initmem(void)
{
	struct number	intresult;

	// ignore in all passes but in first
	if (!FIRST_PASS)
		return SKIP_REMAINDER;

	// get value
	ALU_defined_int(&intresult);
	if ((intresult.val.intval > 255) || (intresult.val.intval < -128))
		Throw_error(exception_number_out_of_8b_range);
	if (output_initmem(intresult.val.intval & 0xff))
		return SKIP_REMAINDER;
	return ENSURE_EOS;
}


// change output "encryption" ("!xor" pseudo opcode)
static enum eos po_xor(void)
{
	char		old_value;
	intval_t	change;

	old_value = output_get_xor();
	ALU_any_int(&change);
	if ((change > 255) || (change < -128)) {
		Throw_error(exception_number_out_of_8b_range);
		change = 0;
	}
	output_set_xor(old_value ^ change);
	// if there's a block, parse that and then restore old value!
	if (Parse_optional_block())
		output_set_xor(old_value);
	return ENSURE_EOS;
}


// select output file and format ("!to" pseudo opcode)
static enum eos po_to(void)
{
	// bugfix: first read filename, *then* check for first pass.
	// if skipping right away, quoted colons might be misinterpreted as EOS
	// FIXME - fix the skipping code to handle quotes! :)
	// "!sl" has been fixed as well

	// read filename to global dynamic buffer
	// if no file name given, exit (complaining will have been done)
	if (Input_read_filename(FALSE, NULL))
		return SKIP_REMAINDER;

	// only act upon this pseudo opcode in first pass
	if (!FIRST_PASS)
		return SKIP_REMAINDER;

	if (outputfile_set_filename())
		return SKIP_REMAINDER;

	// select output format
	// if no comma found, use default file format
	if (Input_accept_comma() == FALSE) {
		if (outputfile_prefer_cbm_format()) {
			// output deprecation warning (unless user requests really old behaviour)
			if (config.wanted_version >= VER_DEPRECATE_REALPC)
				Throw_warning("Used \"!to\" without file format indicator. Defaulting to \"cbm\".");
		}
		return ENSURE_EOS;
	}

	// parse output format name
	// if no keyword given, give up
	if (Input_read_and_lower_keyword() == 0)
		return SKIP_REMAINDER;

	if (outputfile_set_format()) {
		// error occurred
		Throw_error("Unknown output format.");
		return SKIP_REMAINDER;
	}
	return ENSURE_EOS;	// success
}


// helper function for !8, !16, !24 and !32 pseudo opcodes
static enum eos iterate(void (*fn)(intval_t))
{
	struct iter_context	iter;
	struct object		object;

	iter.fn = fn;
	iter.accept_long_strings = FALSE;
	iter.stringxor = 0;
	do {
		ALU_any_result(&object);
		output_object(&object, &iter);
	} while (Input_accept_comma());
	return ENSURE_EOS;
}


// insert 8-bit values ("!8" / "!08" / "!by" / "!byte" pseudo opcode)
static enum eos po_byte(void)
{
	return iterate(output_8);
}


// Insert 16-bit values ("!16" / "!wo" / "!word" pseudo opcode)
static enum eos po_16(void)
{
	return iterate((CPU_state.type->flags & CPUFLAG_ISBIGENDIAN) ? output_be16 : output_le16);
}
// Insert 16-bit values big-endian ("!be16" pseudo opcode)
static enum eos po_be16(void)
{
	return iterate(output_be16);
}
// Insert 16-bit values little-endian ("!le16" pseudo opcode)
static enum eos po_le16(void)
{
	return iterate(output_le16);
}


// Insert 24-bit values ("!24" pseudo opcode)
static enum eos po_24(void)
{
	return iterate((CPU_state.type->flags & CPUFLAG_ISBIGENDIAN) ? output_be24 : output_le24);
}
// Insert 24-bit values big-endian ("!be24" pseudo opcode)
static enum eos po_be24(void)
{
	return iterate(output_be24);
}
// Insert 24-bit values little-endian ("!le24" pseudo opcode)
static enum eos po_le24(void)
{
	return iterate(output_le24);
}


// Insert 32-bit values ("!32" pseudo opcode)
static enum eos po_32(void)
{
	return iterate((CPU_state.type->flags & CPUFLAG_ISBIGENDIAN) ? output_be32 : output_le32);
}
// Insert 32-bit values big-endian ("!be32" pseudo opcode)
static enum eos po_be32(void)
{
	return iterate(output_be32);
}
// Insert 32-bit values little-endian ("!le32" pseudo opcode)
static enum eos po_le32(void)
{
	return iterate(output_le32);
}


// Insert bytes given as pairs of hex digits (helper for source code generators)
static enum eos po_hex(void)	// now GotByte = illegal char
{
	int		digits	= 0;
	unsigned char	byte	= 0;

	for (;;) {
		if (digits == 2) {
			Output_byte(byte);
			digits = 0;
			byte = 0;
		}
		if (GotByte >= '0' && GotByte <= '9') {
			byte = (byte << 4) | (GotByte - '0');
			++digits;
			GetByte();
			continue;
		}
		if (GotByte >= 'a' && GotByte <= 'f') {
			byte = (byte << 4) | (GotByte - 'a' + 10);
			++digits;
			GetByte();
			continue;
		}
		if (GotByte >= 'A' && GotByte <= 'F') {
			byte = (byte << 4) | (GotByte - 'A' + 10);
			++digits;
			GetByte();
			continue;
		}
		// if we're here, the current character is not a hex digit,
		// which is only allowed outside of pairs:
		if (digits == 1) {
			Throw_error("Hex digits are not given in pairs.");
			return SKIP_REMAINDER;	// error exit
		}
		switch (GotByte) {
		case ' ':
		case '\t':
			GetByte();	// spaces and tabs are ignored (maybe add commas, too?)
			continue;
		case CHAR_EOS:
			return AT_EOS_ANYWAY;	// normal exit
		default:
			Throw_error(exception_syntax);	// all other characters are errors
			return SKIP_REMAINDER;	// error exit
		}
	}
}


// "!cbm" pseudo opcode (now obsolete)
static enum eos po_cbm(void)
{
	if (config.wanted_version >= VER_DISABLED_OBSOLETE_STUFF) {
		Throw_error("\"!cbm\" is obsolete; use \"!ct pet\" instead.");
	} else {
		encoder_current = &encoder_pet;
		Throw_first_pass_warning("\"!cbm\" is deprecated; use \"!ct pet\" instead.");
	}
	return ENSURE_EOS;
}

// read encoding table from file
static enum eos user_defined_encoding(FILE *stream)
{
	unsigned char		local_table[256],
				*buffered_table		= encoding_loaded_table;
	const struct encoder	*buffered_encoder	= encoder_current;

	if (stream) {
		encoding_load_from_file(local_table, stream);
		fclose(stream);
	}
	encoder_current = &encoder_file;	// activate new encoding
	encoding_loaded_table = local_table;		// activate local table
	// if there's a block, parse that and then restore old values
	if (Parse_optional_block()) {
		encoder_current = buffered_encoder;
	} else {
		// if there's *no* block, the table must be used from now on.
		// copy the local table to the "outer" table
		memcpy(buffered_table, local_table, 256);
	}
	// re-activate "outer" table (it might have been changed by memcpy())
	encoding_loaded_table = buffered_table;
	return ENSURE_EOS;
}

// use one of the pre-defined encodings (raw, pet, scr)
static enum eos predefined_encoding(void)
{
	unsigned char		local_table[256],
				*buffered_table		= encoding_loaded_table;
	const struct encoder	*buffered_encoder	= encoder_current;

	if (Input_read_and_lower_keyword()) {
		const struct encoder	*new_encoder	= encoding_find();

		if (new_encoder)
			encoder_current = new_encoder;	// activate new encoder
	}
	encoding_loaded_table = local_table;	// activate local table
	// if there's a block, parse that and then restore old values
	if (Parse_optional_block())
		encoder_current = buffered_encoder;
	// re-activate "outer" table
	encoding_loaded_table = buffered_table;
	return ENSURE_EOS;
}
// set current encoding ("!convtab" pseudo opcode)
static enum eos po_convtab(void)
{
	boolean	uses_lib;
	FILE	*stream;

	if ((GotByte == '<') || (GotByte == '"')) {
		// encoding table from file
		if (Input_read_filename(TRUE, &uses_lib))
			return SKIP_REMAINDER;	// missing or unterminated file name

		stream = includepaths_open_ro(uses_lib);
		return user_defined_encoding(stream);
	} else {
		// one of the pre-defined encodings
		return predefined_encoding();
	}
}
// insert string(s)
static enum eos encode_string(const struct encoder *inner_encoder, unsigned char xor)
{
	const struct encoder	*outer_encoder	= encoder_current;	// buffer encoder
	struct iter_context	iter;
	struct object		object;

	iter.fn = output_8;
	iter.accept_long_strings = TRUE;
	iter.stringxor = xor;
	// make given encoder the current one (for ALU-parsed values)
	encoder_current = inner_encoder;
	do {
		// we need to keep the old string handler code, because if user selects
		// older dialect, the new code will complain about string lengths > 1!
		if ((GotByte == '"') && (config.wanted_version < VER_BACKSLASHESCAPING)) {
			// the old way of handling string literals:
			int	offset;

			DYNABUF_CLEAR(GlobalDynaBuf);
			if (Input_quoted_to_dynabuf('"'))
				return SKIP_REMAINDER;	// unterminated or escaping error

			// eat closing quote
			GetByte();
			// now convert to unescaped version
			if (Input_unescape_dynabuf(0))
				return SKIP_REMAINDER;	// escaping error

			// send characters
			for (offset = 0; offset < GlobalDynaBuf->size; ++offset)
				output_8(xor ^ encoding_encode_char(GLOBALDYNABUF_CURRENT[offset]));
		} else {
			// handle everything else (also strings in newer dialects):
			// parse value. no problems with single characters because the
			// current encoding is temporarily set to the given one.
			ALU_any_result(&object);
			output_object(&object, &iter);
		}
	} while (Input_accept_comma());
	encoder_current = outer_encoder;	// reactivate buffered encoder
	return ENSURE_EOS;
}
// insert text string (default format)
static enum eos po_text(void)
{
	return encode_string(encoder_current, 0);
}
// insert raw string
static enum eos po_raw(void)
{
	return encode_string(&encoder_raw, 0);
}
// insert PetSCII string
static enum eos po_pet(void)
{
	return encode_string(&encoder_pet, 0);
}
// insert screencode string
static enum eos po_scr(void)
{
	return encode_string(&encoder_scr, 0);
}
// insert screencode string, XOR'd
static enum eos po_scrxor(void)
{
	intval_t	xor;

	ALU_any_int(&xor);
	if (Input_accept_comma() == FALSE) {
		Throw_error(exception_syntax);
		return SKIP_REMAINDER;
	}
	return encode_string(&encoder_scr, xor);
}

// include binary file ("!binary" pseudo opcode)
// FIXME - split this into "parser" and "worker" fn and move worker fn somewhere else.
static enum eos po_binary(void)
{
	boolean		uses_lib;
	FILE		*stream;
	int		byte;
	struct number	size,
			skip;

	size.val.intval = -1;	// means "not given" => "until EOF"
	skip.val.intval	= 0;

	// if file name is missing, don't bother continuing
	if (Input_read_filename(TRUE, &uses_lib))
		return SKIP_REMAINDER;

	// try to open file
	stream = includepaths_open_ro(uses_lib);
	if (stream == NULL)
		return SKIP_REMAINDER;

	// read optional arguments
	if (Input_accept_comma()) {
		// any size given?
		if ((GotByte != ',') && (GotByte != CHAR_EOS)) {
			// then parse it
			ALU_defined_int(&size);
			if (size.val.intval < 0)
				Throw_serious_error(exception_negative_size);
		}
		// more?
		if (Input_accept_comma()) {
			// any skip given?
			if (GotByte != CHAR_EOS) {
				// then parse it
				ALU_defined_int(&skip);
			}
		}
	}
	// check whether including is a waste of time
	// FIXME - future changes ("several-projects-at-once")
	// may be incompatible with this!
	if ((size.val.intval >= 0) && (pass.undefined_count || pass.error_count)) {
	//if ((size.val.intval >= 0) && (pass.needvalue_count || pass.error_count)) {	FIXME - use!
		output_skip(size.val.intval);	// really including is useless anyway
	} else {
		// really insert file
		fseek(stream, skip.val.intval, SEEK_SET);	// set read pointer
		// if "size" non-negative, read "size" bytes.
		// otherwise, read until EOF.
		while (size.val.intval != 0) {
			byte = getc(stream);
			if (byte == EOF)
				break;
			Output_byte(byte);
			--size.val.intval;
		}
		// if more should have been read, warn and add padding
		if (size.val.intval > 0) {
			Throw_warning("Padding with zeroes.");
			do
				Output_byte(0);
			while (--size.val.intval);
		}
	}
	fclose(stream);
	// if verbose, produce some output
	if (FIRST_PASS && (config.process_verbosity > 1)) {
		int	amount	= vcpu_get_statement_size();

		printf("Loaded %d (0x%04x) bytes from file offset %ld (0x%04lx).\n",
			amount, amount, skip.val.intval, skip.val.intval);
	}
	return ENSURE_EOS;
}


// reserve space by sending bytes of given value ("!fi" / "!fill" pseudo opcode)
static enum eos po_fill(void)
{
	struct number	sizeresult;
	intval_t	fill	= FILLVALUE_FILL;

	ALU_defined_int(&sizeresult);	// FIXME - forbid addresses!
	if (Input_accept_comma())
		ALU_any_int(&fill);	// FIXME - forbid addresses!
	while (sizeresult.val.intval--)
		output_8(fill);
	return ENSURE_EOS;
}


// skip over some bytes in output without starting a new segment.
// in contrast to "*=*+AMOUNT", "!skip AMOUNT" does not start a new segment.
// (...and it will be needed in future for assemble-to-end-address)
static enum eos po_skip(void)	// now GotByte = illegal char
{
	struct number	amount;

	ALU_defined_int(&amount);	// FIXME - forbid addresses!
	if (amount.val.intval < 0)
		Throw_serious_error(exception_negative_size);	// TODO - allow this?
	else
		output_skip(amount.val.intval);
	return ENSURE_EOS;
}


// insert byte until PC fits condition
static enum eos po_align(void)
{
	struct number	andresult,
			equalresult;
	intval_t	fill;
	struct number	pc;

	// TODO:
	// now: !align ANDVALUE, EQUALVALUE [,FILLVALUE]
	// new: !align BLOCKSIZE
	// ...where block size must be a power of two
	ALU_defined_int(&andresult);	// FIXME - forbid addresses!
	if (!Input_accept_comma())
		Throw_error(exception_syntax);
	ALU_defined_int(&equalresult);	// ...allow addresses (unlikely, but possible)
	if (Input_accept_comma())
		ALU_any_int(&fill);
	else
		fill = CPU_state.type->default_align_value;

	// make sure PC is defined
	vcpu_read_pc(&pc);
	if (pc.ntype == NUMTYPE_UNDEFINED) {
		Throw_error(exception_pc_undefined);
		return SKIP_REMAINDER;
	}

	while ((pc.val.intval++ & andresult.val.intval) != equalresult.val.intval)
		output_8(fill);
	return ENSURE_EOS;
}


// not using a block is no longer allowed
static void old_offset_assembly(void)
{
	// really old versions allowed it
	if (config.wanted_version < VER_DEPRECATE_REALPC)
		return;

	// then it was deprecated
	if (config.wanted_version < VER_DISABLED_OBSOLETE_STUFF) {
		Throw_first_pass_warning("\"!pseudopc/!realpc\" is deprecated; use \"!pseudopc {}\" instead.");
		return;
	}

	// now it's obsolete
	Throw_error("\"!pseudopc/!realpc\" is obsolete; use \"!pseudopc {}\" instead.");	// FIXME - amend msg, tell user how to use old behaviour!
}

// start offset assembly
// TODO - maybe add a label argument to assign the block size afterwards (for assemble-to-end-address) (or add another pseudo opcode)
static enum eos po_pseudopc(void)
{
	struct number	new_pc;

	// get new value
	ALU_defined_int(&new_pc);	// FIXME - allow for undefined! (complaining about non-addresses would be logical, but annoying)
/* TODO - add this. check if code can be shared with "*="!
	// check for modifiers
	while (Input_accept_comma()) {
		// parse modifier. if no keyword given, give up
		if (Input_read_and_lower_keyword() == 0)
			return SKIP_REMAINDER;

		if (strcmp(GlobalDynaBuf->buffer, "limit") == 0) {
			skip '='
			read memory limit
		} else if (strcmp(GlobalDynaBuf->buffer, "name") == 0) {
			skip '='
			read segment name (quoted string!)
		} else {
			Throw_error("Unknown !pseudopc segment modifier.");
			return SKIP_REMAINDER;
		}
	}
*/
	pseudopc_start(&new_pc);
	// if there's a block, parse that and then restore old value!
	if (Parse_optional_block()) {
		pseudopc_end();	// restore old state
	} else {
		old_offset_assembly();
	}
	return ENSURE_EOS;
}


// "!realpc" pseudo opcode (now obsolete)
static enum eos po_realpc(void)
{
	old_offset_assembly();
	pseudopc_end_all();	// restore outermost state
	return ENSURE_EOS;
}


// select CPU ("!cpu" pseudo opcode)
static enum eos po_cpu(void)
{
	const struct cpu_type	*cpu_buffer	= CPU_state.type;	// remember current cpu
	const struct cpu_type	*new_cpu_type;

	if (Input_read_and_lower_keyword()) {
		new_cpu_type = cputype_find();
		if (new_cpu_type)
			CPU_state.type = new_cpu_type;	// activate new cpu type
		else
			Throw_error("Unknown processor.");
	}
	// if there's a block, parse that and then restore old value
	if (Parse_optional_block())
		CPU_state.type = cpu_buffer;
	return ENSURE_EOS;
}


// set register length, block-wise if needed.
static enum eos set_register_length(boolean *var, boolean make_long)
{
	int	old_size	= *var;

	// set new register length (or complain - whichever is more fitting)
	vcpu_check_and_set_reg_length(var, make_long);
	// if there's a block, parse that and then restore old value!
	if (Parse_optional_block())
		vcpu_check_and_set_reg_length(var, old_size);	// restore old length
	return ENSURE_EOS;
}
// switch to long accumulator ("!al" pseudo opcode)
static enum eos po_al(void)
{
	return set_register_length(&CPU_state.a_is_long, TRUE);
}
// switch to short accumulator ("!as" pseudo opcode)
static enum eos po_as(void)
{
	return set_register_length(&CPU_state.a_is_long, FALSE);
}
// switch to long index registers ("!rl" pseudo opcode)
static enum eos po_rl(void)
{
	return set_register_length(&CPU_state.xy_are_long, TRUE);
}
// switch to short index registers ("!rs" pseudo opcode)
static enum eos po_rs(void)
{
	return set_register_length(&CPU_state.xy_are_long, FALSE);
}


// force explicit label definitions to set "address" flag ("!addr"). Has to be re-entrant.
static enum eos po_address(void)	// now GotByte = illegal char
{
	SKIPSPACE();
	if (GotByte == CHAR_SOB) {
		typesystem_force_address_block();
		return ENSURE_EOS;
	}
	typesystem_force_address_statement(TRUE);
	return PARSE_REMAINDER;
}


#if 0
// enumerate constants ("!enum")
static enum eos po_enum(void)	// now GotByte = illegal char
{
	struct number	step;

	step.val.intval = 1;
	ALU_defined_int(&step);
Throw_serious_error("Not yet");	// FIXME
	return ENSURE_EOS;
}
#endif


// (re)set symbol
static enum eos po_set(void)	// now GotByte = illegal char
{
	scope_t	scope;
	int	force_bit;

	if (Input_read_scope_and_keyword(&scope) == 0)	// skips spaces before
		return SKIP_REMAINDER;	// zero length

	force_bit = Input_get_force_bit();	// skips spaces after
	if (GotByte != '=') {
		Throw_error(exception_syntax);
		return SKIP_REMAINDER;
	}

	// TODO: in versions before 0.97, force bit handling was broken in both
	// "!set" and "!for":
	// trying to change a force bit raised an error (which is correct), but
	// in any case, ALL FORCE BITS WERE CLEARED in symbol. only cases like
	// !set N=N+1 worked, because the force bit was taken from result.
	// maybe support this behaviour via --dialect? I'd rather not...
	parse_assignment(scope, force_bit, POWER_CHANGE_VALUE | POWER_CHANGE_OBJTYPE);
	return ENSURE_EOS;
}


// set file name for symbol list
static enum eos po_symbollist(void)
{
	// bugfix: first read filename, *then* check for first pass.
	// if skipping right away, quoted colons might be misinterpreted as EOS
	// FIXME - why not just fix the skipping code to handle quotes? :)
	// "!to" has been fixed as well

	// read filename to global dynamic buffer
	// if no file name given, exit (complaining will have been done)
	if (Input_read_filename(FALSE, NULL))
		return SKIP_REMAINDER;

	// only process this pseudo opcode in first pass
	if (!FIRST_PASS)
		return SKIP_REMAINDER;

	// if symbol list file name already set, complain and exit
	if (symbollist_filename) {
		Throw_warning("Symbol list file name already chosen.");
		return SKIP_REMAINDER;
	}

	// get malloc'd copy of filename
	symbollist_filename = DynaBuf_get_copy(GlobalDynaBuf);
	// ensure there's no garbage at end of line
	return ENSURE_EOS;
}


// switch to new zone ("!zone" or "!zn"). has to be re-entrant.
static enum eos po_zone(void)
{
	struct section	entry_values;	// buffer for outer zone
	char		*new_title;
	int		allocated;

	// remember everything about current structure
	entry_values = *section_now;
	// set default values in case there is no valid title
	new_title = s_untitled;
	allocated = FALSE;
	// check whether a zone title is given. if yes and it can be read,
	// get copy, remember pointer and remember to free it later on.
	if (BYTE_CONTINUES_KEYWORD(GotByte)) {
		// because we know of one character for sure,
		// there's no need to check the return value.
		Input_read_keyword();
		new_title = DynaBuf_get_copy(GlobalDynaBuf);
		allocated = TRUE;
	}
	// setup new section
	// section type is "subzone", just in case a block follows
	section_new(section_now, "Subzone", new_title, allocated);
	if (Parse_optional_block()) {
		// block has been parsed, so it was a SUBzone.
		section_finalize(section_now);	// end inner zone
		*section_now = entry_values;	// restore entry values
	} else {
		// no block found, so it's a normal zone change
		section_finalize(&entry_values);	// end outer zone
		section_now->type = "Zone";	// fix type
	}
	return ENSURE_EOS;
}

// "!subzone" or "!sz" pseudo opcode (now obsolete)
static enum eos po_subzone(void)
{
	if (config.wanted_version >= VER_DISABLED_OBSOLETE_STUFF)
		Throw_error("\"!subzone {}\" is obsolete; use \"!zone {}\" instead.");
	else
		Throw_first_pass_warning("\"!subzone {}\" is deprecated; use \"!zone {}\" instead.");
	// call "!zone" instead
	return po_zone();
}

// include source file ("!source" or "!src"). has to be re-entrant.
static enum eos po_source(void)	// now GotByte = illegal char
{
	boolean		uses_lib;
	FILE		*stream;
	char		local_gotbyte;
	struct input	new_input,
			*outer_input;

	// enter new nesting level
	// quit program if recursion too deep
	if (--source_recursions_left < 0)
		Throw_serious_error("Too deeply nested. Recursive \"!source\"?");
	// read file name. quit function on error
	if (Input_read_filename(TRUE, &uses_lib))
		return SKIP_REMAINDER;

	// if file could be opened, parse it. otherwise, complain
	stream = includepaths_open_ro(uses_lib);
	if (stream) {
// FIXME - just use safe_malloc and never free! this also saves us making a copy if defining macros down the road...
#ifdef __GNUC__
		char	filename[GlobalDynaBuf->size];	// GCC can do this
#else
		char	*filename	= safe_malloc(GlobalDynaBuf->size);	// VS can not
#endif

		strcpy(filename, GLOBALDYNABUF_CURRENT);
		outer_input = Input_now;	// remember old input
		local_gotbyte = GotByte;	// CAUTION - ugly kluge
		Input_now = &new_input;	// activate new input
		flow_parse_and_close_file(stream, filename);
		Input_now = outer_input;	// restore previous input
		GotByte = local_gotbyte;	// CAUTION - ugly kluge
#ifndef __GNUC__
		free(filename);	// GCC auto-frees
#endif
	}
	// leave nesting level
	++source_recursions_left;
	return ENSURE_EOS;
}

// if/ifdef/ifndef/else
enum ifmode {
	IFMODE_IF,	// parse expression, then block
	IFMODE_IFDEF,	// check symbol, then parse block or line
	IFMODE_IFNDEF,	// check symbol, then parse block or line
	IFMODE_ELSE	// unconditional last block
};
// has to be re-entrant
static enum eos ifelse(enum ifmode mode)
{
	boolean		nothing_done	= TRUE;	// once a block gets executed, this becomes FALSE, so all others will be skipped even if condition met
	boolean		condition_met;	// condition result for next block
	struct number	ifresult;

	for (;;) {
		// check condition according to mode
		switch (mode) {
		case IFMODE_IF:
			ALU_defined_int(&ifresult);
			condition_met = !!ifresult.val.intval;
			if (GotByte != CHAR_SOB)
				Throw_serious_error(exception_no_left_brace);
			break;
		case IFMODE_IFDEF:
			condition_met = check_ifdef_condition();
			break;
		case IFMODE_IFNDEF:
			condition_met = !check_ifdef_condition();
			break;
		case IFMODE_ELSE:
			condition_met = TRUE;
			break;
		default:
			Bug_found("IllegalIfMode", mode);
			condition_met = TRUE;	// inhibit compiler warning ;)
		}
		SKIPSPACE();
		// execute this block?
		if (condition_met && nothing_done) {
			nothing_done = FALSE;	// all further ones will be skipped, even if conditions meet
			if (GotByte == CHAR_SOB) {
		                Parse_until_eob_or_eof();	// parse block
        		        // if block isn't correctly terminated, complain and exit
                		if (GotByte != CHAR_EOB)
                		        Throw_serious_error(exception_no_right_brace);
			} else {
				return PARSE_REMAINDER;	// parse line (only for ifdef/ifndef)
			}
		} else {
			if (GotByte == CHAR_SOB) {
				Input_skip_or_store_block(FALSE);	// skip block
			} else {
				return SKIP_REMAINDER;	// skip line (only for ifdef/ifndef)
			}
		}
		// now GotByte = '}'
		NEXTANDSKIPSPACE();
		// after ELSE {} it's all over. it must be.
		if (mode == IFMODE_ELSE) {
			// we could just return ENSURE_EOS, but checking here allows for better error message
			if (GotByte != CHAR_EOS)
				Throw_error("Expected end-of-statement after ELSE block.");
			return SKIP_REMAINDER;	// normal exit after ELSE {...}
		}

		// anything more?
		if (GotByte == CHAR_EOS)
			return AT_EOS_ANYWAY;	// normal exit if there is no ELSE {...} block

		// read keyword (expected to be "else")
		if (Input_read_and_lower_keyword() == 0)
			return SKIP_REMAINDER;	// "missing string error" -> ignore rest of line

		// make sure it's "else"
		if (strcmp(GlobalDynaBuf->buffer, "else")) {
			Throw_error("Expected ELSE or end-of-statement.");
			return SKIP_REMAINDER;	// an error has been reported, so ignore rest of line
		}
		// anything more?
		SKIPSPACE();
		if (GotByte == CHAR_SOB) {
			// ELSE {...} -> one last round
			mode = IFMODE_ELSE;
			continue;
		}

		// read keyword (expected to be if/ifdef/ifndef)
		if (Input_read_and_lower_keyword() == 0)
			return SKIP_REMAINDER;	// "missing string error" -> ignore rest of line

		// which one is it?
		if (strcmp(GlobalDynaBuf->buffer, "if") == 0) {
			mode = IFMODE_IF;
		} else if (strcmp(GlobalDynaBuf->buffer, "ifdef") == 0) {
			mode = IFMODE_IFDEF;
		} else if (strcmp(GlobalDynaBuf->buffer, "ifndef") == 0) {
			mode = IFMODE_IFNDEF;
		} else {
			Throw_error("After ELSE, expected block or IF/IFDEF/IFNDEF.");
			return SKIP_REMAINDER;	// an error has been reported, so ignore rest of line
		}
	}
}

// conditional assembly ("!if"). has to be re-entrant.
static enum eos po_if(void)	// now GotByte = illegal char
{
	return ifelse(IFMODE_IF);
}


// conditional assembly ("!ifdef"). has to be re-entrant.
static enum eos po_ifdef(void)	// now GotByte = illegal char
{
	return ifelse(IFMODE_IFDEF);
}


// conditional assembly ("!ifndef"). has to be re-entrant.
static enum eos po_ifndef(void)	// now GotByte = illegal char
{
	return ifelse(IFMODE_IFNDEF);
}


// looping assembly ("!for"). has to be re-entrant.
// old counter syntax: !for VAR, END { BLOCK }		VAR counts from 1 to END
// new counter syntax: !for VAR, START, END { BLOCK }	VAR counts from START to END
// iterating syntax: !for VAR in ITERABLE { BLOCK }	VAR iterates over string/list contents
static enum eos po_for(void)	// now GotByte = illegal char
{
	scope_t		scope;
	bits		force_bit;
	struct for_loop	loop;
	struct number	intresult;

	if (Input_read_scope_and_keyword(&scope) == 0)	// skips spaces before
		return SKIP_REMAINDER;	// zero length

	// now GotByte = illegal char
	force_bit = Input_get_force_bit();	// skips spaces after
	loop.symbol = symbol_find(scope);	// if not number, error will be reported on first assignment
	if (Input_accept_comma()) {
		// counter syntax (old or new)
		loop.u.counter.force_bit = force_bit;
		ALU_defined_int(&intresult);	// read first argument
		loop.u.counter.addr_refs = intresult.addr_refs;
		if (Input_accept_comma()) {
			// new counter syntax
			loop.algorithm = FORALGO_NEWCOUNT;
			if (config.wanted_version < VER_NEWFORSYNTAX)
				Throw_first_pass_warning("Found new \"!for\" syntax.");
			loop.u.counter.first = intresult.val.intval;	// use first argument
			ALU_defined_int(&intresult);	// read second argument
			// compare addr_ref counts and complain if not equal!
			if (config.warn_on_type_mismatch
			&& (intresult.addr_refs != loop.u.counter.addr_refs)) {
				Throw_first_pass_warning("Wrong type for loop's END value - must match type of START value.");
			}
			// setup direction and total
			if (loop.u.counter.first <= intresult.val.intval) {
				// count up
				loop.iterations_left = 1 + intresult.val.intval - loop.u.counter.first;
				loop.u.counter.increment = 1;
			} else {
				// count down
				loop.iterations_left = 1 + loop.u.counter.first - intresult.val.intval;
				loop.u.counter.increment = -1;
			}
		} else {
			// old counter syntax
			loop.algorithm = FORALGO_OLDCOUNT;
			if (config.wanted_version >= VER_NEWFORSYNTAX)
				Throw_first_pass_warning("Found old \"!for\" syntax.");
			if (intresult.val.intval < 0)
				Throw_serious_error("Loop count is negative.");
			// count up
			loop.u.counter.first = 1;
			loop.iterations_left = intresult.val.intval;	// use given argument
			loop.u.counter.increment = 1;
		}
	} else {
		// iterator syntax
		loop.algorithm = FORALGO_ITERATE;
		// check for "in" keyword
		if ((GotByte != 'i') && (GotByte != 'I')) {
			Throw_error(exception_syntax);
			return SKIP_REMAINDER;	// FIXME - this ignores '{' and will then complain about '}'
		}
/* checking for the first character explicitly here looks dumb, but actually
solves a purpose: we're here because the check for comma failed, but maybe that
was just a typo. if the current byte is '.' or '-' or whatever, then trying to
read a keyword will result in "No string given" - which is confusing for the
user if they did not even want to put a string there.
so if the current byte is not the start of "in" we just throw a syntax error.
knowing there is an "i" also makes sure that Input_read_and_lower_keyword()
does not fail. */
		Input_read_and_lower_keyword();
		if (strcmp(GlobalDynaBuf->buffer, "in") != 0) {
			Throw_error("Loop var must be followed by either \"in\" keyword or comma.");
			return SKIP_REMAINDER;	// FIXME - this ignores '{' and will then complain about '}'
		}
		if (force_bit) {
			Throw_error("Force bits can only be given to counters, not when iterating over string/list contents.");
			return SKIP_REMAINDER;	// FIXME - this ignores '{' and will then complain about '}'
		}
		ALU_any_result(&loop.u.iter.obj);	// get iterable
		loop.iterations_left = loop.u.iter.obj.type->length(&loop.u.iter.obj);
		if (loop.iterations_left < 0) {
			Throw_error("Given object is not iterable.");
			return SKIP_REMAINDER;	// FIXME - this ignores '{' and will then complain about '}'
		}
	}

	if (GotByte != CHAR_SOB)
		Throw_serious_error(exception_no_left_brace);

	// remember line number of loop pseudo opcode
	loop.block.start = Input_now->line_number;
	// read loop body into DynaBuf and get copy
	loop.block.body = Input_skip_or_store_block(TRUE);	// changes line number!

	flow_forloop(&loop);
	// free memory
	free(loop.block.body);

	// GotByte of OuterInput would be '}' (if it would still exist)
	GetByte();	// fetch next byte
	return ENSURE_EOS;
}


// looping assembly ("!do"). has to be re-entrant.
static enum eos po_do(void)	// now GotByte = illegal char
{
	struct do_while	loop;

	// read head condition to buffer
	SKIPSPACE();
	flow_store_doloop_condition(&loop.head_cond, CHAR_SOB);	// must be freed!
	if (GotByte != CHAR_SOB)
		Throw_serious_error(exception_no_left_brace);
	// remember line number of loop body,
	// then read block and get copy
	loop.block.start = Input_now->line_number;
	// reading block changes line number!
	loop.block.body = Input_skip_or_store_block(TRUE);	// must be freed!
	// now GotByte = '}'
	NEXTANDSKIPSPACE();	// now GotByte = first non-blank char after block
	// read tail condition to buffer
	flow_store_doloop_condition(&loop.tail_cond, CHAR_EOS);	// must be freed!
	// now GotByte = CHAR_EOS
	flow_do_while(&loop);
	// free memory
	free(loop.head_cond.body);
	free(loop.block.body);
	free(loop.tail_cond.body);
	return AT_EOS_ANYWAY;
}


// looping assembly ("!while", alternative for people used to c-style loops). has to be re-entrant.
static enum eos po_while(void)	// now GotByte = illegal char
{
	struct do_while	loop;

	// read condition to buffer
	SKIPSPACE();
	flow_store_while_condition(&loop.head_cond);	// must be freed!
	if (GotByte != CHAR_SOB)
		Throw_serious_error(exception_no_left_brace);
	// remember line number of loop body,
	// then read block and get copy
	loop.block.start = Input_now->line_number;
	// reading block changes line number!
	loop.block.body = Input_skip_or_store_block(TRUE);	// must be freed!
	// clear tail condition
	loop.tail_cond.body = NULL;
	flow_do_while(&loop);
	// free memory
	free(loop.head_cond.body);
	free(loop.block.body);
	// GotByte of OuterInput would be '}' (if it would still exist)
	GetByte();	// fetch next byte
	return ENSURE_EOS;
}


// macro definition ("!macro").
static enum eos po_macro(void)	// now GotByte = illegal char
{
	// in first pass, parse. In all other passes, skip.
	if (FIRST_PASS) {
		Macro_parse_definition();	// now GotByte = '}'
	} else {
		// skip until CHAR_SOB ('{') is found.
		// no need to check for end-of-statement, because such an
		// error would already have been detected in first pass.
		// for the same reason, there is no need to check for quotes.
		while (GotByte != CHAR_SOB)
			GetByte();
		Input_skip_or_store_block(FALSE);	// now GotByte = '}'
	}
	GetByte();	// Proceed with next character
	return ENSURE_EOS;
}

/*
// trace/watch
#define TRACEWATCH_LOAD		(1u << 0)
#define TRACEWATCH_STORE	(1u << 1)
#define TRACEWATCH_EXEC		(1u << 2)
#define TRACEWATCH_DEFAULT	(TRACEWATCH_LOAD | TRACEWATCH_STORE | TRACEWATCH_EXEC)
#define TRACEWATCH_BREAK	(1u << 3)
static enum eos tracewatch(boolean enter_monitor)
{
	struct number	pc;
	bits		flags	= 0;

	vcpu_read_pc(&pc);
	SKIPSPACE();
	// check for flags
	if (GotByte != CHAR_EOS) {
		do {
			// parse flag. if no keyword given, give up
			if (Input_read_and_lower_keyword() == 0)
				return SKIP_REMAINDER;	// fail (error has been reported)

			if (strcmp(GlobalDynaBuf->buffer, "load") == 0) {
				flags |= TRACEWATCH_LOAD;
			} else if (strcmp(GlobalDynaBuf->buffer, "store") == 0) {
				flags |= TRACEWATCH_STORE;
			} else if (strcmp(GlobalDynaBuf->buffer, "exec") == 0) {
				flags |= TRACEWATCH_EXEC;
			} else {
				Throw_error("Unknown flag (known are: load, store, exec).");	// FIXME - add to docs!
				return SKIP_REMAINDER;
			}
		} while (Input_accept_comma());
	}
	// shortcut: no flags at all -> set all flags!
	if (!flags)
		flags = TRACEWATCH_DEFAULT;
	if (enter_monitor)
		flags |= TRACEWATCH_BREAK;
	if (pc.ntype != NUMTYPE_UNDEFINED) {
		//FIXME - store pc and flags!
	}
	return ENSURE_EOS;
}
// make next byte a trace point (for VICE debugging)
static enum eos po_trace(void)
{
	return tracewatch(FALSE);	// do not enter monitor, just output
}
// make next byte a watch point (for VICE debugging)
static enum eos po_watch(void)
{
	return tracewatch(TRUE);	// break into monitor
}
*/

// constants
#define USERMSG_INITIALSIZE	80


// variables
static	STRUCT_DYNABUF_REF(user_message, USERMSG_INITIALSIZE);	// for !warn/error/serious


// helper function to show user-defined messages
static enum eos throw_string(const char prefix[], void (*fn)(const char *))
{
	struct object	object;

	DYNABUF_CLEAR(user_message);
	DynaBuf_add_string(user_message, prefix);
	do {
		if ((GotByte == '"') && (config.wanted_version < VER_BACKSLASHESCAPING)) {
			DYNABUF_CLEAR(GlobalDynaBuf);
			if (Input_quoted_to_dynabuf('"'))
				return SKIP_REMAINDER;	// unterminated or escaping error

			// eat closing quote
			GetByte();
			// now convert to unescaped version
			if (Input_unescape_dynabuf(0))
				return SKIP_REMAINDER;	// escaping error

			DynaBuf_append(GlobalDynaBuf, '\0');	// terminate string
			DynaBuf_add_string(user_message, GLOBALDYNABUF_CURRENT);	// add to message
		} else {
			// parse value
			ALU_any_result(&object);
			object.type->print(&object, user_message);
		}
	} while (Input_accept_comma());
	DynaBuf_append(user_message, '\0');
	fn(user_message->buffer);
	return ENSURE_EOS;
}


#if 0
// show debug data given in source code
static enum eos po_debug(void)
{
	// FIXME - make debug output depend on some cli switch
	return throw_string("!debug: ", throw_message);
}
// show info given in source code
static enum eos po_info(void)
{
	return throw_string("!info: ", throw_message);
}
#endif


// throw warning as given in source code
static enum eos po_warn(void)
{
	return throw_string("!warn: ", Throw_warning);

}


// throw error as given in source code
static enum eos po_error(void)
{
	return throw_string("!error: ", Throw_error);
}


// throw serious error as given in source code
static enum eos po_serious(void)
{
	return throw_string("!serious: ", Throw_serious_error);
}


// end of source file ("!endoffile" or "!eof")
static enum eos po_endoffile(void)
{
	// well, it doesn't end right here and now, but at end-of-line! :-)
	Input_ensure_EOS();
	Input_now->state = INPUTSTATE_EOF;
	return AT_EOS_ANYWAY;
}

// pseudo opcode table
static struct ronode	pseudo_opcode_tree[]	= {
	PREDEF_START,
	PREDEFNODE("initmem",		po_initmem),
	PREDEFNODE("xor",		po_xor),
	PREDEFNODE("to",		po_to),
	PREDEFNODE("by",		po_byte),
	PREDEFNODE("byte",		po_byte),
	PREDEFNODE("8",			po_byte),
	PREDEFNODE("08",		po_byte),	// legacy alias, don't ask...
	PREDEFNODE("wo",		po_16),
	PREDEFNODE("word",		po_16),
	PREDEFNODE("16",		po_16),
	PREDEFNODE("be16",		po_be16),
	PREDEFNODE("le16",		po_le16),
	PREDEFNODE("24",		po_24),
	PREDEFNODE("be24",		po_be24),
	PREDEFNODE("le24",		po_le24),
	PREDEFNODE("32",		po_32),
	PREDEFNODE("be32",		po_be32),
	PREDEFNODE("le32",		po_le32),
	PREDEFNODE("h",			po_hex),
	PREDEFNODE("hex",		po_hex),
	PREDEFNODE("cbm",		po_cbm),	// obsolete
	PREDEFNODE("ct",		po_convtab),
	PREDEFNODE("convtab",		po_convtab),
	PREDEFNODE("tx",		po_text),
	PREDEFNODE("text",		po_text),
	PREDEFNODE("raw",		po_raw),
	PREDEFNODE("pet",		po_pet),
	PREDEFNODE("scr",		po_scr),
	PREDEFNODE("scrxor",		po_scrxor),
	PREDEFNODE("bin",		po_binary),
	PREDEFNODE("binary",		po_binary),
	PREDEFNODE("fi",		po_fill),
	PREDEFNODE("fill",		po_fill),
	PREDEFNODE("skip",		po_skip),
	PREDEFNODE("align",		po_align),
	PREDEFNODE("pseudopc",		po_pseudopc),
	PREDEFNODE("realpc",		po_realpc),	// obsolete
	PREDEFNODE("cpu",		po_cpu),
	PREDEFNODE("al",		po_al),
	PREDEFNODE("as",		po_as),
	PREDEFNODE("rl",		po_rl),
	PREDEFNODE("rs",		po_rs),
	PREDEFNODE("addr",		po_address),
	PREDEFNODE("address",		po_address),
//	PREDEFNODE("enum",		po_enum),
	PREDEFNODE("set",		po_set),
	PREDEFNODE("sl",		po_symbollist),
	PREDEFNODE("symbollist",	po_symbollist),
	PREDEFNODE("zn",		po_zone),
	PREDEFNODE("zone",		po_zone),
	PREDEFNODE("sz",		po_subzone),	// obsolete
	PREDEFNODE("subzone",		po_subzone),	// obsolete
	PREDEFNODE("src",		po_source),
	PREDEFNODE("source",		po_source),
	PREDEFNODE("if",		po_if),
	PREDEFNODE("ifdef",		po_ifdef),
	PREDEFNODE("ifndef",		po_ifndef),
	PREDEFNODE("for",		po_for),
	PREDEFNODE("do",		po_do),
	PREDEFNODE("while",		po_while),
	PREDEFNODE("macro",		po_macro),
/*	PREDEFNODE("trace",		po_trace),
	PREDEFNODE("watch",		po_watch),	*/
//	PREDEFNODE("debug",		po_debug),
//	PREDEFNODE("info",		po_info),
	PREDEFNODE("warn",		po_warn),
	PREDEFNODE("error",		po_error),
	PREDEFNODE("serious",		po_serious),
	PREDEFNODE("eof",		po_endoffile),
	PREDEF_END("endoffile",		po_endoffile),
	//    ^^^^ this marks the last element
};


// parse a pseudo opcode. has to be re-entrant.
void pseudoopcode_parse(void)	// now GotByte = "!"
{
	void		*node_body;
	enum eos	(*fn)(void),
			then	= SKIP_REMAINDER;	// prepare for errors

	GetByte();	// read next byte
	// on missing keyword, return (complaining will have been done)
	if (Input_read_and_lower_keyword()) {
		// search for tree item
		if ((Tree_easy_scan(pseudo_opcode_tree, &node_body, GlobalDynaBuf))
		&& node_body) {
			fn = (enum eos (*)(void)) node_body;
			SKIPSPACE();
			// call function
			then = fn();
		} else {
			Throw_error(exception_unknown_pseudo_opcode);
		}
	}
	if (then == SKIP_REMAINDER)
		Input_skip_remainder();
	else if (then == ENSURE_EOS)
		Input_ensure_EOS();
	// the other two possibilities (PARSE_REMAINDER and AT_EOS_ANYWAY)
	// will lead to the remainder of the line being parsed by the mainloop.
}
