#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>

//keep last spriterowdata and only copy new 20, 19, 18, 17 lines into convertbuffer?

//21 lines to copy, 0 from gfx
//20 lines to copy, line 20 from gfx
//19 lines to copy, line 40, 41 from gfx
//18 lines to copy, line 60, 61, 62 from gfx


void fatal(const char* s, ...) {
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        exit(2);
}

typedef struct ctx {
    png_bytep * row_pointers;
    png_byte color_type;
    png_byte bit_depth;
    int width;
    int height;
    int mc1;
    int mc2;
    int mc3;
    int bg;
    int x_start;
    int x_end;
    int y_start;
    int y_end;
    int hires;
    int multicolor;
    int duplicate_mc;  // 1 = copy even pixelcolumn to odd.  2 = copy odd pixel columns to even.
    int map;
    int nobadline;
} ctx;


void do_duplicate_mc(ctx* ctx, unsigned char* data, int bx, int by, int width) {
    int x, y;
    if (ctx->duplicate_mc == 1) {
        for (y = 0; y < 21; y++) {
            for (x = 0; x < 24; x+=2) {
                data[(by + y) * width + bx + x + 1] = data[(by + y) * width + bx + x];
            }
        }
    }
    else if (ctx->duplicate_mc == 2) {
        for (y = 0; y < 21; y++) {
            for (x = 0; x < 24; x+=2) {
                data[(by + y) * width + bx + x] = data[(by + y) * width + bx + x + 1];
            }
        }
    }
}


int is_hires(ctx* ctx, unsigned char* data, int bx, int by, int width) {
    int x, y;
    int mcol1 = 0;
    int mcol2 = 0;
    int mcol3 = 0;
    for (y = 0; y < 21; y++) {
        for (x = 0; x < 24; x++) {
            if (data[(by + y) * width + bx + x] == ctx->mc1) mcol1++;
            else if (data[(by + y) * width + bx + x] == ctx->mc2) mcol2++;
            else if (data[(by + y) * width + bx + x] != ctx->bg) mcol3++;
        }
        //check for hires pixels
        for (x = 0; x < 24; x += 2) {
            if (data[(by + y) * width + bx + x + 0] != data[(by + y) * width + bx + x + 1]) return 1;
        }
    }

    //force colors same as bg to bg
    if (ctx->mc1 == ctx->bg) mcol1 = 0;
    if (ctx->mc2 == ctx->bg) mcol2 = 0;

    //contains more than one color, do not treat as hires, for sure
    if (mcol1 > 0 && mcol2 > 0) return 0;
    if (mcol1 > 0 && mcol3 > 0) return 0;
    if (mcol2 > 0 && mcol3 > 0) return 0;

    if (mcol1 > 0 && mcol2 == 0 && mcol3 == 0) return 0;
    if (mcol2 > 0 && mcol1 == 0 && mcol3 == 0) return 0;

    //only mcol3 is used? force to hires in any case
    if (mcol1 == 0 && mcol2 == 0) return 1;

    //should not happen, but treat as mutlicol in case
    return 0;
}

int find_sprite(unsigned char* spriteset, unsigned char* block, int pos) {
    int res = 0;
    int i;

    //no identic sprite found, return
    if (res == pos) return res;
    for (i = 0; i < 63; i++) {
        if (spriteset[res * 64 + i] != block[i]) {
            //advance to next sprite
            i = -1; res++;
            //no identic sprite found, return
            if (res == pos) return res;
        }
    }
    return res;
}

