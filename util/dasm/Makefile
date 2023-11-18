CFLAGS = -Os -Wall -ffast-math -fomit-frame-pointer -fgcse -s
# -s
CC = gcc
DASM_SRC = main.c exp.c globals.c mne6502.c ops.c symbols.c

.PHONY: all

all: dasm

dasm: $(DASM_SRC) asm.h
	$(CC) -o $@ $(DASM_SRC) $(CFLAGS)

clean:
	-rm dasm
