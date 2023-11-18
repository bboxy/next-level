#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#define	HIRES		1
#define STARTROW	0
#define LASTROW		10

#define ARRAY_ELEMS(a) (sizeof(a) / sizeof((a)[0]))
typedef struct cell {
    int screen_lo;
    int screen_hi;
    int colram_lo;
    int colram_hi;
    int x;
    int y;
    char set_cr;
    char set_sc;
} cell;

void swap (unsigned char* koala, cell* pica) {
    int a;
    int x,y;
    unsigned char bits;
    unsigned char sbyte;
    unsigned char dbyte;

    unsigned char* block = koala + (pica->y*40+pica->x)*8;
    unsigned char* screen = koala + 8000 + pica->y*40+pica->x;

    a = pica->screen_lo;
    pica->screen_lo = pica->screen_hi;
    pica->screen_hi = a;

    screen[0] = pica->screen_hi | (pica->screen_lo << 4);
    for (y = 0; y < 8; y++) {
        sbyte = block[y];
        for (x = 0; x < 8; x += 2) {
            bits = sbyte & 3;
            sbyte = sbyte >> 2;
            switch (bits) {
                case 0:
                break;
                case 1:
                    bits = 2;
                break;
                case 2:
                    bits = 1;
                break;
                case 3:
                break;
            }
            dbyte = dbyte >> 2;
            dbyte |= (bits << 6);
        }
        block[y] = dbyte;
    }
}