void load_png(ctx* ctx, char* name) {
    int y;

    png_byte header[8];
    png_infop info_ptr;
    png_structp png_ptr;

    FILE *fp = fopen(name, "rb");
    if (!fp) fatal("File %s not found", name);
    if (fread(header, 1, 8, fp) != 8 || png_sig_cmp(header, 0, 8)) fatal("%s is not a .png file", name);
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png_ptr) fatal("png_create_read_struct failed");
    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) fatal("png_create_info_struct failed");
    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fatal("Error during init_io");
    }

    png_set_filler(png_ptr, 0, PNG_FILLER_AFTER);
    png_set_expand(png_ptr);

    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, 8);
    png_read_info(png_ptr, info_ptr);
    ctx->width = png_get_image_width(png_ptr, info_ptr);
    ctx->height = png_get_image_height(png_ptr, info_ptr);
    ctx->color_type = png_get_color_type(png_ptr, info_ptr);
    ctx->bit_depth = png_get_bit_depth(png_ptr, info_ptr);

    ctx->bit_depth = png_get_bit_depth(png_ptr, info_ptr);
    //printf("%d\n",ctx->bit_depth);

    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fatal("Error during read_image");
    }

    png_read_update_info(png_ptr, info_ptr);

    ctx->row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * ctx->height);
    for (y = 0; y < ctx->height; y++) {
        ctx->row_pointers[y] = (png_byte*) malloc(png_get_rowbytes(png_ptr,info_ptr));
    }

    png_read_image(png_ptr, ctx->row_pointers);

    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
}

void to_c64_palette(ctx* ctx, unsigned char* data) {
    static const int palette[16][3] = {
        {0x00, 0x00, 0x00},
        {0xFF, 0xFF, 0xFF},
        {0x68, 0x37, 0x2B},
        {0x70, 0xA4, 0xB2},
        {0x6F, 0x3D, 0x86},
        {0x58, 0x8D, 0x43},
        {0x35, 0x28, 0x79},
        {0xB8, 0xC7, 0x6F},
        {0x6F, 0x4F, 0x25},
        {0x43, 0x39, 0x00},
        {0x9A, 0x67, 0x59},
        {0x44, 0x44, 0x44},
        {0x6C, 0x6C, 0x6C},
        {0x9A, 0xD2, 0x84},
        {0x6C, 0x5E, 0xB5},
        {0x95, 0x95, 0x95},
    };

    int x, y, c;

    unsigned char r1, g1, b1;
    unsigned char r2, g2, b2;

    int best_col;
    int best_dist;
    int dist;

    for (y = 0; y < ctx->height; y++) {
        for (x = 0; x < ctx->width; x++) {
             r1 = ctx->row_pointers[y][x * 4 + 0];
             g1 = ctx->row_pointers[y][x * 4 + 1];
             b1 = ctx->row_pointers[y][x * 4 + 2];

             best_dist = - 1;
             best_col = 0;
             for (c = 0; c < 16; c++) {
                 r2 = palette[c][0];
                 g2 = palette[c][1];
                 b2 = palette[c][2];

                 dist = (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2) + (b1-b2)*(b1-b2);

                 if (best_dist < 0 || best_dist > dist) {
                     best_col = c;
                     best_dist = dist;
                 }
             }
             data[y * ctx->width + x] = best_col;
             //if (x < 200) printf("%x", best_col);
        }
        //printf("\n");
    }
}

void thcmyfy(ctx* ctx, unsigned char* data, unsigned char* copy) {
    int x,y;

    int rowsize = 21;
    int ysrc = 0;
    int ydst = 0;
    int size;

    while ((ysrc < ctx->height) && rowsize) {
        if (rowsize + ysrc > ctx->height) size = (ctx->height - ysrc) * ctx->width;
        else size = rowsize * ctx->width;
        memcpy(&data[ydst * ctx->width], &copy[ysrc * ctx->width], size);
        rowsize -= ctx->nobadline;
        ysrc += 21;
        ydst += 21;
    }

    rowsize = 0;
    ysrc = 0;
    ydst = 21;

    while ((ysrc < ctx->height) && (rowsize < 21)) {
        printf("sp-line: %d  gfx-line: %d  num lines: %d\n", ydst, ysrc, rowsize);
        if (rowsize + ysrc > ctx->height) size = (ctx->height - ysrc) * ctx->width;
        else size = rowsize * ctx->width;
        memcpy(&data[ydst * ctx->width], &copy[ysrc * ctx->width], size);
        rowsize += ctx->nobadline;
        ydst += (21 - ctx->nobadline);
        ysrc += (21 - ctx->nobadline);
    }

    if (ctx->height == ctx->y_end) {
        ctx->y_end = ydst;
    }
    ctx->height = ydst;

    for (y = 0; y < ctx->height; y++) {
        printf("%04d: ", y);
        for (x = 0; x < ctx->width; x++) {
            if (data[y * ctx->width + x]) printf ("█");
            else printf(" ");
        }
        printf("\n");
    }
}

