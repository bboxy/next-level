#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>

#define MIX_START_VAL	55

int num_clear = 0;
int num_d418 = 0;
int num_nops = 0;
int wrote_ldy = 0;

void fatal(const char* s, ...) {
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        exit(2);
}

//black+white sind alles $d418 writes, cyan sind clear writes (dürften mehr als 156 sein, brauchst nur die ersten 156 nehmen), purple muss zu einem $0b -> $d021 umgebaut werden

void print_clear(int do_d011, int do_reg) {
    if (!do_reg) {
        printf("\t\t\tldy #$00\n");
        if (num_clear < 96) {
            printf("clear%d\t\t\tsty plotsprites + $000\n",num_clear);
        } else {
            printf("clear%d\t\t\tsty plotsprites + $100\n",num_clear);
        }
        num_clear++;
    } else {
        num_nops++;
        num_nops++;
        num_nops++;
    }
}

void write_clears() {
    while(num_nops) {
        if (!wrote_ldy) {
            printf("\t\t\tldy #$00\n");
            wrote_ldy = 1;
            num_nops--;
        }
        if (num_nops >= 2 && num_clear < 156) {
            if (num_clear < 96) {
                printf("clear%d\t\t\tsty plotsprites + $000\n",num_clear);
            } else {
                printf("clear%d\t\t\tsty plotsprites + $100\n",num_clear);
            }
            num_clear++;
            num_nops--;
            num_nops--;
        } else {
            printf("\t\t\tnop\n");
            num_nops--;
        }
    }
}

void do_reg(unsigned char col, int reg, int do_d011, int do_nop) {
    int do_d418 = 0;
    int do_clear = 0;
    if (!do_nop) {
        write_clears();
        wrote_ldy = 1;
    }
    if ((col & 0xf0) == 0) reg |= 0xd000;
    if ((col & 0xf0) == 0x10) {
        reg = (col & 0xf) | 0xd000;
        col = 0xd4;
    }
    else if ((col & 0xf0) == 0x20) {
        if ((col & 0xf) == 0 || (col & 0xf) == 1) {
            reg = 0xd418;
            do_d418 = 1;
        } else if ((col & 0xf) == 3) {
            if (num_clear < 156) do_clear = 1;
 	    reg = 0xdbff;
        } else if ((col & 0xf) == 4) {
            col = 0xb;
            reg = 0xd021;
        } else {
 	    reg = 0xd020;
        }
    }
    else if ((col & 0xf0) > 0x20) {
        reg = (col >> 4) | 0xd020;
    } else {
        reg |= 0xd000;
    }
    if (do_clear) {
        print_clear(do_d011, do_nop);
    } else if (do_d418) {
        printf("mix%d\t\t\tldy #$00\n",num_d418 + MIX_START_VAL);
        if (do_d011) printf("\t\t\tstx $d011\n");
        printf("\t\t\tsty $d418\n");
        num_d418++;
    } else {
        if (reg == 0xdbff) {
            printf("\t\t\tnop\n");
            if (do_d011) printf("\t\t\tstx $d011\n");
            printf("\t\t\tnop\n");
            printf("\t\t\tnop\n");
        } else {
            printf("\t\t\tldy #$%02x\n", col);
            if (do_d011) printf("\t\t\tstx $d011\n");
            printf("\t\t\tsty $%04x\n", reg);
        }
    }
}

void do_regs(unsigned char col1, unsigned char col2, unsigned char col3, unsigned char col4, unsigned char col5, unsigned char col6, int do_d011) {
    wrote_ldy = 0;
    do_reg(col1, 0x28, do_d011, 0);
    do_reg(col2, 0x29, 0, 0);
    do_reg(col3, 0x2a, 0, col3 == col2 && col2 == 0x23);
    do_reg(col4, 0x2b, 0, col4 == col3 && col3 == 0x23);
    do_reg(col5, 0x2c, 0, col5 == col4 && col4 == 0x23);
    do_reg(col6, 0x2d, 0, col6 == col5 && col5 == 0x23);
    write_clears();
}

