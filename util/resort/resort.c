#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include <png.h>
#include <string.h>
#include <stdarg.h>

#define MAX_LENGTH 16

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

    char* output_name;
    char* input_name;

    unsigned char screen[1000];
    unsigned char colram[1000];
    unsigned char bitmap[8000];

    unsigned int map_00[16];
    unsigned int map_01[16];
    unsigned int map_10[16];
    unsigned int map_11[16];

    int cols_00;
    int cols_01;
    int cols_10;
    int cols_11;

    int mc1;
    int mc2;
    int mc3;
    int bg;

    int used[4];
} ctx;

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

    png_set_palette_to_rgb(png_ptr);
    png_set_filler(png_ptr, 0, PNG_FILLER_AFTER);

    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, 8);
    png_read_info(png_ptr, info_ptr);

    ctx->width = png_get_image_width(png_ptr, info_ptr);
    ctx->height = png_get_image_height(png_ptr, info_ptr);
    ctx->color_type = png_get_color_type(png_ptr, info_ptr);
    ctx->bit_depth = png_get_bit_depth(png_ptr, info_ptr);

    //expand grayscale to rgb first (1 bit png!)
    if (ctx->color_type == PNG_COLOR_TYPE_GRAY || ctx->color_type == PNG_COLOR_TYPE_GRAY_ALPHA) png_set_gray_to_rgb(png_ptr);
    png_set_expand(png_ptr);
    png_read_update_info(png_ptr, info_ptr);
    ctx->color_type = png_get_color_type(png_ptr, info_ptr);
    ctx->bit_depth = png_get_bit_depth(png_ptr, info_ptr);

    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fatal("Error during read_image");
    }

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

int find_col(ctx* ctx, int bx, int by, int color, int map_only) {
    int a;
    //int result = -1;
    for (a = 0; a < ctx->cols_00; a++) {
        if (ctx->map_00[a] == color) {
            if (ctx->bg >= 0 && ctx->bg != color) {
                printf("clash on 00 @ block x:$%02x y:$%02x\n", bx, by);
            } else {
                ctx->bg = color;
            }
            return 0;
        }
    }
    for (a = 0; a < ctx->cols_01; a++) {
        if (ctx->map_01[a] == color) {
            if (ctx->mc1 >= 0 && ctx->mc1 != color) {
                printf("clash on 01 @ block x:$%02x y:$%02x\n", bx, by);
            } else {
                ctx->mc1 = color;
            }
            return 1;
        }
    }
    for (a = 0; a < ctx->cols_10; a++) {
        if (ctx->map_10[a] == color) {
            if (ctx->mc2 >= 0 && ctx->mc2 != color) {
                printf("clash on 10 @ block x:$%02x y:$%02x\n", bx, by);
            } else {
                ctx->mc2 = color;
            }
            return 2;
        }
    }
    for (a = 0; a < ctx->cols_11; a++) {
        if (ctx->map_11[a] == color) {
            if (ctx->mc3 >= 0 && ctx->mc3 != color) {
                printf("clash on 11 @ block x:$%02x y:$%02x\n", bx, by);
            } else {
                ctx->mc3 = color;
            }
            return 3;
        }
    }
    if (!map_only) {
        if (ctx->bg == color) return 0;
        if (ctx->mc1 == color) return 1;
        if (ctx->mc2 == color) return 2;
        if (ctx->mc3 == color) return 3;
        if (ctx->mc1 < 0) {
            ctx->mc1 = color;
            return 1;
        }
        if (ctx->mc2 < 0) {
            ctx->mc2 = color;
            return 2;
        }
        if (ctx->mc3 < 0) {
            ctx->mc3 = color;
            return 3;
        }
    }
    return -1;
}

