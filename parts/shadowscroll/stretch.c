#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>
#include <string.h>

#define PI atan2 (0.0, -1.0)

void fatal(const char* s, ...) {
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        exit(2);
}

signed read_number(char* sw, char* arg, int llim, int hlim) {
    int num = strtoul(arg, NULL, 10);
    if (num < llim || num > hlim) {
        fatal("number for '%s' must be between %d and %d", sw, llim, hlim);
    }
    return num;
}

//have a struct that has all store dests and xvals
//if only one x val is left, things get easy to be resorted, else swapping might be an idea, reload of a is too expensive (4 cycles instead of two saved)
int main(int argc, char *argv[]) {
	unsigned char wave_x[256];
	unsigned char wave_y[256];

	unsigned char spr_y[256];
	unsigned char spr_x_lo[256];
	unsigned char spr_x_hi[256];

	unsigned char xfrac8[256];
	unsigned char yfrac8[256];
	unsigned char yfrac16[256];
	unsigned char xfrac8_sin[256];
	unsigned char yfrac8_sin[256];
	unsigned char yfrac16_sin[256];
	int x;

	FILE* fw;
	float sx,sy;

	for (x = 0; x < 256; x++) {
		xfrac8[x] = ((x * 40 / 64) + 18) & 255;
		yfrac8[x] = (int)(0x200 * x / 256.0 + 0xb8) & 255;
		yfrac16[x] = ((int)(0x200 * x / 256.0 + 0xb8) >> 8) & 255;
	}
	for (x = 0; x < 256; x++) {
		sx = sinf(2.0 * PI * x / 256.0) * 127.5 + 127.5;
		sy = cosf(2.0 * PI * x / 256.0) * 127.5 + 127.5;
		wave_y[x] = (unsigned char)sy;
		wave_x[x] = ((unsigned int)sx);
		sx = sinf(2.0 * PI * x / 256.0) * 140 + 140 + 32;
		sy = cosf(2.0 * PI * x / 256.0) * -28.0 + 28.0 + 0x23;
		spr_y[x] = (unsigned char)sy;
		spr_x_lo[x] = ((unsigned int)sx);
		spr_x_hi[x] = (((unsigned int)sx) >> 8) * 255;
	}
	for (x = 0; x < 256; x++) {
		xfrac8_sin[x] = xfrac8[wave_y[(x + 0xca) & 255]];
		yfrac8_sin[x]  = yfrac8 [wave_y[(x + 0x00) & 255]];
		yfrac16_sin[x] = yfrac16[wave_y[(x + 0x00) & 255]];
	}

	fw = fopen("sinus.bin","wb");
	fwrite(wave_y,1,256,fw);
	fwrite(wave_x,1,256,fw);
	fwrite(spr_y,1,256,fw);
	fwrite(spr_x_lo,1,256,fw);
	fwrite(spr_x_hi,1,256,fw);
	fwrite(xfrac8_sin,1,256,fw);
	fwrite(yfrac8_sin,1,256,fw);
	fwrite(yfrac16_sin,1,256,fw);
	fclose(fw);

	return 0;
}
