/* iAN CooG/HVSC */
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

/*****************************************************************************/
int main(int argc, char *argv[])
/*****************************************************************************/
{
    FILE *input;
    unsigned char cp;
    int  inbyte,counter;
    char p[5];

    if(!argv[1])
    {
        printf("Convert heX v0.2\r\n");
        printf("Usage: CX filename [-s/-strip_loadaddress]\r\n");
        exit(1);
    }

    if((input=fopen(argv[1],"rb"))!=NULL)
    {
        counter=0;
        if( (argc>2) && (strnicmp(argv[2],"-S",2)==0) )
        {
            fgetc(input);
            fgetc(input);
        }
        if( (inbyte=fgetc(input))!=-1 )
        {
            while(1) /*(!feof(input))*/
            {

                cp=(unsigned char)(inbyte&0xff);
                if( counter==0)
                    printf("\tbyte ");
                sprintf(p,"$%02X",cp);

                p[4]='\0';
                printf("%s",p);
                p[0]='\0';
                p[1]='\0';
                if( (inbyte=fgetc(input)) == -1L )
                {
                    printf("\n");
                    break;
                }
                counter++;
                if(counter<16)
                    printf(",");
                else
                {
                    printf("\n");
                    counter=0;
                }

            }
        }

    }
    printf("\n");
    fclose(input);
    return 0;

}
