#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const int irqs[] = {17, 
                    19+17,
                  2*19+17,
                  3*19+17,
                  4*19+17,
                  5*19+17,
                  6*19+17,
                  7*19+17,
                  -1};

void dump_array(signed char *array)
{
    for(int i=0; i < 256; ++i)
    {
        if ((i % 16) == 0)
        {
            printf("\n!byte %d",array[i]);
        }
        else
        {
            printf(",%d",array[i]);
        }
    }
    printf("\n");
}

int main()
{
    signed char irq_nr[256];
    signed char irq_line[256];
    signed char spr_y[256];
    int y;
    for(int i=-256; i < 0; ++i)
    {
        int j;
        for(j = 0; j < 8; ++j)
        {
            y = i+j*21;
            if((y + 21 >= 0) /*&& (i+irqs[j] > 0)*/)
            {
                break;
            }
        }
        if (j < 8)
        {
            if (y < 0)
            {
                y += 56;
            }
            irq_nr[i+256] = j;
            irq_line[i+256] = i+irqs[j];
            if ((irq_line[i+256] >= -1) && (irq_line[i+256] < 4))
            {
                irq_line[i+256] = -2;
            }
            spr_y[i+256] = y;
            //printf("%d %d, %d\n", j, i+irqs[j], y);
        }
        else
        {
            irq_nr[i+256] = -1;
            irq_line[i+256] = 0;
            spr_y[i+256] = -1;
            //printf("0xff\n");
        }
    }
    printf("\nirq_nr_tab:");
    dump_array(irq_nr);
    printf("\nirq_line_tab:");
    dump_array(irq_line);
    printf("\nirq_spry_tab:");
    dump_array(spr_y);
    return 0;
}
