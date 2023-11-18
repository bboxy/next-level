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

signed read_number(char* sw, char* arg, int llim, int hlim) {
    int num = strtoul(arg, NULL, 10);
    if (num < llim || num > hlim) {
        fatal("number for '%s' must be between %d and %d", sw, llim, hlim);
    }
    return num;
}

int main(int argc, char *argv[]) {
    FILE* fw;

    unsigned char* data;

    char* colmap_name;

    int prefix_len;
    int result_name_len;

    int map_size;

    int y;

    char* filename;

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
        fprintf(stderr, "Usage: %s input_filename.png\n", *argv);
        exit (2);
    }
    filename = argv[1];
    printf("Input filename = %s\n", filename);

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
    map_size = ctx.width * ctx.height;

    colmap_name  = (char*) malloc(result_name_len);
    snprintf(colmap_name, result_name_len, "%s.bin", filename);

    fw = fopen(colmap_name, "wb");
    fwrite(&data[0],1,map_size,fw);
    fclose(fw);

    free(colmap_name);

    for (y = 0; y < ctx.height; y++) free(ctx.row_pointers[y]);

    free(ctx.row_pointers);
    free(data);
    return 0;
}
