CFLAGS = -O3 -Wall
LDLIBS = -lpng
CC = gcc

.PHONY: all

all: convert

convert: convert.c
	$(CC) -o $@ $< $(CFLAGS) $(LDLIBS)

clean:
	-rm convert *.bin
