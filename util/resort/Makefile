include ../../link/paths.mk
include ../../link/defines.mk

.PHONY: all

all: resort

resort: resort.c
	$(CC) $< -o $@ $(CFLAGS) $(LDLIBS)

clean:
	-rm resort
