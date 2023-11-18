#include <math.h>
#include <stdio.h>
#include <inttypes.h>

#define PI atan2 (0.0, -1.0)

int main() {
    int8_t result[0x8000] = { 0 };
    FILE* fw;

    float d,z0,r;
    int z,q,i,c,a,x,q2;
    int degrees = 180;
    int dy,y, pos;

    r = 0x1f;
    for (a = 0; a < degrees; a++) {
        result[a+0x000] = round(sin(2.0 * PI * a / (float)degrees) * r);
        result[a+0x100] = round(cos(2.0 * PI * a / (float)degrees) * r);
    }

    for (a = 0; a < 256; a++) {
        result[a+0x1000] = round(sin(2.0 * PI * a / (float)256) * 0x50) + 0x70;
    }
    //for(a = 0; a < 128; a++) {
    //    result[a+0x1000] = 0xb8 / 128.0 * a + 16;
    //    result[0x1000+255-a] = 0xb8 / 128.0 * a + 16;
   // }
    for (a = 0; a < 256; a++) {
        result[a+0x1100] = (int)(0x1f-round(sin(2.0 * PI * a / (float)256) * 0x1f)) & 0xff; //0x2f
        //result[a+0x1100+48] = (int)(0x3f-round(sin(2.0 * PI * a / (float)96) * 0x3f)) & 0xff;
    }

//was 312.0
    d = 158.0; z0 = 3.0;
    for (i = 0; i < 0x100; i++) {
        z = i;
        if(z > 127) z = z - 256;
        q = round(d/(z0-z/64.0));
//        if(q > 127) q = 127;
//        if(q < -127) q = -127;
//        if(q < 0) q = 256 + q;

        if(i<128) result[0x200+i+128] = q + 0x80;
        else result[0x200+i-128] = q + 0x80;
    }
    for(i = 0; i < 0x200; i++) {
        x = i & 255;
        if(x > 127) x = 256 - x;
        q = round(x*x/256.0);
        result[0x300+i] = (q & 0xff);
        result[0x500+i] = (q & 0xff) + 0x40;
        result[0x700+i] = (q & 0xff) + 0x80;
        //q = round((x+1)*(x)/256.0);
        result[0x900+i-1] = (q & 0xff);
    }
    for(i = 0; i < 0x80; i++) {
        q = round(i / 2.0);
        result[0xb00+i] = q;
    }
    for(i = 0; i < 0x80; i++) {
        q = round((i - 128) / 2.0);
        result[0xb80+i] = q;
    }

//    pos = 0;
//    for(y = 0; y < 128; y++) {
//        result[0x0c00+y] = pos & 0xff;
//        result[0x0c80+y] = pos >> 8;
//        x = 0;
//        if(y == 0) {
//            x = 0;
//            printf("%d",x);
//            result[0x1000+pos] = x;
//            pos++;
//        } else {
//            for(dy = 0; dy <=y; dy++) {
//                x = 127 * dy / y;
//                printf("%d ",x);
//                result[0x1000+pos] = x;
//                pos++;
//            }
//        }
//        printf("\n");
//    }

    fw = fopen("sinus.bin", "wb");
    c = 0x00;
    fwrite(&c,1,1,fw);
    c = 0x40;
    fwrite(&c,1,1,fw);
    fwrite(&result[0],1,0x8000,fw);
    fclose(fw);
    return 0;
}
