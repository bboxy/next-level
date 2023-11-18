#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>
#include <string.h>

#define PI atan2 (0.0, -1.0)

int main(int argc, char *argv[]) {
	unsigned char wave[] = {
		4,
		8,
		10,
		12,
		13,
		14,
		15,
		15,
		16,
		17,
		18,
		18,
		19,
		19,
		20,
		21,
		21,
		22,
		23,
		25,
		28,
		32,
	};
	unsigned char sinus[32];
	float x;
	float f;
	int y;

	FILE* fw;
	fw = fopen("sinus.bin","wb");

	for (y = 0; y < 32; y++) sinus[y] = 0;
	for (f = 0.0; f < 16.0; f += 1.0) {
		for (x = 0.0; x < 32.9; x += 0.1) {
			y = (sinf(0.5 * PI + (2.0 * PI * (x / 64.0)))) * f + (32.0 - f);
			if (y >= 0 && y <= 32) sinus[y] = 32 - x;
		}
		fwrite(sinus,1,32,fw);
	}

	fclose(fw);

	return 0;
}
