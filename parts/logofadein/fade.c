#include <math.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#define MC	0
#define COLRAM	1

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

    screen[0] = pica->screen_hi << 4 | (pica->screen_lo);
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

int has_pixels(unsigned char* koala, int mode) {
    int y;
    int x;
    int res = 0;
    unsigned char byte;
    for (y = 0; y < 8; y++) {
        byte = koala[y];
        for (x = 0; x < 8; x += 2) {
           if ((byte & 3) == mode) res = 1;
           byte >>= 2;
        }
    }
    return res;
}

static int read_number(char* arg, char* argname, int limit) {
    int number;
    if (arg != NULL && arg[0] == '$') number = strtoul(arg + 1, NULL, 16);
    else if (arg != NULL && arg[0] == '0' && arg[1] == 'x') number = strtoul(arg + 2, NULL, 16);
    else if (arg != NULL && arg[0] >= '0' && arg[0] <= '9') number = strtoul(arg, NULL, 10);
    else {
        fprintf(stderr, "Error: no valid number given for argument %s (given value is: '%s')\n", argname, arg);
        exit(1);
    }
    if (number < 0 || number > limit) {
        fprintf(stderr, "Error: Number '%s' out of range (0 - 65536)\n", arg);
        exit(1);
    }
    return number;
}

