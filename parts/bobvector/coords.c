#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <math.h>

#define NUMPLOTS	98
#define FRAMES		146
#define DEGREES		128
#define SIZES		11

#define SCREEN1		0xcc00
#define SCREEN2		0xf000

int offsets[SIZES][8] = { 0 };
int pointers[SIZES][8] = { 0 };
int numcols[SIZES][8] = { 0 };

/*
static const unsigned int bobs[] = {
//bob_1_0
		0b10000000,

//bob_2_0
		0b11000000,
		0b11000000,

//bob_3_0
		0b01000000,
		0b11100000,
		0b01000000,

//bob_4_0
		0b01100000,
		0b11110000,
		0b11110000,
		0b01100000,

//bob_5_0
		0b01110000,
		0b11111000,
		0b11111000,
		0b11111000,
		0b01110000,

//bob_6_0
		0b01111000,
		0b11111100,
		0b11111100,
		0b11111100,
		0b11111100,
		0b01111000,

//bob_7_0
		0b00111000,
		0b01111100,
		0b11111110,
		0b11111110,
		0b11111110,
		0b01111100,
		0b00111000,

//bob_8_0
		0b00111100,
		0b01111110,
		0b11111111,
		0b11111111,
		0b11111111,
		0b11111111,
		0b01111110,
		0b00111100,

//bob_9_0
		0b0011111000000000,// & 0xbbbbbbbb,
		0b0111111100000000,// & 0xeeeeeeee,
		0b1111111110000000,// & 0xbbbbbbbb,
		0b1111111110000000,// & 0xeeeeeeee,
		0b1111111110000000,// & 0xbbbbbbbb,
		0b1111111110000000,// & 0xeeeeeeee,
		0b1111111110000000,// & 0xbbbbbbbb,
		0b0111111100000000,// & 0xeeeeeeee,
		0b0011111000000000,// & 0xbbbbbbbb,

//bob_10_0
		0b0001111000000000,// & 0xaaaaaaaa,
		0b0011111100000000,// & 0x55555555,
		0b0111111110000000,// & 0xaaaaaaaa,
		0b1111111111000000,// & 0x55555555,
		0b1111111111000000,// & 0xaaaaaaaa,
		0b1111111111000000,// & 0x55555555,
		0b1111111111000000,// & 0xaaaaaaaa,
		0b0111111110000000,// & 0x55555555,
		0b0011111100000000,// & 0xaaaaaaaa,
		0b0001111000000000,// & 0x55555555,

//bob_11_0
		0b0001111100000000,// & 0x44444444,
		0b0011111110000000,// & 0x11111111,
		0b0111111111000000,// & 0x44444444,
		0b1111111111100000,// & 0x11111111,
		0b1111111111100000,// & 0x44444444,
		0b1111111111100000,// & 0x11111111,
		0b1111111111100000,// & 0x44444444,
		0b1111111111100000,// & 0x11111111,
		0b0111111111000000,// & 0x44444444,
		0b0011111110000000,// & 0x11111111,
		0b0001111100000000,// & 0x44444444
};
*/

