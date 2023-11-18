CFLAGS = -O3 -Wall
#LDLIBS = -lpng
# Solving the macos + homebrew linking hell:
LDLIBS = -I/opt/homebrew/Cellar/libpng/1.6.37/include/libpng16 -L/opt/homebrew/Cellar/libpng/1.6.37/lib -Wl,-rpath,/opt/homebrew/Cellar/libpng/1.6.37/lib -lpng16

CC = gcc

.PHONY: all

all: colimage_0.png.bin colimage_1.png.bin colimage_2.png.bin colimage_3.png.bin

convert: convert.c
	$(CC) -o $@ $< $(CFLAGS) $(LDLIBS)

colimage_0.png.bin: colimage_0.png
	python convert_one_colimage.py colimage_0.png
colimage_1.png.bin: colimage_1.png
	python convert_one_colimage.py colimage_1.png
colimage_2.png.bin: colimage_2.png
	python convert_one_colimage.py colimage_2.png
colimage_3.png.bin: colimage_3.png
	python convert_one_colimage.py colimage_3.png

clean:
	-rm convert *.bin