void remap(ctx* ctx) {
    FILE* fw;
    int bx, by, x, y;
    int bits;
    unsigned char byte;
    unsigned char* data;
    load_png(ctx, ctx->input_name);
    data = (unsigned char*) malloc(sizeof(unsigned char) * 320 * 200);
    if (ctx->height > 200 || ctx->width > 320) {
        fprintf(stderr, "Error: dimensions exceed 320x200 pixels\n");
        exit(1);
    }
    to_c64_palette(ctx, data);
    ctx->bg = -1;
    for (by = 0; by < 25; by ++) {
        for (bx = 0; bx < 40; bx ++) {
            ctx->mc1 = -1;
            ctx->mc2 = -1;
            ctx->mc3 = -1;
            for (y = 0; y < 8; y++) {
                for (x = 0; x < 8; x += 2) {
                    //populate with requested mapping first
                    find_col(ctx, bx, by, data[((by * 8 + y) * 320) + bx * 8 + x], 1);
                }
            }
            //XXX TODO need multiple passes: 1. pass, find all requested color mappings, second pass: map remaining colors to stil lavailable colors, then assemble block
            for (y = 0; y < 8; y++) {
                byte = 0;
                for (x = 0; x < 8; x += 2) {
		    byte <<= 2;
                    //use either premapped colors or fill up remaining colors/mappings
                    bits = find_col(ctx, bx, by, data[((by * 8 + y) * 320) + bx * 8 + x], 0);
                    byte |= (bits & 3);
                }
                ctx->bitmap[by * 320 + bx * 8 + y] = byte;
            }
            ctx->colram[by * 40 + bx] = ctx->mc3 & 0xf;
            ctx->screen[by * 40 + bx] = ((ctx->mc1 & 0xf) << 4) | (ctx->mc2 & 0xf);
        }
    }
    free(data);
    fw = fopen(ctx->output_name, "wb");
    fputc(0x00,fw);
    fputc(0x60,fw);
    fwrite(&ctx->bitmap,1,8000,fw);
    fwrite(&ctx->screen,1,1000,fw);
    fwrite(&ctx->colram,1,1000,fw);
    fputc(ctx->bg,fw);
}

void add_to_mapping(ctx* ctx, char* argname, char *arg) {
    int color = strtoul(argname + 1, NULL, 10);
    if (color < 0 || color > 15) {
        fprintf(stderr, "Error: no valid number color selected: '%s')\n", argname);
        exit(1);
    }
    if (!strcmp(arg, "00")) {
        ctx->map_00[ctx->cols_00++] = color;
    } else if (!strcmp(arg, "01")) {
        ctx->map_01[ctx->cols_01++] = color;
    } else if (!strcmp(arg, "10")) {
        ctx->map_10[ctx->cols_10++] = color;
    } else if (!strcmp(arg, "11")) {
        ctx->map_11[ctx->cols_11++] = color;
    } else {
        fprintf(stderr, "Error: no valid mapping given: '%s' (00, 01, 10, 11))\n", arg);
        exit(1);
    }
}

int main(int argc, char *argv[]) {
    int i;

    ctx ctx = { 0 };
    ctx.cols_00 = 0;
    ctx.cols_01 = 0;
    ctx.cols_10 = 0;
    ctx.cols_11 = 0;

    for (i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-", 1) || !strncmp(argv[i], "--", 2)) {
            if (!strcmp(argv[i], "-0")  ||
                !strcmp(argv[i], "-1")  ||
                !strcmp(argv[i], "-2")  ||
                !strcmp(argv[i], "-3")  ||
                !strcmp(argv[i], "-4")  ||
                !strcmp(argv[i], "-5")  ||
                !strcmp(argv[i], "-6")  ||
                !strcmp(argv[i], "-7")  ||
                !strcmp(argv[i], "-8")  ||
                !strcmp(argv[i], "-9")  ||
                !strcmp(argv[i], "-10") ||
                !strcmp(argv[i], "-11") ||
                !strcmp(argv[i], "-12") ||
                !strcmp(argv[i], "-13") ||
                !strcmp(argv[i], "-14") ||
                !strcmp(argv[i], "-15")) {
                add_to_mapping(&ctx, argv[i], argv[i + 1]);
                i++;
            } else if (!strcmp(argv[i], "-i")) {
                i++;
                ctx.input_name = argv[i];
            } else if (!strcmp(argv[i], "-o")) {
                i++;
                ctx.output_name = argv[i];
            } else {
                fprintf(stderr, "Error: Unknown option %s\n", argv[i]);
                exit(1);
            }
        } else {
            fprintf(stderr, "Error: Unknown option %s\n", argv[i]);
            exit(1);
        }
    }

    if (argc == 1) {
        fprintf(stderr, "Usage: %s [options] input\n"
                        "  -o [filename]               Set output filename\n"
                        "  -i [filename]               Set input filename (parseable with sprintf)\n"
                        "  -0 .. 15 [mapping]          select a target mapping for color (00, 01, 10, 11)\n"
                        ,argv[0]);
        exit(1);
    }

    if (ctx.input_name == NULL) {
        fprintf(stderr, "Error: No input-filename given\n");
        exit(1);
    }

    if (ctx.output_name == NULL) {
        fprintf(stderr, "Error: No ouput-filename given\n");
        exit(1);
    }
    remap(&ctx);
    return 0;
}