const float cube[NUMPLOTS][3] = {

	{-0.50, 1.00,-0.50},
	{-0.00, 1.00,-0.50},
	{ 0.50, 1.00,-0.50},

	{-0.50, 1.00,-0.00},
	{-0.00, 1.00,-0.00},
	{ 0.50, 1.00,-0.00},

	{-0.50, 1.00, 0.50},
	{-0.00, 1.00, 0.50},
	{ 0.50, 1.00, 0.50},


	{-0.50,-1.00,-0.50},
	{-0.00,-1.00,-0.50},
	{ 0.50,-1.00,-0.50},

	{-0.50,-1.00,-0.00},
	{-0.00,-1.00,-0.00},
	{ 0.50,-1.00,-0.00},

	{-0.50,-1.00, 0.50},
	{-0.00,-1.00, 0.50},
	{ 0.50,-1.00, 0.50},


	{-1.00,-1.00,-1.00},
	{-0.50,-1.00,-1.00},
	{-0.00,-1.00,-1.00},
	{ 0.50,-1.00,-1.00},

	{ 1.00,-1.00,-1.00},
	{ 1.00,-1.00,-0.50},
	{ 1.00,-1.00,-0.00},
	{ 1.00,-1.00, 0.50},

	{ 1.00,-1.00, 1.00},
	{ 0.50,-1.00, 1.00},
	{ 0.00,-1.00, 1.00},
	{-0.50,-1.00, 1.00},

	{-1.00,-1.00, 1.00},
	{-1.00,-1.00, 0.50},
	{-1.00,-1.00,-0.00},
	{-1.00,-1.00,-0.50},


	{-1.00, 1.00,-1.00},
	{-0.50, 1.00,-1.00},
	{-0.00, 1.00,-1.00},
	{ 0.50, 1.00,-1.00},

	{ 1.00, 1.00,-1.00},
	{ 1.00, 1.00,-0.50},
	{ 1.00, 1.00,-0.00},
	{ 1.00, 1.00, 0.50},

	{ 1.00, 1.00, 1.00},
	{ 0.50, 1.00, 1.00},
	{ 0.00, 1.00, 1.00},
	{-0.50, 1.00, 1.00},

	{-1.00, 1.00, 1.00},
	{-1.00, 1.00, 0.50},
	{-1.00, 1.00,-0.00},
	{-1.00, 1.00,-0.50},


	{-1.00, 0.50,-1.00},
	{-0.50, 0.50,-1.00},
	{-0.00, 0.50,-1.00},
	{ 0.50, 0.50,-1.00},

	{ 1.00, 0.50,-1.00},
	{ 1.00, 0.50,-0.50},
	{ 1.00, 0.50,-0.00},
	{ 1.00, 0.50, 0.50},

	{ 1.00, 0.50, 1.00},
	{ 0.50, 0.50, 1.00},
	{ 0.00, 0.50, 1.00},
	{-0.50, 0.50, 1.00},

	{-1.00, 0.50, 1.00},
	{-1.00, 0.50, 0.50},
	{-1.00, 0.50,-0.00},
	{-1.00, 0.50,-0.50},

	{-1.00, 0.00,-1.00},
	{-0.50, 0.00,-1.00},
	{-0.00, 0.00,-1.00},
	{ 0.50, 0.00,-1.00},

	{ 1.00, 0.00,-1.00},
	{ 1.00, 0.00,-0.50},
	{ 1.00, 0.00,-0.00},
	{ 1.00, 0.00, 0.50},

	{ 1.00, 0.00, 1.00},
	{ 0.50, 0.00, 1.00},
	{ 0.00, 0.00, 1.00},
	{-0.50, 0.00, 1.00},

	{-1.00, 0.00, 1.00},
	{-1.00, 0.00, 0.50},
	{-1.00, 0.00,-0.00},
	{-1.00, 0.00,-0.50},

	{-1.00,-0.50,-1.00},
	{-0.50,-0.50,-1.00},
	{-0.00,-0.50,-1.00},
	{ 0.50,-0.50,-1.00},

	{ 1.00,-0.50,-1.00},
	{ 1.00,-0.50,-0.50},
	{ 1.00,-0.50,-0.00},
	{ 1.00,-0.50, 0.50},

	{ 1.00,-0.50, 1.00},
	{ 0.50,-0.50, 1.00},
	{ 0.00,-0.50, 1.00},
	{-0.50,-0.50, 1.00},

	{-1.00,-0.50, 1.00},
	{-1.00,-0.50, 0.50},
	{-1.00,-0.50,-0.00},
	{-1.00,-0.50,-0.50},
};

typedef struct plot {
	int x;
	int y;
	int size;
	unsigned int addr;
} plot;

int compare(const void *s1, const void *s2) {
	plot *e1 = (plot *)s1;
	plot *e2 = (plot *)s2;
        if (e1->addr > e2->addr) return -1;
        else if (e1->addr < e2->addr) return 1;
        return (e1->x & 7) - (e2->x & 7);
}