int convert(ctx* ctx, unsigned char* data, unsigned char* colormap, unsigned char* spritemap, unsigned char* spriteset, int spritepos) {
    int bx, by;
    int x, y;
    int hires;
    int col3;
    int pix;

    unsigned char bits;
    unsigned char byte;
    unsigned char block[64];

    int temp;
//    int oldpos;
    int pixel;

    for (by = ctx->y_start; by <= ctx->y_end - 21; by += 21) {
//        oldpos = spritepos;
        for (bx = ctx->x_start; bx <= ctx->x_end - 24; bx += 24) {
            // Duplicate pixelrows if requested with the -d flag:
            do_duplicate_mc(ctx, data, bx, by, ctx->width);
            if (ctx->hires) hires = 1;
            else if (ctx->multicolor) hires = 0;
            else hires = is_hires(ctx, data, bx, by, ctx->width);
            if (ctx->duplicate_mc > 0) hires = 0;
            col3 = ctx->mc3;
            pixel = 0;
            for (y = 0; y < 21; y++) {
                for (x = 0; x < 24; x++) {
                    if ((x & 7) == 0) byte = 0;
                    pix = data[((by + y) * ctx->width) + bx + x];
                    if(!hires) {
                        if (pix != ctx->bg && pix != ctx->mc1 && pix != ctx->mc2) {
                            //extra handling for col3 as it can be set per sprite
                            if (col3 < 0) col3 = pix;
                            else if (col3 != pix) {
                                if (ctx->bg < 0) ctx->bg = pix;
                                else if (ctx->mc1 < 0) ctx->mc1 = pix;
                                else if (ctx->mc2 < 0) ctx->mc2 = pix;
                                else {
                                    printf("col3 clash @ x=%d, y=%d, hires=%d col=$%x mc1=$%x mc2=$%x\n", bx + x, by + y, hires, pix, ctx->mc1, ctx->mc2);
                                }
                            }
                        }

                        if (pix == ctx->bg) {
                            bits = 0;
                        } else if (pix == ctx->mc1) {
                            bits = 1;
                            pixel += 2;
                        } else if (pix == ctx->mc2) {
                            bits = 3;
                            pixel += 2;
                        } else {
                            bits = 2;
                            pixel += 2;
                        }

                        byte = (byte << 2) | bits;
                        //skip one pixel (multicolor!)
                        x++;
                    } else {
                        if(pix != ctx->bg) {
                            pixel++;
                            bits = 1;
                            if (col3 < 0) col3 = pix;
                            else if (col3 != pix) {
                                printf("col3 clash @ x=%d, y=%d, hires=%d col=$%x\n", bx + x, by + y, hires, pix);
                            }
                        } else {
                            bits = 0;
                        }
                        byte = (byte << 1) | bits;
                    }
                    if ((x & 7) == 7) block[y * 3 + (x >> 3)] = byte;
                }
            }

            //if (clash) {
                //printf("col3 clash @ x=%d, y=%d, hires=%d\n", bx, by, hires);
                //exit (2);
            //}
            if (col3 < 0) col3 = 0;

            if (ctx->map) {
                temp = find_sprite(&spriteset[0], &block[0], spritepos);
            } else {
                temp = spritepos;
            }

            if (spritepos < 256) {
                spritemap[(by / 21) * (ctx->width / 24) + (bx / 24)] = temp;
                colormap[(by / 21) * (ctx->width / 24) + (bx / 24)] = col3;
            }

            //add block to spriteset
            if (temp == spritepos) {
                memcpy(&spriteset[0 + spritepos * 64], &block[0], 63);
                spritepos++;
            }
            printf("%02x",temp);
        }
        printf("\n");
        if (spritepos >= 65536 / 64) {
            printf("need mroe than 256 sprites. Aborting.\n");
            break;
        }
    }
    if (spritepos >= 256) {
        printf("sprites used: %d  (but only the first 256 sprites used in map)\n",spritepos);
    } else {
        printf("sprites used: %d\n",spritepos);
    }
    return spritepos;
}

