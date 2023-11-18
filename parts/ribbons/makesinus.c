#include <math.h>
#include <stdio.h>
#include <inttypes.h>

#define PI atan2 (0.0, -1.0)

int main() {
    int8_t result[0x0800] = { 0 };
    FILE* fw;

    int a;

    for (a = 0; a < 256; a++) {
        result[a + 0x000] = round(sin(2.0 * PI * (0x00 + a) / (float)100) * 0x18) + 0x48;
        result[a + 0x100] = round(sin(2.0 * PI * (0x00 - a) / (float)120) * 0x18) + 0xe0;
        result[a + 0x200] = round(sin(2.0 * PI * (0x00 + a) / (float)90) * 0x18) + 0x70;
        result[a + 0x300] = round(sin(2.0 * PI * (0x60 - a) / (float)140) * 0x18) + 0x90;
        result[a + 0x400] = round(sin(2.0 * PI * (0x60 + a) / (float)78) * 0x18) + 0xc0;
        result[a + 0x500] = round(sin(2.0 * PI * (0xa0 - a) / (float)156) * 0x18) + 0x30;
        result[a + 0x600] = round(sin(2.0 * PI * (0xc0 + a) / (float)78) * 0x18) + 0x118;
        result[a + 0x700] = round(sin(2.0 * PI * (0xe0 - a) / (float)156) * 0x18) + 0x128;
    }

    fw = fopen("sinus.bin", "wb");
    fwrite(&result[0],1,8*256,fw);
    fclose(fw);
    return 0;
}