void do_d018(unsigned char d018) {
    if (d018 < 0x8) {
        printf("patchdd00val\t\tldy #$01\n");
        printf("\t\t\tsty $dd00\n");
    } else {
        printf("\t\t\tldy #$%02x\n", d018);
        printf("\t\t\tsty $d018\n");
    }
}

void do_block0(unsigned char col1, unsigned char col2, unsigned char col3, unsigned char col4, unsigned char col5, unsigned char col6, unsigned char d018, unsigned char d011) {
    do_regs(col1, col2, col3, col4, col5, col6, 0);
    do_d018(d018);
    printf("\t\t\tldy #$3c\n");
    printf("\t\t\tsty $d011\n");
}

void do_block1(unsigned char col1, unsigned char col2, unsigned char col3, unsigned char col4, unsigned char col5, unsigned char col6, unsigned char d018, unsigned char d011) {
    do_regs(col1, col2, col3, col4, col5, col6, 0);
    do_d018(d018);
}

void do_block2(unsigned char col1, unsigned char col2, unsigned char col3, unsigned char col4, unsigned char col5, unsigned char col6, unsigned char d018, unsigned char d011) {
    do_regs(col1, col2, col3, col4, col5, col6, 1);
    do_d018(d018);
}

void do_block3(unsigned char col1, unsigned char col2, unsigned char col3, unsigned char col4, unsigned char col5, unsigned char col6, unsigned char d018, unsigned char d011) {
    printf("\t\t\tsta $d011\n");
    do_regs(col1, col2, col3, col4, col5, col6, 0);
    do_d018(d018);
    if (d011) {
        printf("\t\t\tldy #$%02x\n",d011);
    } else {
        printf("\t\t\tldy d011temp\n");
    }
    printf("\t\t\tsty $d011\n");
}

int main(int argc, char *argv[]) {
    int l;
    unsigned char col1[101];
    unsigned char col2[101];
    unsigned char col3[101];
    unsigned char col4[101];
    unsigned char col5[101];
    unsigned char col6[101];
    unsigned char d018[101];
    FILE* fw;

    char* filename;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s filename.nuf\n", *argv);
        exit (2);
    }
    argv++;
    argc--;

    if (!argc) fatal("no filename given.");

    filename = *argv;
    fw = fopen(filename,"rb");
    if (!fw) fatal("File %s not found", filename);
    fseek(fw, 0x402, SEEK_SET);
    if (fread(col1, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0x482, SEEK_SET);
    if (fread(col2, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0x802, SEEK_SET);
    if (fread(col3, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0x882, SEEK_SET);
    if (fread(col4, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0xc02, SEEK_SET);
    if (fread(col5, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0xc82, SEEK_SET);
    if (fread(col6, 1, 101, fw) != 101) fatal("file too short.");
    fseek(fw, 0x134e, SEEK_SET);
    if (fread(d018, 1, 101, fw) != 101) fatal("file too short.");

    col2[100] = 0x20;
    l = 0;
    do_block3(col1[l + 1], col2[l + 1], col3[l + 1], col4[l + 1], col5[l + 1], col6[l + 1], d018[l], 0x3a);
    for (l = 1; l < 100; l++) {
        if ((l & 3) == 1) do_block0(col1[l + 1], col2[l + 1], col3[l + 1], col4[l + 1], col5[l + 1], col6[l + 1], d018[l], 0x00);
        if ((l & 3) == 2) do_block1(col1[l + 1], col2[l + 1], col3[l + 1], col4[l + 1], col5[l + 1], col6[l + 1], d018[l], 0x00);
        if ((l & 3) == 3) do_block2(col1[l + 1], col2[l + 1], col3[l + 1], col4[l + 1], col5[l + 1], col6[l + 1], d018[l], 0x00);
        if ((l & 3) == 0) do_block3(col1[l + 1], col2[l + 1], col3[l + 1], col4[l + 1], col5[l + 1], col6[l + 1], d018[l], 0x00);
    }
    printf("\t\t\tldy #$10\n");
    printf("\t\t\tsty $d011\n");
    printf("\t\t\trts\n");

    fclose(fw);

    return 0;
}