int main() {
    int mem = 0;
    unsigned int bg_col = 0;
    FILE* fr;
    FILE* fw;

    unsigned char koala[10001];
    cell pic[1000];

    int x,y,a,b;
    int stat_screen_lo[16];
    int stat_screen_hi[16];
    int stat_colram_lo[16];

    int lo, hi;
    int num_hi, num_lo;

    int hit_screen;
    int hit_colram;

    int act_lo, act_hi;

    int col;

    int count;
    int num_lines = 0;

    fr = fopen("hill.prg", "rb");
    fgetc(fr);
    fgetc(fr);
    if (HIRES) {
        fread(koala, 9000, 1, fr);
    } else {
        fread(koala, 10000, 1, fr);
    	fread(&bg_col, 1, 1, fr);
    }
    koala[10000] = bg_col;
    fclose(fr);

    fw = fopen("fade_gen.asm", "wb");

    //fprintf(fw,"jmp_tab\n");
    for (a = 0; a < 1000; a++) {
        pic[a].set_cr = 0;
        pic[a].set_sc = 0;
    }
    for (y = STARTROW; y < LASTROW; y++) {
        for (x = 0; x < 40; x++) {
            pic[y*40+x].screen_lo = koala[8000+y*40+x] & 0x0f;
            pic[y*40+x].screen_hi = koala[8000+y*40+x] >> 4;
            if (!HIRES) {
                pic[y*40+x].colram_lo = koala[9000+y*40+x];
                pic[y*40+x].colram_hi = -1;
            }
            if (!HIRES) pic[y*40+x].set_cr = 1;
            else pic[y*40+x].set_cr = 0;
            pic[y*40+x].set_sc = 1;
            pic[y*40+x].x = x;
            pic[y*40+x].y = y;
        }
    }

    if (HIRES) bg_col = -1;

    for (a = STARTROW * 40; a < LASTROW * 40; a++) {
        if (pic[a].set_sc && pic[a].screen_lo != bg_col && pic[a].screen_hi == bg_col) {
            for (b = STARTROW * 40; b < LASTROW * 40; b++) {
                if (pic[b].screen_hi == pic[a].screen_lo) {
                    swap(koala,&pic[a]);
                }
            }
        }
        if (pic[a].set_sc && pic[a].screen_hi != bg_col && pic[a].screen_lo == bg_col) {
            for (b = STARTROW * 40; b < LASTROW * 40; b++) {
                if (pic[b].screen_lo == pic[a].screen_hi) {
                    swap(koala,&pic[a]);
                }
            }
        }
        for (b = STARTROW * 40; b < LASTROW * 40; b++) {
            if (pic[a].set_sc && pic[b].set_cr && pic[a].screen_lo == pic[b].colram_lo) swap(koala,&pic[a]);
            if (pic[a].set_sc && pic[b].set_cr && pic[a].screen_hi == pic[a].colram_lo) swap(koala,&pic[a]);
        }
    }
//        if (y == 0) {
//            for (x = 0; x < 40; x++) {
//            printf("$%02x  $%02x\n",pic[x].screen_lo|(pic[x].screen_hi<<4),pic[x].colram_lo);
//            }
//        }
//        //clear stats
//        memset(stat_screen_lo,0,16);
//        memset(stat_screen_hi,0,16);
//        memset(stat_colram_lo,0,16);
//
//        //sum up stats over all used blocks of this run
//        for (a = 0; a < 1000; a++) {
//            if (pic[a].set_cr) {
//                if(pic[a].screen_lo > 0) stat_screen_lo[pic[a].screen_lo]++;
//                if(pic[a].screen_hi > 0) stat_screen_hi[pic[a].screen_hi]++;
//                if(pic[a].colram_lo > 0) stat_colram_lo[pic[a].colram_lo]++;
//            }
//        }
//
//        num_hi = 0;
//        num_lo = 0;
//
//        //which nibbles are used more, hi or low?
//        for (a = 0; a < 16; a++) if (stat_screen_hi[a] > 0) num_hi++;
//        for (a = 0; a < 16; a++) if (stat_screen_lo[a] > 0) num_lo++;
//        for (a = 0; a < 16; a++) if (stat_colram_lo[a] > 0) num_lo++;
//
//        fprintf(fw,"row%02d\n", y);

//        ;act_lo/hi -> lo/hi erster block, if bgcol -> -1 setzen
//        ;dann block suchen der mindestens einen match hat, falls nicht farbe neu setzen und ausgeben dann block suageben
        //hi values are set more often -> better resue count this way
        //
        act_lo = bg_col;
        act_hi = bg_col;

        while (1) {
            //do we have a hit with actual colors?
            for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
            }

            if (a == LASTROW * 40) {
                //nope, need to find a new color
                //check if we have still blocks with a different lo color
                for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                    //block still available?
                    if (pic[a].set_sc) {
                        if (pic[a].screen_hi != act_hi && pic[a].screen_lo == act_lo) {
                            act_hi = pic[a].screen_hi;
                            if (act_hi != bg_col) {
                                fprintf(fw,"\t\tlda coltab_hi_%x,y\n", act_hi);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                            }
                            break;
                        }
                        if (pic[a].screen_hi == act_hi && pic[a].screen_lo != act_lo) {
                            act_lo = pic[a].screen_lo;
                            if (act_lo != bg_col) {
                                fprintf(fw,"\t\tldx coltab_lo_%x,y\n", act_lo);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                            }
                            break;
                        }
                    }
                }

                for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                    if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                    if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
                }

                //nope, so check colram
                if (a == LASTROW * 40) {
                    for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                        if (pic[a].set_cr) {
                            if (pic[a].colram_lo != act_lo) {
                                act_lo = pic[a].colram_lo;
                                if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo_%x,y\n", act_lo);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                                break;
                            }
                        }
                    }
                }

                //do we now have a mach?
                for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                    if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                    if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
                }

                //this sucks, so we need to load 2 colors
                if (a == LASTROW * 40) {
                    for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                        if (pic[a].set_sc == 1) break;
                    }
                    //anything available in the screen section?
                    if (a != LASTROW * 40) {
                        act_lo = pic[a].screen_lo;
                        act_hi = pic[a].screen_hi;
                        if (act_hi != bg_col) fprintf(fw,"\t\tlda coltab_hi_%x,y\n", act_hi);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
				} else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                        if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo_%x,y\n", act_lo);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                    } else {
                        for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                            if (pic[a].set_cr == 1) break;
                        }
                        //nope, but in the colram section?
                        if (a != LASTROW * 40) {
                            act_lo = pic[a].colram_lo;
                            if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo_%x,y\n", act_lo);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                        }
                    }
                }
            }

            count = 0;
            for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                if ((pic[a].set_sc == 1) || (pic[a].set_cr == 1)) count++;
            }
            if (count==0) break;

            for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                if (pic[a].set_cr) {
                    if (pic[a].colram_lo == act_lo) {
                        if (act_lo != bg_col) {
                            fprintf(fw,"\t\tstx $%04x\n", 0xd800 +pic[a].y*40+pic[a].x);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                        }
                        pic[a].set_cr = 0;
                    }
                }
            }

            for (a = STARTROW * 40; a < LASTROW * 40; a++) {
                if (pic[a].set_sc) {
                    if ((pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) || (pic[a].screen_lo == bg_col && pic[a].screen_hi == act_hi) || (pic[a].screen_lo == act_lo && pic[a].screen_hi == bg_col)) {
                        if (pic[a].screen_lo == bg_col && pic[a].screen_hi == bg_col) {
                        } else {
                            fprintf(fw,"\t\tsax screen + $%04x\n", a);
				mem +=3;
				if ((mem & 0x3ff) == 0x27b) {
					fprintf(fw,"\t\tjmp * + $2d\n");
					fprintf(fw,"!fill $2a,$00\n");
					mem += 0x2d;
                                } else if ((mem & 7) == 6) {
                                    fprintf(fw,"\t\tdop #$00\n");
                                    mem +=2;
                                }
                        }
                        pic[a].set_sc = 0;
                    }
                }
            }
        }
        fprintf(fw,"\t\trts\n");


//    fprintf(fw,"\t\t!byte $%02x,$%02x,$%02x,$%02x\n", d021[a],d021[a],d021[a],d021[a]);
    fclose(fw);
    fw = fopen("clean.prg", "wb");
    fputc(0x00,fw);
    fputc(0x40,fw);
    if (HIRES) {
        fwrite(koala, 9000, 1, fw);
    } else {
        fwrite(koala, 10001, 1, fw);
    }
    fclose(fw);
}
