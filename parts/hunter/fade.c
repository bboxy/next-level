#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

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

void main() {
    unsigned int bg_col = 0;
    FILE* fr;
    FILE* fw;

    unsigned int coltab_lo = 0xe400;
    unsigned int coltab_hi = 0xe500;
    unsigned int screen = 0xe000;

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

    fr = fopen("shrine.koa", "rb");
    fgetc(fr);
    fgetc(fr);
    fread(koala, 10000, 1, fr);
    fread(&bg_col, 1, 1, fr);
    koala[10000] = bg_col;
    fclose(fr);

    fw = fopen("fade_gen.asm", "wb");

    for (a = 0; a < 1000; a++) {
        pic[a].set_cr = 0;
        pic[a].set_sc = 0;
    }
    for (y = 0; y < 25; y++) {
        for (x = 0; x < 40; x++) {
            pic[y*40+x].screen_lo = koala[8000+y*40+x] & 0x0f;
            pic[y*40+x].screen_hi = koala[8000+y*40+x] >> 4;
            pic[y*40+x].colram_lo = koala[9000+y*40+x];
            pic[y*40+x].colram_hi = -1;
            pic[y*40+x].set_cr = 1;
            pic[y*40+x].set_sc = 1;
            pic[y*40+x].x = x;
            pic[y*40+x].y = y;
        }
    }

        for (a = 0; a < 1000; a++) {
            if (pic[a].set_sc && pic[a].screen_lo != bg_col && pic[a].screen_hi == bg_col) {
                for (b = 0; b < 1000; b++) {
                    if (pic[b].screen_hi == pic[a].screen_lo) {
                        swap(koala,&pic[a]);
                    }
                }
            }
            if (pic[a].set_sc && pic[a].screen_hi != bg_col && pic[a].screen_lo == bg_col) {
                for (b = 0; b < 1000; b++) {
                    if (pic[b].screen_lo == pic[a].screen_hi) {
                        swap(koala,&pic[a]);
                    }
                }
            }
            for (b = 0; b < 1000; b++) {
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

//        ;act_lo/hi -> lo/hi erster block, if bgcol -> -1 setzen
//        ;dann block suchen der mindestens einen match hat, falls nicht farbe neu setzen und ausgeben dann block suageben
        //hi values are set more often -> better resue count this way
        //
        act_lo = bg_col;
        act_hi = bg_col;

        while (1) {
            //do we have a hit with actual colors?
            for (a = 0; a < 1000; a++) {
                if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
            }

            if (a == 1000) {
                //nope, need to find a new color
                //check if we have still blocks with a different lo color
                for (a = 0; a < 1000; a++) {
                    //block still available?
                    if (pic[a].set_sc) {
                        if (pic[a].screen_hi != act_hi && pic[a].screen_lo == act_lo) {
                            act_hi = pic[a].screen_hi;
                            if (act_hi != bg_col) {
                                fprintf(fw,"\t\tlda coltab_hi + $%04x,y\n", (act_hi << 4));
                            }
                            break;
                        }
                        if (pic[a].screen_hi == act_hi && pic[a].screen_lo != act_lo) {
                            act_lo = pic[a].screen_lo;
                            if (act_lo != bg_col) {
                                fprintf(fw,"\t\tldx coltab_lo + $%04x,y\n", (act_lo << 4));
                            }
                            break;
                        }
                    }
                }

                for (a = 0; a < 1000; a++) {
                    if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                    if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
                }

                //nope, so check colram
                if (a == 1000) {
                    for (a = 0; a < 1000; a++) {
                        if (pic[a].set_cr) {
                            if (pic[a].colram_lo != act_lo) {
                                act_lo = pic[a].colram_lo;
                                if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo + $%04x,y\n", (act_lo << 4));
                                break;
                            }
                        }
                    }
                }

                //do we now have a mach?
                for (a = 0; a < 1000; a++) {
                    if (pic[a].set_cr && pic[a].colram_lo == act_lo) break;
                    if (pic[a].set_sc && pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) break;
                }

                //this sucks, so we need to load 2 colors
                if (a == 1000) {
                    for (a = 0; a < 1000; a++) {
                        if (pic[a].set_sc == 1) break;
                    }
                    //anything available in the screen section?
                    if (a != 1000) {
                        act_lo = pic[a].screen_lo;
                        act_hi = pic[a].screen_hi;
                        if (act_hi != bg_col) fprintf(fw,"\t\tlda coltab_hi + $%04x,y\n", (act_hi << 4));
                        if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo + $%04x,y\n", (act_lo << 4));
                    } else {
                        for (a = 0; a < 1000; a++) {
                            if (pic[a].set_cr == 1) break;
                        }
                        //nope, but in the colram section?
                        if (a != 1000) {
                            act_lo = pic[a].colram_lo;
                            if (act_lo != bg_col) fprintf(fw,"\t\tldx coltab_lo + $%04x,y\n", (act_lo << 4));
                        }
                    }
                }
            }

            count = 0;
            for (a = 0; a < 1000; a++) {
                if ((pic[a].set_sc == 1) || (pic[a].set_cr == 1)) count++;
            }
            if (count==0) break;

            for (a = 0; a < 1000; a++) {
                if (pic[a].set_cr) {
                    if (pic[a].colram_lo == act_lo) {
                        if (act_lo != bg_col) {
                            fprintf(fw,"\t\tstx $%04x\n", 0xd800 +pic[a].y*40+pic[a].x);
                        }
                        pic[a].set_cr = 0;
                    }
                }
            }
            for (a = 0; a < 1000; a++) {
                if (pic[a].set_sc) {
                    if ((pic[a].screen_lo == act_lo && pic[a].screen_hi == act_hi) || (pic[a].screen_lo == bg_col && pic[a].screen_hi == act_hi) || (pic[a].screen_lo == act_lo && pic[a].screen_hi == bg_col)) {
                        if (pic[a].screen_lo == bg_col && pic[a].screen_hi == bg_col) {
                        } else {
                            fprintf(fw,"\t\tsax screen + $%04x\n", a);
                        }
                        pic[a].set_sc = 0;
                    }
                }
            }
        }
        fprintf(fw,"\t\trts\n");


//    fprintf(fw,"\t\t!byte $%02x,$%02x,$%02x,$%02x\n", d021[a],d021[a],d021[a],d021[a]);
    fclose(fw);
    fw = fopen("clean.kla", "wb");
    fputc(0x00,fw);
    fputc(0x40,fw);
    fwrite(koala, 10001, 1, fw);
    fclose(fw);
}
