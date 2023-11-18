#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>

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
    unsigned char mc1;
    unsigned char mc2;
    unsigned char mc3;
    int colram;
    unsigned char bg;
    int x_start;
    int x_end;
    int y_start;
    int y_end;
    int reserved;
    int hires;
    int fix;
    int splits[256];
    int num_splits;
    int cs_num;
    int tile_height;
    int tile_width;
    int cset_size;
    int plain;
    int max_cs_size;
    int ecm;
} ctx;

void print_char(ctx* ctx, unsigned char* data, int bx, int by, int width) {
    int x, y;

    for (y = 0; y < ctx->tile_height; y++) {
        if (y % 8 == 0) printf("+--------+\n");
        printf("|");
        for (x = 0; x < 8; x++) {
            printf("%1x",data[(by + y) * width + bx + x]);
        }
        printf("|\n");
    }
    printf("+--------+\n");
}

int is_hires(ctx* ctx, unsigned char* data, int bx, int by, int width) {
    int x, y;
    int mcol1 = 0;
    int mcol2 = 0;
    int colram = 0;

    for (y = 0; y < ctx->tile_height; y++) {
        for (x = 0; x < 8; x++) {
            if (data[(by + y) * width + bx + x] == ctx->mc1) mcol1++;
            else if (data[(by + y) * width + bx + x] == ctx->mc2) mcol2++;
            else if (data[(by + y) * width + bx + x] != ctx->bg) {
                colram++;
            }
        }
        //check for hires pixels
        for (x = 0; x < 8; x += 2) {
            if (data[(by + y) * width + bx + x + 0] != data[(by + y) * width + bx + x + 1]) return 1;
        }
    }

    // no further checks if we work on plain multicol
    if (ctx->colram >= 0) {
        return 0;
    }

    //force colors same as bg to bg
    if (ctx->mc1 == ctx->bg) mcol1 = 0;
    if (ctx->mc2 == ctx->bg) mcol2 = 0;

    //contains more than one color, do not treat as hires, for sure
    if (mcol1 > 0 && mcol2 > 0) return 0;
    //if (mcol1 > 0 && colram > 0) return 0;
    //if (mcol2 > 0 && colram > 0) return 0;

    // we can treat a multicolchar as hires, as soon as it only uses one multicol that is < 8
    if (ctx->mc1 < 8 && mcol1 > 0 && mcol2 == 0 && colram == 0) return 1;
    if (ctx->mc2 < 8 && mcol2 > 0 && mcol1 == 0 && colram == 0) return 1;

    //only colram is used? force to hires in any case
    if (mcol1 == 0 && mcol2 == 0) return 1;

    //should not happen, but treat as mutlicol in case
    return 0;
}

