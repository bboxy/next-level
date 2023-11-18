#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>


#define BGCOL	0xe

typedef struct ctx {
    png_bytep * row_pointers;
    png_byte color_type;
    png_byte bit_depth;
    int width;
    int height;
    int bg;
} ctx;

void fatal(const char* s, ...) {
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        exit(2);
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

void to_koala (ctx* ctx, unsigned char* data, unsigned char* bitmap, unsigned char* screen, unsigned char* colram) {
    int block_x, block_y;
    unsigned char color;
    int x, y;
    int mc1;
    int mc2;
    int cr;
    unsigned char byte;

    for (block_y = 0; block_y < 25; block_y++) {
        for (block_x = 0; block_x < 40; block_x++) {
            mc1 = -1;
            mc2 = -1;
            cr = -1;
            for (y = 0; y < 8; y++) {
                for (x = 0; x < 8; x += 2) {
                    color = data[(block_y * 8 + y) * ctx->width + (block_x * 8) + x];
                    if (color != ctx->bg) {
                        if (mc1 == -1) mc1 = color;
                        else if (mc2 == -1 && mc1 != color) mc2 = color;
                        else if (cr == -1 && mc1 != color && mc2 != color) cr = color;
                        else if (cr != color && mc1 != color && mc2 != color) {
                            printf("clash @ x=%03x y=$%02x\n", block_x, block_y);
                        }
                    }
                }
            }
            if (cr < 0) cr = 0;
            if (mc1 < 0) mc1 = 0;
            if (mc2 < 0) mc2 = 0;

            colram[block_y * 40 + block_x] = cr;
            screen[block_y * 40 + block_x] = mc1 << 4 | mc2;

            for (y = 0; y < 8; y++) {
                byte = 0;
                for (x = 0; x < 8; x += 2) {
                    byte <<= 2;
                    color = data[(block_y * 8 + y) * ctx->width + (block_x * 8) + x];
                    if (color == mc1) {
                        byte |= 1;
                    }
                    if (color == mc2) {
                        byte |= 2;
                    }
                    if (color == cr) {
                        byte |= 3;
                    }
                }
                bitmap[block_y * 320 + block_x * 8 + y] = byte;
            }
        }
    }
    return;
}

int present(unsigned char* bitmap, int pix) {
    int y;
    unsigned char byte;
    int shifts;
    int count = 0;

    for (y = 0; y < 8; y++) {
        byte = bitmap[y];
        for (shifts = 0; shifts < 4; shifts++) {
           if ((byte & 0x3) == pix) count++;
           byte >>= 2;
        }
    }
    return count;
}

void remap(unsigned char* bitmap, unsigned char* dest, int from, int to) {
    int shifts;
    int y;
    for (y = 0; y < 8; y++) {
        for (shifts = 0; shifts < 8; shifts += 2) {
            if ((bitmap[y] & (0x3 << shifts)) == (from << shifts)) dest[y] |= (to << shifts);
        }
    }
    return;
}

int main () {
    unsigned char* data;

    char* filename = "waves_bgtest.png";

    ctx ctx;
    ctx.width = 320;
    ctx.height = 200;
    ctx.bg = 0xe;

    unsigned char* bitmap;
    unsigned char* screen;
    unsigned char* colram;

    unsigned char bitmap_fin[8000] = { 0 };
    unsigned char screen_fin[40] = { 0 };
    unsigned char colram_fin[40] = { 0 };

    int x, y;
    int mc1, mc2, mc3;
    int c1, c2, c3;

    FILE* fw;

    load_png(&ctx, filename);

    data = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height);
    bitmap = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height);
    screen = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height / 8);
    colram = (unsigned char*) malloc(sizeof(unsigned char) * ctx.width * ctx.height / 8);

    to_c64_palette(&ctx, data);
    to_koala(&ctx, data, bitmap, screen, colram);

    free(data);

    fw = fopen("clean.kla", "wb");

    for (x = 0; x < 40; x++) {

        mc1 = -1;
        mc2 = -1;
        mc3 = -1;

        for (y = 0; y < 25; y++) {

            c1 = screen[y * 40 + x] >> 4;
            c2 = screen[y * 40 + x] & 0xf;
            c3 = colram[y * 40 + x] & 0xf;

            if (mc1 < 0) {
                if (present(bitmap + x * 8 + y * 320, 1) > 0 && c1 != mc2 && c1 != mc3 && c1 != BGCOL) mc1 = c1;
            }
            if (mc1 < 0) {
                if (present(bitmap + x * 8 + y * 320, 2) > 0 && c2 != mc2 && c2 != mc3 && c2 != BGCOL) mc1 = c2;
            }
            if (mc1 < 0) {
                if (present(bitmap + x * 8 + y * 320, 3) > 0 && c3 != mc2 && c3 != mc3 && c3 != BGCOL) mc1 = c3;
            }

            if (mc2 < 0) {
                if (present(bitmap + x * 8 + y * 320, 1) > 0 && c1 != mc1 && c1 != mc3 && c1 != BGCOL) mc2 = c1;
            }
            if (mc2 < 0) {
                if (present(bitmap + x * 8 + y * 320, 2) > 0 && c2 != mc1 && c2 != mc3 && c2 != BGCOL) mc2 = c2;
            }
            if (mc2 < 0) {
                if (present(bitmap + x * 8 + y * 320, 3) > 0 && c3 != mc1 && c3 != mc3 && c3 != BGCOL) mc2 = c3;
            }

            if (mc3 < 0) {
                if (present(bitmap + x * 8 + y * 320, 1) > 0 && c1 != mc1 && c1 != mc2 && c1 != BGCOL) mc3 = c1;
            }
            if (mc3 < 0) {
                if (present(bitmap + x * 8 + y * 320, 2) > 0 && c2 != mc1 && c2 != mc2 && c2 != BGCOL) mc3 = c2;
            }
            if (mc3 < 0) {
                if (present(bitmap + x * 8 + y * 320, 3) > 0 && c3 != mc1 && c3 != mc2 && c3 != BGCOL) mc3 = c3;
            }

            //takefirst color of screen, lookup pixels in this color in block, if present, set first color to != -1, if done, fill up color2 and if still done, fill up color -3, and remap all pixels to right dest pixelnum
        }

        for (y = 0; y < 25; y++) {

            c1 = screen[y * 40 + x] >> 4;
            c2 = screen[y * 40 + x] & 0xf;
            c3 = colram[y * 40 + x] & 0xf;

            if (mc1 == c1) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 1, 1);
            if (mc1 == c2) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 2, 1);
            if (mc1 == c3) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 3, 1);

            if (mc2 == c1) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 1, 2);
            if (mc2 == c2) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 2, 2);
            if (mc2 == c3) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 3, 2);

            if (mc3 == c1) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 1, 3);
            if (mc3 == c2) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 2, 3);
            if (mc3 == c3) remap(bitmap + x * 8 + y * 320, bitmap_fin + x * 8 + y * 320, 3, 3);
        }

        //printf ("%1x %1x %1x\n", mc1, mc2, mc3);
        screen_fin[x] = (mc1 << 4) | (mc2 & 0xf);
        colram_fin[x] = (mc3 & 0xf);
    }

    fwrite(bitmap_fin,1,8000,fw);
    fwrite(screen_fin,1,40,fw);
    fwrite(colram_fin,1,40,fw);

    fclose(fw);
    free(bitmap);
    free(colram);
    free(screen);
    return 0;
}