int main(int argc, char* argv[]) {
    char* input_name = NULL;
    char* output_name = NULL;
    char* fade_name = NULL;
    char* map_name = NULL;
    char* label = NULL;
    unsigned int bg_col = 0xa;
    FILE* fr = NULL;
    FILE* fw = NULL;
    FILE* mr = NULL;

    unsigned char koala[10001];
    unsigned char map[1000] = { 0 };
    cell pic[1000];
    cell cells[1000];

    int x,y,a,b;
    int mc1, mc2, colram;

    int act_lo, act_hi;
    int tgt_col = 0;
    int single_col = -1;

    int count;
    int i;

    int current_num = 0;
    int num_blocks = 0;
    int max_num = 0;
    int hires = 0;

    //XXX TODO add -h switch for hires support (in fact do not use bg_col but any block counts? disable colram stuff but setting whole colram to not used?)
    for (i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-", 1) || !strncmp(argv[i], "--", 2)) {
            if (!strcmp(argv[i], "-o")) {
                i++;
                output_name = argv[i];
            } else if (!strcmp(argv[i], "-f")) {
                i++;
                fade_name = argv[i];
            } else if (!strcmp(argv[i], "-m")) {
                i++;
                map_name = argv[i];
            } else if (!strcmp(argv[i], "-c")) {
                single_col = read_number(argv[i + 1], argv[i], 15);
                i++;
            } else if (!strcmp(argv[i], "-t")) {
                tgt_col = read_number(argv[i + 1], argv[i], 15);
                i++;
            } else if (!strcmp(argv[i], "-l")) {
                i++;
                label = argv[i];
            } else if (!strcmp(argv[i], "-h")) {
                hires = 1;
            } else {
                fprintf(stderr, "Error: Unknown option %s\n", argv[i]);
                exit(1);
            }
        } else if (i == argc - 1) {
            input_name = argv[i];
        } else {
            fprintf(stderr, "Error: Unknown option %s\n", argv[i]);
            exit(1);
        }
    }

    if (argc == 1) {
        printf("fade-generator for koala by Bitbreaker/Performers\n");
        fprintf(stderr, "Usage: %s [options] input\n"
                        "  -o [filename]               Set filename for output koala\n"
                        "  -f [filename]               Set filename for generated .asm\n"
                        "  -l [name]                   Name of lookup-labels being used in generated .asm\n"
                        "  -t [num]                    Target color of color fade to cease out unchanged blocks\n"
                        "  -c [num]                    Only pick specfic color for fade\n"
                        "  -h                          Use hires mode\n"
                        "  -m [name]                   Use given map for providing a fade pattern (default: whole screen at once)\n"
                        ,argv[0]);
        exit(1);
    }

    if (!input_name) {
        fprintf(stderr, "Error: No input name given\n");
        exit(1);
    }
    if (!output_name) {
        fprintf(stderr, "Error: No output name given\n");
        exit(1);
    }
    if (!fade_name) {
        fprintf(stderr, "Error: No fade name given\n");
        exit(1);
    }
    if (map_name) {
        mr = fopen(map_name, "rb");
        if (!mr) {
            fprintf(stderr, "Error: Can't open map file\n");
            exit(1);
        }
        if ((a = fread(map, 1, 1000, mr)) != 1000) {
            fprintf(stderr, "Error: Can't read 1000 bytes from map (%d bytes read)\n", a);
            exit(1);
        }
        fclose(mr);
    }

    max_num = 0;
    for (a = 0; a < 1000; a++) {
        if (map[a] > max_num) max_num = map[a];
    }

    fr = fopen(input_name, "rb");
    fgetc(fr);
    fgetc(fr);
    fread(koala, 1, 10000, fr);
    fread(&bg_col, 1, 1, fr);
    if (hires) bg_col = -1;
    koala[10000] = bg_col;
    fclose(fr);

    fw = fopen(fade_name, "wb");

    for (a = 0; a < 1000; a++) {
        pic[a].set_cr = 0;
        pic[a].set_sc = 0;
    }
    for (y = 0; y < 25; y++) {
        for (x = 0; x < 40; x++) {
            mc1 = koala[8000+y*40+x] & 0x0f;
            mc2 = koala[8000+y*40+x] >> 4;
            colram = koala[9000+y*40+x] & 0xf;

            pic[y * 40 + x].screen_lo = mc1;
            pic[y * 40 + x].screen_hi = mc2;
            pic[y * 40 + x].colram_lo = colram;
            pic[y * 40 + x].colram_hi = -1;

            if (hires || (has_pixels(koala + y * 320 + x * 8, 2) && mc1 != tgt_col)) {
                pic[y * 40 + x].set_sc = 1;
            } else {
                koala[8000 + y * 40 + x] &= 0xf0;
            }
            if (hires || (has_pixels(koala + y * 320 + x * 8, 1) && mc2 != tgt_col)) {
                pic[y * 40 + x].set_sc = 1;
            } else {
                koala[8000 + y * 40 + x] &= 0x0f;
            }
            if (has_pixels(koala + y * 320 + x * 8, 3) && colram != tgt_col) {
                if (!hires) pic[y * 40 + x].set_cr = 1;
            } else {
                koala[9000 + y * 40 + x] = 0;
            }
            pic[y * 40 + x].x = x;
            pic[y * 40 + x].y = y;
        }
    }

    if (!hires) {
        for (a = 0; a < 1000; a++) {
            if (pic[a].set_sc && pic[a].screen_lo != bg_col && pic[a].screen_hi == bg_col) {
                for (b = 0; b < 1000; b++) {
                    if (pic[b].screen_hi == pic[a].screen_lo) {
                        swap(koala, &pic[a]);
                    }
                }
            }
            if (pic[a].set_sc && pic[a].screen_hi != bg_col && pic[a].screen_lo == bg_col) {
                for (b = 0; b < 1000; b++) {
                    if (pic[b].screen_lo == pic[a].screen_hi) {
                        swap(koala, &pic[a]);
                    }
                }
            }
            for (b = 0; b < 1000; b++) {
                if (pic[a].set_sc && pic[b].set_cr && pic[a].screen_lo == pic[b].colram_lo) swap(koala, &pic[a]);
                if (pic[a].set_sc && pic[b].set_cr && pic[a].screen_hi == pic[a].colram_lo) swap(koala, &pic[a]);
            }
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
    //XXX TODO for column mode do x = 0 .. 39 here and make check on column by a % 40 == x, do this as a wrapper inside all loops, with switch for columnwise, also write out a label per column and a rts per column
    //even better, check for a map that has a pattern after which zu separate? -> check each hit in map if current value? -> for standard mode map is all 0
    for (current_num = 0; current_num <= max_num; current_num++) {
        num_blocks = 0;
        for (a = 0; a < 1000; a++) {
            if (map[a] == current_num) {
                if (single_col < 0) {
                    cells[num_blocks++] = pic[a];
                } else {
                    //any hit in colors?
                    if (single_col == pic[a].screen_lo || single_col == pic[a].screen_hi || single_col == pic[a].colram_lo) {
                        //disable use of colram if not matching
                        if (single_col != pic[a].colram_lo) pic[a].set_cr = 0;
                        //disable use of screen if not matching
                        if (single_col != pic[a].screen_lo && single_col != pic[a].colram_hi) pic[a].set_sc = 0;
                        cells[num_blocks++] = pic[a];
                    }
                }
            }
        }
        fprintf(fw, "area_%s_%03x\n", label, current_num);

        act_lo = bg_col;
        act_hi = bg_col;

    //XXX TODO do stats, those colors taht cross with most other colors will be done first? -> lda/ldx color most and the nall other colors that cross with it? needs also be done per map? if doing the map approach see that the count is >= 1
        while (1) {
            //do we have a hit with actual colors?
            for (a = 0; a < num_blocks; a++) {
                if (cells[a].set_cr && cells[a].colram_lo == act_lo) break;
                if (cells[a].set_sc && cells[a].screen_lo == act_lo && cells[a].screen_hi == act_hi) break;
            }

            if (a == num_blocks) {
                //nope, need to find a new color
                //check if we have still blocks with a different lo color
                for (a = 0; a < num_blocks; a++) {
                    //block still available?
                    if (cells[a].set_sc) {
                        if (cells[a].screen_hi != act_hi && cells[a].screen_lo == act_lo) {
                            act_hi = cells[a].screen_hi;
                            if (act_hi != bg_col) {
                                fprintf(fw,"\t\tlda %s_hi_%1x,y\n", label, act_hi);
                            }
                            break;
                        }
                        if (cells[a].screen_hi == act_hi && cells[a].screen_lo != act_lo) {
                            act_lo = cells[a].screen_lo;
                            if (act_lo != bg_col) {
                                fprintf(fw,"\t\tldx %s_lo_%1x,y\n", label, act_lo);
                            }
                            break;
                        }
                    }
                }

                for (a = 0; a < num_blocks; a++) {
                    if (cells[a].set_cr && cells[a].colram_lo == act_lo) break;
                    if (cells[a].set_sc && cells[a].screen_lo == act_lo && cells[a].screen_hi == act_hi) break;
                }

                //nope, so check colram
                if (a == num_blocks) {
                    for (a = 0; a < num_blocks; a++) {
                        if (cells[a].set_cr) {
                            if (cells[a].colram_lo != act_lo) {
                                act_lo = cells[a].colram_lo;
                                if (act_lo != bg_col) fprintf(fw,"\t\tldx %s_lo_%1x,y\n", label, act_lo);
                                break;
                            }
                        }
                    }
                }

                //do we now have a mach?
                for (a = 0; a < num_blocks; a++) {
                    if (cells[a].set_cr && cells[a].colram_lo == act_lo) break;
                    if (cells[a].set_sc && cells[a].screen_lo == act_lo && cells[a].screen_hi == act_hi) break;
                }

                //this sucks, so we need to load 2 colors
                if (a == num_blocks) {
                    for (a = 0; a < num_blocks; a++) {
                        if (cells[a].set_sc == 1) break;
                        }
                    //anything available in the screen section?
                    if (a != num_blocks) {
                    act_lo = cells[a].screen_lo;
                        act_hi = cells[a].screen_hi;
                        if (act_hi != bg_col) fprintf(fw,"\t\tlda %s_hi_%1x,y\n", label, act_hi);
                        if (act_lo != bg_col) fprintf(fw,"\t\tldx %s_lo_%1x,y\n", label, act_lo);
                    } else {
                        for (a = 0; a < num_blocks; a++) {
                            if (cells[a].set_cr == 1) break;
                        }
                        //nope, but in the colram section?
                        if (a != num_blocks) {
                            act_lo = cells[a].colram_lo;
                            if (act_lo != bg_col) fprintf(fw,"\t\tldx %s_lo_%1x,y\n", label, act_lo);
                        }
                    }
                }
            }

            count = 0;
            for (a = 0; a < num_blocks; a++) {
                if ((cells[a].set_sc == 1) || (cells[a].set_cr == 1)) count++;
            }
            if (count==0) break;

            for (a = 0; a < num_blocks; a++) {
                if (cells[a].set_cr) {
                    if (cells[a].colram_lo == act_lo) {
                        if (act_lo != bg_col) {
                            fprintf(fw,"\t\tstx $%04x\n", 0xd800 + cells[a].y * 40 + cells[a].x);
                        }
                        cells[a].set_cr = 0;
                    }
                }
            }
            for (a = 0; a < num_blocks; a++) {
                if (cells[a].set_sc) {
                    if ((cells[a].screen_lo == act_lo && cells[a].screen_hi == act_hi) || (cells[a].screen_lo == bg_col && cells[a].screen_hi == act_hi) || (cells[a].screen_lo == act_lo && cells[a].screen_hi == bg_col)) {
                        if (cells[a].screen_lo == bg_col && cells[a].screen_hi == bg_col) {
                        } else {
                            fprintf(fw,"\t\tsax screen + $%04x\n", cells[a].y * 40 + cells[a].x);
                        }
                        cells[a].set_sc = 0;
                    }
                }
            }
        }
        fprintf(fw,"\t\trts\n");
    }


//    fprintf(fw,"\t\t!byte $%02x,$%02x,$%02x,$%02x\n", d021[a],d021[a],d021[a],d021[a]);
    fclose(fw);
    fw = fopen(output_name, "wb");
    fputc(0x00,fw);
    fputc(0x40,fw);
    if (!hires) fwrite(koala, 1, 10001, fw);
    else fwrite(koala, 1, 9000, fw);
    fclose(fw);
    return 0;
}