int find_char(ctx* ctx, unsigned char* charset, unsigned char* block, int pos) {
    // do not match against reserved chars
    int res = ctx->reserved;
    int y;

    //no identic char found, return
    if (res == pos) return res;
    for (y = 0; y < ctx->tile_height; y++) {
        if (charset[res * ctx->tile_height + y] != block[y]) {
            //advance to next char
            y = -1; res++;
            //no identic char found, return
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

void next_charset(ctx* ctx, unsigned char* charset, int charpos) {
    if (charpos == 0) return;
    printf("charset %d contains %d chars (+%d reserved).\n",ctx->cs_num, charpos - ctx->reserved, ctx->reserved);
    if (charpos > ctx->max_cs_size) {
        printf("chars do not fit into one charset, you need to split with -s?\n");
    }
    ctx->cs_num++;
    if (ctx->cs_num * ctx->cset_size >= 0x10000) {
        fatal("too many charsets");
    }
    // start with a clean charset
    memset(charset + ctx->cs_num * ctx->cset_size, 0, ctx->cset_size);
}

void convert(ctx* ctx, unsigned char* data, unsigned char* colormap, unsigned char* charmap, unsigned char* charset) {
    int bx, by;
    int x, y;
    int hires;
    int colram;
    int pix;
    int clash;
    int s;
    int num_chars = 0;
    int charpos = 0;

    int last_charpos = 0;
    int last_num_chars = 0;

    unsigned char bits;
    unsigned char byte;
    unsigned char block[ctx->tile_height];

    int temp;
    int pixel;
    int new_charset = 1;
    int offset = 0;

    ctx->cs_num = 0;

    for (by = ctx->y_start; by <= ctx->y_end - ctx->tile_height; by += ctx->tile_height) {

        // remember old stats
        last_charpos = charpos;
        last_num_chars = num_chars;

	// skip first x chars if reserved
        if (charpos < ctx->reserved) charpos = ctx->reserved;

        // do we have fixed chars?
        if (ctx->fix && new_charset) {
            new_charset = 0;
            memset(charpos * 8 + charset + ctx->cs_num * ctx->cset_size + 0, 0, ctx->tile_height);
            memset(charpos * 8 + charset + ctx->cs_num * ctx->cset_size + ctx->tile_height, 255, ctx->tile_height);
            //memset(charpos * 8 + charset + ctx->cs_num * ctx->cset_size + 0, 0, 8);
            //memset(charpos * 8 + charset + ctx->cs_num * ctx->cset_size + 8, 255, 8);

            charpos += 2;
            num_chars += 2;
        }

        for (bx = ctx->x_start; bx <= ctx->x_end - 8; bx += 8) {
            if (ctx->hires) hires = 1;
            else hires = is_hires(ctx, data, bx, by, ctx->width);

            if (ctx->colram >= 0) colram = ctx->colram + 8;
            else colram = -1;

            clash = 0;
            pixel = 0;

            if (ctx->ecm) offset = -1;
            else offset = 0;

            if (hires && ctx->colram >= 0) {
                clash = 1;
            }
            for (y = 0; y < ctx->tile_height; y++) {
                byte = 0;
                for (x = 0; x < 8; x++) {
                    pix = data[(by + y) * ctx->width + bx + x];
                    if(!hires) {
                        if (pix == ctx->bg) {
                            bits = 0;
                        } else if (pix == ctx->mc1) {
                            bits = 1;
                            pixel += 2;
                        } else if (pix == ctx->mc2) {
                            bits = 2;
                            pixel += 2;
                        } else {
                            if (colram < 0) colram = pix + (ctx->hires ^ 1) * 8;
                            else if (colram != pix + 8) {
                                clash = 1;
                            }
                            bits = 3;
                            pixel += 2;
                        }
                        byte = (byte << 2) | bits;
                        //skip one pixel (multicolor!)
                        x++;
                    } else {
                        if (ctx->ecm) {
                            if (pix != ctx->bg && pix != ctx->mc1 && pix != ctx->mc2 && pix != ctx->mc3) {
                                pixel++;
                                bits = 1;
                                if (colram < 0) colram = pix;
                                else if (colram != pix) clash = 1;
                            } else {
                                if (pix == ctx->bg)  {
                                    if ((offset != 0x00) && (offset >= 0)) clash = 1;
                                    offset = 0x00;
                                }
                                if (pix == ctx->mc1)  {
                                    if ((offset != 0x40) && (offset >= 0)) clash = 1;
                                    offset = 0x40;
                                }
                                if (pix == ctx->mc2)  {
                                    if ((offset != 0x80) && (offset >= 0)) clash = 1;
                                    offset = 0x80;
                                }
                                if (pix == ctx->mc3)  {
                                    if ((offset != 0xc0) && (offset >= 0)) clash = 1;
                                    offset = 0xc0;
                                }
                                bits = 0;
                            }
                        } else {
                            if (pix != ctx->bg) {
                                pixel++;
                                bits = 1;
                                if (colram < 0) colram = pix;
                                else if (colram != pix) clash = 1;
                            } else {
                                bits = 0;
                            }
                        }
                        byte = (byte << 1) | bits;
                    }
                }
                block[y] = byte;
            }
            if (pixel == 0) {
                colram = 0;
            }

            if (offset < 0) offset = 0;
//save some more chars by transforming empty chars to filled chars with color 0
//            if (block[0] == 0x55 || block[0] == 0xaa || block[0] == 0x00) {
//                for (y = 0; y < 8; y++) {
//                    if (block[0] != block[y]) break;
//                }
//                //all lines are equal
//                if (y == 8) {
//                    if(block[0] == 0) {
//                        colram = 0;
//                        hires = 1;
//                        memset(&block[0], 0xff, 8);
//                    }
//                }
//            }

            if (clash) {
                printf("colram clash @ x=%d, y=%d, hires=%d\n", bx, by, hires);
            	print_char(ctx, data, bx, by, ctx->width);
                //exit (2);
            }
            if (colram < 0) colram = (1 ^ hires) * 8;
            if (!ctx->plain) {
                temp = find_char(ctx, &charset[ctx->cs_num * ctx->cset_size], &block[0], charpos);
            } else {
                temp = charpos;
            }

            if (charpos <= ctx->max_cs_size) {
                charmap[by / ctx->tile_height * (ctx->width / 8) + bx / 8] = temp | offset;
                colormap[by / ctx->tile_height * (ctx->width / 8) + bx / 8] = colram;
            }

            // add block to charset
            if (temp == charpos) {
		memcpy(&charset[ctx->cs_num * ctx->cset_size + charpos * ctx->tile_height], &block[0], ctx->tile_height);
                charpos++;
                num_chars++;
            }
        }

        if (ctx->num_splits) {
            // check for splits
            for (s = 0; s < ctx->num_splits; s++) {
                if (by + ctx->tile_height == ctx->splits[s]) {
                    printf("user defined split at y=%d chars used until here: %d\n",ctx->splits[s], charpos);
                    next_charset(ctx, charset, charpos);
                    charpos = 0;
                    new_charset = 1;
                }
            }
        }

        if (charpos > ctx->max_cs_size) {
            num_chars = last_num_chars;
            // wipe out remaining chars
            memset(charset + ctx->cs_num * ctx->cset_size + last_charpos * ctx->tile_height, 0, (0x100 - last_charpos) * ctx->tile_height);
            next_charset(ctx, charset, last_charpos);
            charpos = 0;
            new_charset = 1;
            printf("forcing a split at y=%d\n",by);
            // redo charline
            by -= ctx->tile_height;
        }
    }

    // finalize old charset and start with a new one if needed
    next_charset(ctx, charset, charpos);

    printf("overall used chars: %d\n",num_chars);
    return;
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

    //could become multiple charsets, like one charset per block? then better have charset[num][pos]
    unsigned char* colormap;
    unsigned char* charmap;
    unsigned char* charset;
    unsigned char* data;

    char* charset_name;
    char* charmap_name;
    char* colmap_name;

    int prefix_len;
    int result_name_len;

    int map_size;

    int y;

    char* filename;
    char* sw;

    int split;

    ctx ctx;

    ctx.mc1 = 0xf;
    ctx.mc2 = 0xc;
    ctx.bg = 0;
    ctx.colram = -1;
    ctx.x_start = -1;
    ctx.y_start = -1;
    ctx.x_end = -1;
    ctx.y_end = -1;
    ctx.fix = 0;

    ctx.hires = 0;
    ctx.reserved = 0;
    ctx.splits[0] = - 1;
    ctx.num_splits = 0;
    ctx.plain = 0;

    ctx.ecm = 0;
    ctx.tile_height = 8;
    ctx.max_cs_size = 256;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s -1 [multicol1] -2 [multicol2] -c [colram] -b [background] -r [resreved] -h -x [from] -y [from] -X [to] -Y [to] filename.png\n", *argv);
        fprintf(stderr, "\t-1     multicolor 1 for mixed mode / bg 1 for ecm mode\n");
        fprintf(stderr, "\t-2     multicolor 2 for mixed mode / bg 2 for ecm mode\n");
        fprintf(stderr, "\t-3     bg 3 in ecm mode\n");
        fprintf(stderr, "\t-c     force use of this value for colram (disable mixed mode)\n");
        fprintf(stderr, "\t-b     background\n");
        fprintf(stderr, "\t-x     x-start\n");
        fprintf(stderr, "\t-y     y-start\n");
        fprintf(stderr, "\t-X     x-end\n");
        fprintf(stderr, "\t-Y     y-end\n");
        fprintf(stderr, "\t-h     force hires only\n");
	fprintf(stderr, "\t-e     convert to ecm mode\n");
        fprintf(stderr, "\t-r     leave reserved number of chars free\n");
        fprintf(stderr, "\t-f     char 0 and 1 are blank and full block fix\n");
        fprintf(stderr, "\t-s     split in line y (can be used multiple times) to force a split at a given position, but actually the tool will find the optimal split positions\n");
        fprintf(stderr, "\t-t     tile height (standard: 8)\n");
	fprintf(stderr, "\t-p     do plain conversion without duplicate checks\n");
        exit (2);
    }
    while (++argv, --argc) {
        sw = *argv;
        if (argc >= 2 && !strcmp(*argv, "-f")) {
            ctx.fix = 1;
        } else if (argc >= 2 && !strcmp(*argv, "-s")) {
            split = read_number(sw, *++argv, 8, 65535);
            if (split % 8 != 0) {
                fatal("-s must be a mutiple of 8");
            } else {
                if(ctx.num_splits >= 256) {
                    fatal("max 256 splits allowed");
                } else {
                    ctx.splits[ctx.num_splits] = split;
                    ctx.num_splits++;
                }
            }
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-1")) {
            ctx.mc1 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-2")) {
            ctx.mc2 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-3")) {
            ctx.mc3 = read_number(sw, *++argv, 0, 15);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-c")) {
            ctx.colram = read_number(sw, *++argv, 0, 7);
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
        } else if (argc >= 2 && !strcmp(*argv, "-r")) {
            ctx.reserved = read_number(sw, *++argv, 0, 256);
            argc--;
        } else if (argc >= 2 && !strcmp(*argv, "-t")) {
            ctx.tile_height = read_number(sw, *++argv, 0, 256);
            argc--;
        } else if (argc >= 1 && !strcmp(*argv, "-e")) {
            ctx.ecm = 1;
            ctx.max_cs_size = 64;
            ctx.hires = 1;
        } else if (argc >= 1 && !strcmp(*argv, "-h")) {
            ctx.hires = 1;
        } else if (argc >= 1 && !strcmp(*argv, "-p")) {
            ctx.plain = 1;
        } else {
            break;
        }
    }

    ctx.cset_size = 0x800 / 8 * ctx.tile_height;
    filename = *argv;

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

    data = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height);
    to_c64_palette(&ctx, data);

    map_size = ctx.width / 8 * ctx.height / ctx.tile_height;
    colormap = (unsigned char*) malloc(sizeof(unsigned char) * map_size);
    charmap  = (unsigned char*) malloc(sizeof(unsigned char) * map_size);
    charset  = (unsigned char*) malloc(sizeof(unsigned char) * 65536);

    memset(colormap, ctx.colram, map_size);
    memset(charmap, 0, map_size);
    memset(charset, 0, 65536);

    convert (&ctx, data, colormap, charmap, charset);

    charset_name = (char*) malloc(result_name_len);
    charmap_name = (char*) malloc(result_name_len);
    colmap_name  = (char*) malloc(result_name_len);

    snprintf(charset_name, result_name_len, "%s.chr", filename);
    snprintf(charmap_name, result_name_len, "%s.scr", filename);
    snprintf(colmap_name,  result_name_len, "%s.col", filename);

    fw = fopen(charset_name, "wb");
    fwrite(&charset[0],1, ctx.cs_num * ctx.cset_size,fw);
    fclose(fw);

    fw = fopen(colmap_name, "wb");
    fwrite(&colormap[0],1,map_size,fw);
    fclose(fw);

    fw = fopen(charmap_name, "wb");
    fwrite(&charmap[0],1,map_size ,fw);
    fclose(fw);

    free(charset_name);
    free(charmap_name);
    free(colmap_name);

    for (y = 0; y < ctx.height; y++) free(ctx.row_pointers[y]);

    free(colormap);
    free(charmap);
    free(charset);

    free(ctx.row_pointers);
    free(data);
    return 0;
}