signed read_number(char* sw, char* arg, int llim, int hlim) {
    int num = strtoul(arg, NULL, 10);
    if (num < llim || num > hlim) {
        fatal("number for '%s' must be between %d and %d", sw, llim, hlim);
    }
    return num;
}

int main(int argc, char *argv[]) {
    FILE* fw;

    //could become multiple spritesets, like one spriteset per block? then better have spriteset[num][pos]
    unsigned char* colormap;
    unsigned char* spritemap;
    unsigned char* spriteset;
    unsigned char* data;
    unsigned char* copy;

    char* spriteset_name;
    char* spritemap_name;
    char* colmap_name;

    int prefix_len;
    int result_name_len;

    int map_size;

    int spritepos = 0;
    int y;

    char* filename;
    char* sw;

    ctx ctx;

    ctx.mc1 = -1;
    ctx.mc2 = -1;
    ctx.mc3 = -1;
    ctx.bg = 0;
    ctx.x_start = -1;
    ctx.y_start = -1;
    ctx.x_end = -1;
    ctx.y_end = -1;
    ctx.map = 0;
    ctx.nobadline = 0;

    ctx.hires = 0;
    ctx.multicolor = 0;
    ctx.duplicate_mc = 0;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s -1 [multicol1] -2 [multicol2] -3 [multicol3] -b [background] -m -h -d [1/2] -x [from] -y [from] -X [to] -Y [to] -o [num] filename.png\n", *argv);
        fprintf(stderr, "\t-1     multicolor 1\n");
        fprintf(stderr, "\t-2     multicolor 2\n");
        fprintf(stderr, "\t-3     multicolor 3\n");
        fprintf(stderr, "\t-b     background\n");
        fprintf(stderr, "\t-x     x-start\n");
        fprintf(stderr, "\t-y     y-start\n");
        fprintf(stderr, "\t-X     x-end\n");
        fprintf(stderr, "\t-Y     y-end\n");
        fprintf(stderr, "\t-h     force hires only\n");
        fprintf(stderr, "\t-M     force multicolor only\n");
        fprintf(stderr, "\t-d     1=copy even pixelcolumns to odd. 2=copy odd pixelcolumns to even.\n");
        fprintf(stderr, "\t-m     also create a spritemap\n");
        fprintf(stderr, "\t-o     render sprites suitable for sprite data overlay to avoid sprite switches in badlines. Number of overlapping lines are configured here\n");
        exit (2);
    }
    while (++argv, --argc) {
        sw = *argv;
        if (argc >= 2 && !strcmp(*argv, "-1")) {
            ctx.mc1 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-2")) {
            ctx.mc2 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-3")) {
            ctx.mc3 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-b")) {
            ctx.bg = read_number(sw, *++argv, 0 , 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-x")) {
            ctx.x_start = read_number(sw, *++argv, 0, 65536);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-y")) {
            ctx.y_start = read_number(sw, *++argv, 0, 65536);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-X")) {
            ctx.x_end = read_number(sw, *++argv, 0, 65536);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-Y")) {
            ctx.y_end = read_number(sw, *++argv, 0, 65536);
            argc--;
        } else if (argc >= 1 && !strcmp(*argv, "-h")) {
            ctx.hires = 1;
        } else if (argc >= 1 && !strcmp(*argv, "-M")) {
            ctx.multicolor = 1;
        } else if (argc >= 2 && !strcmp(*argv, "-d")) {
            ctx.duplicate_mc = read_number(sw, *++argv, 0, 2);
            argc--;
        } else if (argc >= 1 && !strcmp(*argv, "-m")) {
            ctx.map = 1;
        } else if (argc >= 2 && !strcmp(*argv, "-o")) {
            ctx.nobadline = read_number(sw, *++argv, 1, 21);
            argc--;
        } else {
            //break;
            filename = *argv;
        }
    }

    //filename = *argv;

    load_png(&ctx, filename);

    // cut of prefix in case
    prefix_len = strlen(filename);
    if (prefix_len >= 4) {
        if (!strcmp(filename + prefix_len - 4, ".png") || !strcmp(filename + prefix_len - 4, ".PNG")) {
            prefix_len -= 4;
            filename[prefix_len] = 0;
        }
    }
    result_name_len = sizeof(char) * (prefix_len + 5);

    if (ctx.y_start < 0) ctx.y_start = 0;
    if (ctx.y_end < 0) ctx.y_end = ctx.height;
    if (ctx.x_start < 0) ctx.x_start = 0;
    if (ctx.x_end < 0) ctx.x_end = ctx.width;

    if (ctx.y_start > ctx.height) {
        fatal("y-start > height");
    }
    if (ctx.y_start >= ctx.y_end) {
        fatal("y-start >= y-end");
    }
    if (ctx.y_end > ctx.height) {
        fatal("y-end > height");
    }

    if (ctx.x_start > ctx.width) {
        fatal("x-start > width");
    }
    if (ctx.x_start >= ctx.x_end) {
        fatal("x-start >= x-end");
    }
    if (ctx.x_end > ctx.width) {
        fatal("x-end > width");
    }

    data = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * (4 * ctx.height));
    copy = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height);

    to_c64_palette(&ctx, data);
    for (y = 0; y < ctx.height; y++) free(ctx.row_pointers[y]);

    if (ctx.nobadline > 0) {
        memcpy(copy, data, sizeof(unsigned char) * ctx.width * ctx.height);
        memset(data, 0, sizeof(unsigned char) * ctx.width * (4 * ctx.height));
        thcmyfy(&ctx, data, copy);
    }

    map_size = (ctx.width / 24) * (ctx.height / 21);
    colormap = (unsigned char*) malloc(sizeof(unsigned char) * map_size);
    spritemap  = (unsigned char*) malloc(sizeof(unsigned char) * map_size);
    spriteset  = (unsigned char*) malloc(sizeof(unsigned char) * 65536);

    memset(colormap, 0, map_size);
    memset(spritemap, 0, map_size);
    memset(spriteset, 0, 65536 * sizeof(unsigned char));

    spritepos = convert (&ctx, data, colormap, spritemap, spriteset, spritepos);

    spriteset_name = (char*) malloc(result_name_len);
    spritemap_name = (char*) malloc(result_name_len);
    colmap_name  = (char*) malloc(result_name_len);

    snprintf(spriteset_name, result_name_len, "%s.spr", filename);
    snprintf(spritemap_name, result_name_len, "%s.map", filename);
    snprintf(colmap_name,  result_name_len, "%s.col", filename);

    fw = fopen(spriteset_name, "wb");
    fwrite(&spriteset[0],1,spritepos * 64,fw);
    fclose(fw);

//    fw = fopen(colmap_name, "wb");
//    fwrite(&colormap[0],1,map_size,fw);
//    fclose(fw);

    if (ctx.map) {
        fw = fopen(spritemap_name, "wb");
        fwrite(&spritemap[0],1,map_size ,fw);
        fclose(fw);
    }

    free(spriteset_name);
    free(spritemap_name);
    free(colmap_name);

    free(colormap);
    free(spritemap);
    free(spriteset);

    free(ctx.row_pointers);
    free(data);
    free(copy);
    return 0;
}
