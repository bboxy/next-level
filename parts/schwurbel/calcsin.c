#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int main(void)
{
    FILE *f;
    unsigned char ar[257];
    int i;
    
    double w,v;
    for (i=0,w=0; w < M_PI*2; w += M_PI/128.0, ++i)
    {
        v = sin(w)*100.0 + 155.0;
        //printf("%d %lf\n", i, v);
        ar[i] = (unsigned char)v;
    }
    f = fopen("sintab", "wb");
    fwrite(ar, 1, 256, f);
    fclose(f);
    
    for (i=0,w=0; w < M_PI*2; w += M_PI/128.0, ++i)
    {
        v = sin(w)*95.0 + 96.0;
        //printf("%d %lf\n", i, v);
        ar[i] = (unsigned char)v;
    }
    f = fopen("sintab2", "wb");
    fwrite(ar, 1, 256, f);
    fclose(f);

    for (i=0,w=0; w < M_PI*2; w += M_PI/128.0, ++i)
    {
        v = sin(w)*63.0 + sin(w/2.0)*32.0 + 96.0;
        printf("%d %lf\n", i, v);
        ar[i] = (unsigned char)v;
    }
    f = fopen("sintab3", "wb");
    fwrite(ar, 1, 256, f);
    fclose(f);
    
    return 0;
}