int main() {
        int stats[256] = { 0 };
	int last_lo, last_off;
	int first;
        //int off;
        //int lo;
	//int addr;

	float stars_x;
	float stars_y;
	float stars_z;

	float d = 1.5;
	float scale = 0.0;//0.45;

	int fx[NUMPLOTS][FRAMES] = {{ 0 }};
	int fy[NUMPLOTS][FRAMES] = {{ 0 }};
	int fs[NUMPLOTS][FRAMES] = {{ 0 }};

	plot plots[NUMPLOTS] = { 0 };

	int x,y;

	float deg_x;
	float deg_y;
	float deg_z;

//	int shift;
	int size;
//	int colum;
//	int w;

//	int l;
	int b;
//	int s;

//	int ps;

	int px,py;
	int n;

	FILE* st_lo;
	FILE* st_off;
	FILE* st_poi;

	st_lo  = fopen("stream_lo.asm", "wb");
	st_off = fopen("stream_off.asm", "wb");
	st_poi = fopen("stream_poi.asm", "wb");


	float cx,cy,cz,cx_,cy_,cz_;

	float depth = -1.8;
        int addr;
        int xand7;
        int yand7;

//	for (shift = 0; shift < 8; shift++) {
//		b = 0;
//		for (size = 0; size < SIZES; size++) {
//			printf("bob_%d_%d\n",size,shift);
//			w = ((size + shift) / 8);
//			if (w > size / 8) {
//				ps = 8;
//			} else {
//				ps = 0;
//			}
//			for (colum = w; colum >= 0; colum--) {
//				pointers[size][shift] = b;
//				numcols[size][shift] = w;
//				for (y = 0; y <= size; y++) {
//					l = bobs[b + y];
//					l <<= ps;
//					l >>= shift;
//					printf("	!byte $%02x\n", ((l >> (colum * 8) & 0xff) ^ 0x00));
//				}
//				if (colum != 0) printf("\n");
//			}
//			b += (size + 1);
//		}
//	}
//
//	printf("\n");
//	printf("data\n");

	for (b = 0; b < FRAMES; b++) {
		for (x = 0; x < NUMPLOTS; x++) {
			//choose a position on y axis from 0.2 .. 1.0
			deg_x = (2.0 * M_PI) * 1.0 * (b % DEGREES) / DEGREES;
			deg_y = (2.0 * M_PI) * 1.0 * (b % DEGREES) / DEGREES;
			deg_z = (2.0 * M_PI) * 2.0 * (b % DEGREES) / DEGREES;

			//rotate this shit
			cx_ = cube[x][0] * cosf(deg_z) - cube[x][1] * sinf(deg_z);
			cy_ = cube[x][0] * sinf(deg_z) + cube[x][1] * cosf(deg_z);

			cx = cx_;
			cy = cy_;

			cy_ = cy * cosf(deg_y) - cube[x][2] * sinf(deg_y);
			cz_ = cy * sinf(deg_y) + cube[x][2] * cosf(deg_y);

			cy = cy_;
			cz = cz_;

			cx_ = cz * sinf(deg_x) + cx * cosf(deg_x);
			cz_ = cz * cosf(deg_x) - cx * sinf(deg_x);

			stars_x = cx_ * scale;// + (sinf(deg_y) / 2.25);
			stars_y = cy_ * scale;
			stars_z = (cz_ + depth) * scale;

			fs[x][b] = (stars_z + 1.0) * 6.0 - 2.0;
			fx[x][b] = ((((stars_x / (1.0 - (stars_z / d))) + 1.0) * 100.0) - ((float)fs[x][b] / 2.0)) + 0.5 + 4.0;
			fy[x][b] = ((((stars_y / (1.0 - (stars_z / d))) + 1.0) * 100.0) - ((float)fs[x][b] / 2.0)) + 0.5;
		}
		if (scale < 0.45) scale += 0.025;
		if (depth < 0.00) depth += 0.1;
	}

	last_lo = 0;
	last_off = 0;
        for (y = 0; y < FRAMES; y++) {
		fprintf(st_lo,".frame_lo%03d\n", y);
		fprintf(st_off,".frame_off%03d\n", y);
		fprintf(st_poi,".frame_poi%03d\n", y);
		for (x = 0; x < NUMPLOTS; x++) {
			plots[x].x    = fx[x][y];
			plots[x].y    = fy[x][y];
			plots[x].size = fs[x][y];
			plots[x].addr = (plots[x].y >> 3) * 40 + (plots[x].x >> 3) + 14;
		}
		qsort((void*)plots, NUMPLOTS, sizeof(plots[0]), compare);
		for (size = 0; size < 9; size++) {
			n = 0;
			for (x = 0; x < NUMPLOTS; x++) {
				px = plots[x].x;
				py = plots[x].y;
				if (plots[x].size == size) {
					if (px > 0 && px < (320 - size - 1) && py > 0 && py < (199 - size - 1)) {
						n++;
					}
				}
			}
			fprintf(st_poi,"!byte $%02x\n", n);
			if (n) {
				//fprintf(st_poi,"!byte $%02x\n", size + 1);
				//fprintf(st_poi,"!byte $%02x\n", n);
				for (x = 0; x < NUMPLOTS; x++) {
					px = plots[x].x;
					py = plots[x].y;
					if (plots[x].size == size) {
						//if (px > 0 && px < (319 - size) && py >= 0 && py < (199 - size)) {
							//addr = (py >> 3) * 40 + (px >> 3) + 7;
                                                        //lo = addr & 255;
                                                        //off = ((addr >> 2) & 0xc0) | ((py & 7) << 0) | ((px & 7) << 3);
                                                        stats[px]++;

							fprintf(st_lo,"!byte $%02x\n", (plots[x].addr >> 2) & 0xff);
							fprintf(st_off,"!byte $%02x\n", ((plots[x].addr << 6) | ((plots[x].x & 7) << 3) | (plots[x].y & 7)) & 0xff);

							//last_lo =  (plots[x].addr >> 2) & 0xff;
							//last_off = ((plots[x].addr << 6) | ((plots[x].x & 7) << 3) | (plots[x].y & 7)) & 0xff;

							//fprintf(st_lo,"!byte $%02x\n", lo);
							//fprintf(st_off,"!byte $%02x\n", off);
							//if (addr == 0 && (((addr >> 2) & 0xc0) | ((plots[x].y & 7) << 0) | ((plots[x].x & 7) << 3)) == 0) printf("ficken\n");
						//}
					}
				}
			}
		}
		//fprintf(st_poi,"!byte $%02x\n", 0);
	}
        //for (y = 0; y < 256; y++) {
        //    printf("$%04x ", stats[y]);
        //    if ((y & 0xf) == 0xf) printf("\n");
        //}
	fclose(st_lo);
	fclose(st_off);
	fclose(st_poi);
	return 0;
}
