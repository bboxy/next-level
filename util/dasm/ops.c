
/*
*  OPS.C
*
*  (c)Copyright 1988, Matthew Dillon, All Rights Reserved.
*
*  Handle mnemonics and pseudo ops
*
*/

#include "asm.h"

ubyte    Gen[1<<10];
ubyte    OrgFill = DEFORGFILL;
int  Glen,lastrorg;

extern MNE    Mne6502[];
//extern MNE    Mne6803[];
//extern MNE    MneHD6303[];
//extern MNE    Mne68705[];
//extern MNE    Mne68HC11[];

void generate(void);
void genfill(long fill, long bytes, int size);
void pushif(bool xbool);
int gethexdig(int c);

/*
*  An opcode modifies the SEGMENT flags in the following ways:
*/

void v_processor(char *str, MNE *dummy)
{
    static int    called=1;

    if (called)
        return;
//
//  called = 1;
//  if (strcmp(str,"6502") == 0) {
//      addhashtable(Mne6502);
//      MsbOrder = 0;       /*  lsb,msb */
//      Processor = 6502;
//  }
//  if (strcmp(str,"6803") == 0) {
//      addhashtable(Mne6803);
//      MsbOrder = 1;       /*  msb,lsb */
//      Processor = 6803;
//  }
//  if (strcmp(str,"HD6303") == 0 || strcmp(str, "hd6303") == 0) {
//      addhashtable(Mne6803);
//      addhashtable(MneHD6303);
//      MsbOrder = 1;       /*  msb,lsb */
//      Processor = 6303;
//  }
//  if (strcmp(str,"68705") == 0) {
//      addhashtable(Mne68705);
//      MsbOrder = 1;       /*  msb,lsb */
//      Processor = 68705;
//  }
//  if (strcmp(str,"68HC11") == 0 || strcmp(str, "68hc11") == 0) {
//      addhashtable(Mne68HC11);
//      MsbOrder = 1;       /*  msb,lsb */
//      Processor = 6811;
//  }
//  if (!Processor)
//  {
//      asmerr( ERROR_PROCESSOR_NOT_SUPPORTED, true, str );
//  }
}

#define badcode(mne,adrmode)  (!(mne->okmask & (1L << adrmode)))

void v_mnemonic(char *str, MNE *mne)
{
    int addrmode;
    SYMBOL *sym;
    uword opcode;
    short opidx;
    SYMBOL *symbase;
    int     opsize;

    Csegment->flags |= SF_REF;
    programlabel();
    symbase = eval(str, 1);

    if (Xtrace)
        printf("PC: %04x  MNE: %s  addrmode: %d  ",
           Csegment->org, mne->name, symbase->addrmode);
    for (sym = symbase; sym; sym = sym->next)
    {
        if (sym->flags & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_MNEMONIC_NOT_RESOLVED;
        }
    }
    sym = symbase;

    if (mne->flags & MF_IMOD)
    {
        if (sym->next)
        {
            sym->addrmode = AM_BITMOD;
            if ((mne->flags & MF_REL) && sym->next)
                sym->addrmode = AM_BITBRAMOD;
        }
    }
    addrmode = sym->addrmode;
    if ((sym->flags & SYM_UNKNOWN) || sym->value >= 0x100)
        opsize = 2;
    else
        opsize = (sym->value) ? 1 : 0;

    while (badcode(mne,addrmode) && Cvt[addrmode])
        addrmode = Cvt[addrmode];
    if (Xtrace)
        printf("mnemask: %08x adrmode: %d  Cvt[am]: %d\n",
        mne->okmask, addrmode, Cvt[addrmode]);

    if (badcode(mne,addrmode))
    {
        char sBuffer[128];
        sprintf( sBuffer, "%s %s", mne->name, str );
        asmerr( ERROR_ILLEGAL_ADDRESSING_MODE, false, sBuffer );
        freesymbollist(symbase);
        return;
    }

    if (Mnext >= 0 && Mnext < NUMOC)            /*  Force   */
    {
        addrmode = Mnext;

        if (badcode(mne,addrmode))
        {
            asmerr( ERROR_ILLEGAL_FORCED_ADDRESSING_MODE, false, mne->name );
            freesymbollist(symbase);
            return;
        }
    }

    if (Xtrace)
        printf("final addrmode = %d\n", addrmode);

    while (opsize > Opsize[addrmode])
    {
        if (Cvt[addrmode] == 0 || badcode(mne,Cvt[addrmode]))
        {
           char sBuffer[128];

           if (sym->flags & SYM_UNKNOWN)
                break;

            sprintf( sBuffer, "%s %s", mne->name, str );
            asmerr( ERROR_ADDRESS_MUST_BE_LT_100, false, sBuffer );
            break;
        }
        addrmode = Cvt[addrmode];
    }
    opcode = mne->opcode[addrmode];
    opidx = 1 + (opcode > 0xFF);
    if (opidx == 2)
    {
        Gen[0] = opcode >> 8;
        Gen[1] = opcode;
    }
    else
    {
        Gen[0] = opcode;
    }

    switch(addrmode)
    {
    case AM_BITMOD:
        sym = symbase->next;
        if (!(sym->flags & SYM_UNKNOWN) && sym->value >= 0x100)
            asmerr( ERROR_ADDRESS_MUST_BE_LT_100, false, NULL );
        Gen[opidx++] = sym->value;

        if (!(symbase->flags & SYM_UNKNOWN))
        {
            if (symbase->value > 7)
                asmerr( ERROR_ILLEGAL_BIT_SPECIFICATION, false, str );
            else
                Gen[0] += symbase->value << 1;
        }
        break;

    case AM_BITBRAMOD:

        if (!(symbase->flags & SYM_UNKNOWN))
        {
            if (symbase->value > 7)
                asmerr( ERROR_ILLEGAL_BIT_SPECIFICATION, false, str );
            else
                Gen[0] += symbase->value << 1;
        }

        sym = symbase->next;

        if (!(sym->flags & SYM_UNKNOWN) && sym->value >= 0x100)
            asmerr( ERROR_ADDRESS_MUST_BE_LT_100, false, NULL );

        Gen[opidx++] = sym->value;
        sym = sym->next;
        break;

    case AM_REL:
        break;

    default:
        if (Opsize[addrmode] > 0)
            Gen[opidx++] = sym->value;
        if (Opsize[addrmode] == 2)
        {
            if (MsbOrder)
            {
                Gen[opidx-1] = sym->value >> 8;
                Gen[opidx++] = sym->value;
            }
            else
            {
                Gen[opidx++] = sym->value >> 8;
            }
        }
        sym = sym->next;
        break;
    }

    if (mne->flags & MF_MASK)
    {
        if (sym)
        {
            if (!(sym->flags & SYM_UNKNOWN) && sym->value >= 0x100)
                asmerr( ERROR_ADDRESS_MUST_BE_LT_100, false, NULL );

            Gen[opidx] = sym->value;
            sym = sym->next;
        }
        else
        {
            asmerr( ERROR_NOT_ENOUGH_ARGS, true, NULL );
        }

        ++opidx;
    }

    if ((mne->flags & MF_REL) || addrmode == AM_REL)
    {
        ++opidx;        /*  to end of instruction   */

        if (!sym)
            asmerr( ERROR_NOT_ENOUGH_ARGS, true, NULL );
        else if (!(sym->flags & SYM_UNKNOWN))
        {
            long    pc;
            ubyte   pcf;
            long    dest;

            pc = (Csegment->flags & SF_RORG) ? Csegment->rorg : Csegment->org;
            pcf= (Csegment->flags & SF_RORG) ? Csegment->rflags : Csegment->flags;

            if ((pcf & (SF_UNKNOWN|2)) == 0)
            {
                dest = sym->value - pc - opidx;
                if (dest >= 128 || dest < -128)
                {
                    char sBuffer[64];
                    sprintf( sBuffer, "%d", (int)dest );
                    asmerr( ERROR_BRANCH_OUT_OF_RANGE, true, sBuffer );

                }
            }
            else
            {
                /* Don't bother - we'll take another pass */
                dest = 0;
            }
            Gen[opidx-1] = dest & 0xFF;     /*  byte before end of inst.    */
        }
    }
    Glen = opidx;
    generate();
    freesymbollist(symbase);
}

void v_trace(char *str, MNE *dummy)
{
    if (str[1] == 'n')
        Xtrace = 1;
    else
        Xtrace = 0;
}

void v_list(char *str, MNE *dummy)
{
    programlabel();

    Glen = 0;       /*  Only so outlist() works */
#if OlafList
    if (strncmp(str, "localoff", 7) == 0 || strncmp(str, "LOCALOFF", 7) == 0)
        Incfile->flags |=  INF_NOLIST;
    else if (strncmp(str, "localon", 7) == 0 || strncmp(str, "LOCALON", 7) == 0)
        Incfile->flags &= ~INF_NOLIST;
    else
#endif
        if (strncmp(str, "off", 2) == 0 || strncmp(str, "OFF", 2) == 0)
            ListMode = 0;
        else
            ListMode = 1;
}

char * getfilename(char *str)
{
    if (*str == '\"')
    {
        char    *buf;

        str++;
        buf = ckmalloc(strlen(str)+1);
        strcpy(buf, str);

        for (str = buf; *str && *str != '\"'; ++str);
        *str = 0;

        return buf;
    }
    return str;
}

void v_include(char *str, MNE *dummy)
{
    char    *buf;

    programlabel();
    buf = getfilename(str);

    pushinclude(buf);

    if (buf != str)
        free(buf);
}

#if OlafIncbin
/* taken from TLR dasm */
#define warning_fmt printf
#define fatal_fmt   printf
#define error_fmt   printf
static int do_incbin(const char *name, int offs, int len)
{
    FILE *binfile;
    int reterr=0;
    programlabel();

    binfile = pfopen(name, "rb");
    if (binfile != NULL) {
        int flen;
        int left;
        fseek(binfile, 0, SEEK_END);
        flen = ftell(binfile);

        left = flen - offs;
        if (offs > 0 && left <= 0)
        {
            warning_fmt("Offset %d is outside the file '%s'.\n", offs, name);
            left=0;
            offs=0;
        }
        else
        {
            if (len >= 0)
            {
                if (len <= left)
                {
                    left = len;
                } else
                {
                    warning_fmt("Length %d means reading outside the file '%s'. Truncating.\n", len, name);
                }
            }
        }

        if (Redo != 0) {
            /* optimize: don't actually read the file if not needed */
            Glen = left;
            generate();     /* does not access Gen[] if Redo is set */
        }
        else
        {
            fseek(binfile, offs, SEEK_SET);
            while (left)
            {
                size_t rlen;
                rlen = ((size_t)left < sizeof(Gen)) ? (size_t)left : sizeof(Gen);
                Glen = fread(Gen, 1, rlen, binfile);
                if (Glen <= 0)
                {
                    break;
                }
                generate();
                left-=rlen;
            }
        }
        if (fclose(binfile) != 0) {
            warning_fmt("Problem closing binary include file '%s'.\n", name);
        }
    }
    else {
        warning_fmt("Unable to open binary include file '%s'.\n", name);
        reterr=1;
    }
    return reterr;
}

/* TLR version only accepts filenames between quotes, I don't like it, redone my way */
void v_incbin(char *str, MNE *dummy)
{
    char *name,*p,*q;
    int offs;
    int len,reterr=0;
    SYMBOL *sym;

    if(str == NULL)
    {
        printf("incbin: parameter is NULL\n");
        exit(1);
        return;
    }
    name="";
    programlabel();
    offs=0;
    len=-1;
    name = getfilename(str);

    if((p=strchr(str,','))!=NULL)
    {
        *p=0;
        p++;
        if((q=strchr(p,','))!=NULL)
        {
            *q=0;
            q++;
            sym=eval(q,1);
            len=sym->value;
            freesymbollist(sym);

            if (len < 0)
            {
                error_fmt("incbin: length was %d but must be >= 0!\n", len);
                reterr=1;
            }
        }
        sym=eval(p,1);
        offs=sym->value;
        freesymbollist(sym);
        if (offs < 0)
        {
            error_fmt("incbin: offset was %d but must be >= 0!\n", offs);
            reterr=1;
        }
    }

    reterr=do_incbin(name, offs, len);

    Glen = 0;           /* don't list hexdump */
    //  6/11/18 fatal include error, quit program
    if(reterr)
    {
    	error_fmt("Aborting\r\n");
    	exit(1);
    }
}
/* old version */
#if 0
void v_incbin(char *str, MNE *dummy)
{
    char    *buf;
    FILE    *binfile;

    programlabel();
    buf = getfilename(str);

    binfile = pfopen(buf, "rb");
    if (binfile)
    {
        if (Redo)
        {
            /* optimize: don't actually read the file if not needed */
            fseek(binfile, 0, SEEK_END);
            Glen = ftell(binfile);
            generate();     /* does not access Gen[] if Redo is set */
        }
        else
        {
            for (;;)
            {
                Glen = fread(Gen, 1, sizeof(Gen), binfile);
                if (Glen <= 0)
                    break;
                generate();
            }
        }
        fclose(binfile);
    }
    else
    {
        printf("unable to open %s\n", buf);
    }

    if (buf != str)
        free(buf);
    Glen = 0;           /* don't list hexdump */
}
#endif


/* -=[iAN CooG/HVSC]=- */
void v_incprg(char *str, MNE *dummy)
{
    char    *buf;
    FILE    *binfile;
    char *p;
    int reterr=0;
    int read_len;
    programlabel();
    if((p=strchr(str,','))!=NULL)
    {
        *p=0;
        p++;
        if((*p=='$')||(strchr("0123456789",*p)!=NULL))
        {   /* incprg file.prg,$1000 = force org to $1000 */
            v_org(p, dummy);
        }
        else if((*p&0xdf) == 'L')
        {   /* incprg file.prg,l = force org to original loadaddr */
            char temp[4]={0},neworg[8]={0};
            buf = getfilename(str);
            binfile = pfopen(buf, "rb");
            if (binfile)
            {
                read_len = fread(temp, 1, 2, binfile);
                fclose( binfile);
                if (read_len < 0) return;
                sprintf(neworg,"%d",*(unsigned short int*)temp);
                v_org(neworg, dummy);
            }
        }
    }
    buf = getfilename(str);
    binfile = pfopen(buf, "rb");
    if (binfile)
    {
        if (Redo)
        {
            /* optimize: don't actually read the file if not needed */
            fseek(binfile, 0, SEEK_END);
            Glen = ftell(binfile);
            generate();     /* does not access Gen[] if Redo is set */
        }
        else
        {
            fseek(binfile, 2, SEEK_SET);
            for (;;)
            {

                Glen = fread(Gen, 1, sizeof(Gen), binfile);
                if (Glen <= 0)
                    break;
                generate();
            }
        }
        fclose(binfile);
    }
    else
    {
        printf("incprg: unable to open '%s'\n", buf);
        reterr=1;
    }

    if (buf != str)
        free(buf);
    Glen = 0;           /* don't list hexdump */
    //  6/11/18 fatal include error, quit program
    if(reterr)
    {
    	error_fmt("Aborting\r\n");
    	exit(1);
    }
}

#endif

void v_seg(char *str, MNE *dummy)
{
    SEGMENT *seg;

    for (seg = Seglist; seg; seg = seg->next)
    {
        if (strcmp(str, seg->name) == 0)
        {
            Csegment = seg;
            programlabel();
            return;
        }
    }
    Csegment = seg = (SEGMENT *)zmalloc(sizeof(SEGMENT));
    seg->next = Seglist;
    seg->name = strcpy(ckmalloc(strlen(str)+1), str);
    seg->flags= seg->rflags = seg->initflags = seg->initrflags = SF_UNKNOWN;
    Seglist = seg;
    if (Mnext == AM_BSS)
        seg->flags |= SF_BSS;
    programlabel();
}

void v_hex(char *str, MNE *dummy)
{
    int i;
    int result;

    programlabel();
    Glen = 0;
    for (i = 0; str[i]; ++i)
    {
        if (str[i] == ' ')
            continue;
        result = (gethexdig(str[i]) << 4) + gethexdig(str[i+1]);
        if (str[++i] == 0)
            break;
        Gen[Glen++] = result;
    }
    generate();
}

int gethexdig(int c)
{
    char sBuffer[64];

    if (c >= '0' && c <= '9')
        return(c - '0');

    if (c >= 'a' && c <= 'f')
        return(c - 'a' + 10);

    if (c >= 'A' && c <= 'F')
        return(c - 'A' + 10);

    sprintf( sBuffer, "Bad Hex Digit %c", c );
    asmerr( ERROR_SYNTAX_ERROR, false, sBuffer );

    puts("(Must be a valid hex digit)");
    if (F_listfile)
        fputs("(Must be a valid hex digit)\n", FI_listfile);

    return(0);
}

void v_err(char *str, MNE *dummy)
{
    programlabel();
    asmerr( ERROR_ERR_PSEUDO_OP_ENCOUNTERED, true, NULL );
    exit(1);
}

static unsigned char ascii2petscii (unsigned char c)
{
  if (c >= 'A' && c <= 'Z') /* convert upper case letters */
    c -= 'A' - 0xC1;
  else if (c >= 'a' && c <= 'z') /* convert lower case letters */
    c -= 'a' - 0x41;
  //else if ((c & 127) < 32) /* convert control characters */
    //c = '-';
  else if (c == 0xa0); /* do not touch shifted spaces */
  //else if (c > 'z') /* convert graphics characters */
    //c = '+';

  return c;
}

void v_dc(char *str, MNE *mne)
{
    SYMBOL *sym;
    SYMBOL *tmp;
    ulong  value;
    char *macstr = 0;       /* "might be used uninitialised" */
    char vmode = 0;
    char tempstr[2048];
    Glen = 0;
    programlabel();
#if OlafByte
    /* for byte, .byte, word, .word, long, .long */
    if (mne->name[0] != 'd')
    {
        static char tmp[4];
        strcpy(tmp, "x.x");
        tmp[2] = mne->name[0];
        findext(tmp);
    }
#endif
//#if scr_ul
    if(mne->name[0] == 's')
    {
        int i,s;

        unsigned char *ascp,*tptr;
        unsigned char tab[8]={0x80,0x20,0x00,0x40,0xC0,0x60,0x40,0x60 };
        *tempstr=0;
        ascp=(unsigned char *)str;
        if(*ascp==0x22)
            ascp++;
        tptr=(unsigned char *)((char*)ascp+strlen((char*)ascp)-1);
        if(*tptr==0x22) *tptr=0;
        s=strlen((char*)ascp);
        tptr=(unsigned char *)tempstr;
        for(i=s;i;i--)
        {
            if(((*ascp&0xdf)>='A')&&((*ascp&0xdf)<='Z'))
            {
                if(mne->name[3] == 'u')
                {
                    *ascp&=0xdf;
                }
                if(mne->name[3] == 'l')
                {
                    *ascp^=0x20;
                }
            }
            if(*ascp==0xFF)
               *ascp=0x5e;
            else
            {
                unsigned char idx=(*ascp>>5);
                *ascp = (*ascp&0x1f)|tab[idx];
            }
            /* MTR/VRZ request: SCRLR for reversed chars */
            if(mne->name[4] == 'r')
            {
               *ascp|=0x80;
            }

            tptr+=sprintf((char*)tptr,"$%02x",*ascp);
            if(i>1)
                tptr+=sprintf((char*)tptr,",");
            ascp++;
        }

        str=tempstr;

    }
//#endif
//#if petc
    if (mne->name[0] == 'p'||mne->name[0] == 't')
    {
        unsigned char *ascp;
        ascp=(unsigned char*)str;
        while(*ascp)
        {
            *ascp=ascii2petscii(*ascp);
            ++ascp;
        }
    }
    if (mne->name[1] == 'v')
    {
        int i;
        vmode = 1;
        for (i = 0; str[i] && str[i] != ' '; ++i);
        tmp = findsymbol(str, i);
        str += i;
        if (tmp == NULL)
        {
            puts("EQM label not found");
            return;
        }
        if (tmp->flags & SYM_MACRO)
        {
            macstr = (void *)tmp->string;
        }
        else
        {
            puts("must specify EQM label for DV");
            return;
        }
    }
    sym = eval(str, 0);
    for (; sym; sym = sym->next)
    {
        value = sym->value;
        if (sym->flags & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_DC_NOT_RESOLVED;
        }
        if (sym->flags & SYM_STRING)
        {
            ubyte *ptr = (void *)sym->string;
            while ((value = *ptr) != 0)
            {
                if (vmode)
                {
                    setspecial(value, 0);
                    tmp = eval(macstr, 0);
                    value = tmp->value;
                    if (tmp->flags & SYM_UNKNOWN)
                    {
                        ++Redo;
                        Redo_why |= REASON_DV_NOT_RESOLVED_PROBABLY;
                    }
                    freesymbollist(tmp);
                }
                switch(Mnext)
                {
                default:
                case AM_BYTE:
                    Gen[Glen++] = value & 0xFF;
                    break;
                case AM_WORD:
                    if (MsbOrder)
                    {
                        Gen[Glen++] = (value >> 8) & 0xFF;
                        Gen[Glen++] = value & 0xFF;
                    }
                    else
                    {
                        Gen[Glen++] = value & 0xFF;
                        Gen[Glen++] = (value >> 8) & 0xFF;
                    }
                    break;
                case AM_LONG:
                    if (MsbOrder)
                    {
                        Gen[Glen++] = (value >> 24)& 0xFF;
                        Gen[Glen++] = (value >> 16)& 0xFF;
                        Gen[Glen++] = (value >> 8) & 0xFF;
                        Gen[Glen++] = value & 0xFF;
                    }
                    else
                    {
                        Gen[Glen++] = value & 0xFF;
                        Gen[Glen++] = (value >> 8) & 0xFF;
                        Gen[Glen++] = (value >> 16)& 0xFF;
                        Gen[Glen++] = (value >> 24)& 0xFF;
                    }
                    break;
                }
                ++ptr;
            }
        }
        else
        {
            if (vmode)
            {
                setspecial(value, sym->flags);
                tmp = eval(macstr, 0);
                value = tmp->value;
                if (tmp->flags & SYM_UNKNOWN)
                {
                    ++Redo;
                    Redo_why |= REASON_DV_NOT_RESOLVED_COULD;
                }
                freesymbollist(tmp);
            }
            switch(Mnext)
            {
            default:
            case AM_BYTE:
                Gen[Glen++] = value & 0xFF;
                break;
            case AM_WORD:
                if (MsbOrder)
                {
                    Gen[Glen++] = (value >> 8) & 0xFF;
                    Gen[Glen++] = value & 0xFF;
                }
                else
                {
                    Gen[Glen++] = value & 0xFF;
                    Gen[Glen++] = (value >> 8) & 0xFF;
                }
                break;
            case AM_LONG:
                if (MsbOrder)
                {
                    Gen[Glen++] = (value >> 24)& 0xFF;
                    Gen[Glen++] = (value >> 16)& 0xFF;
                    Gen[Glen++] = (value >> 8) & 0xFF;
                    Gen[Glen++] = value & 0xFF;
                }
                else
                {
                    Gen[Glen++] = value & 0xFF;
                    Gen[Glen++] = (value >> 8) & 0xFF;
                    Gen[Glen++] = (value >> 16)& 0xFF;
                    Gen[Glen++] = (value >> 24)& 0xFF;
                }
                break;
            }
        }
    }
    generate();
    freesymbollist(sym);
}

void v_ds(char *str, MNE *dummy)
{
    SYMBOL *sym;
    int mult = 1;
    long filler = 0;

    if (Mnext == AM_WORD)
        mult = 2;
    if (Mnext == AM_LONG)
        mult = 4;
    programlabel();
    if ((sym = eval(str, 0)) != NULL)
    {
        if (sym->next)
            filler = sym->next->value;
        if (sym->flags & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_DS_NOT_RESOLVED;
        }
        else
        {
            if (sym->next && sym->next->flags & SYM_UNKNOWN)
            {
                ++Redo;
                Redo_why |= REASON_DS_NOT_RESOLVED;
            }
            genfill(filler, sym->value, mult);
        }
        freesymbollist(sym);
    }
}

void v_org(char *str, MNE *dummy)
{
    SYMBOL *sym;

    sym = eval(str, 0);
    Csegment->org = sym->value;

    if (sym->flags & SYM_UNKNOWN)
        Csegment->flags |= SYM_UNKNOWN;
    else
        Csegment->flags &= ~SYM_UNKNOWN;

    if (Csegment->initflags & SYM_UNKNOWN)
    {
        Csegment->initorg = sym->value;
        Csegment->initflags = sym->flags;
    }

    if (sym->next)
    {
        OrgFill = sym->next->value;
        if (sym->next->flags & SYM_UNKNOWN)
            asmerr( ERROR_VALUE_UNDEFINED, true, NULL );
    }

    programlabel();
    freesymbollist(sym);
}

void v_rorg(char *str, MNE *dummy)
{
    SYMBOL *sym = eval(str, 0);

    Csegment->flags |= SF_RORG;
    if (sym->addrmode != AM_IMP)
    {
        Csegment->rorg = sym->value;
        if (sym->flags & SYM_UNKNOWN)
            Csegment->rflags |= SYM_UNKNOWN;
        else
            Csegment->rflags &= ~SYM_UNKNOWN;
        if (Csegment->initrflags & SYM_UNKNOWN)
        {
            Csegment->initrorg = sym->value;
            Csegment->initrflags = sym->flags;
        }
    }
    programlabel();
    freesymbollist(sym);
}

void v_rend(char *str, MNE *dummy)
{
    programlabel();
    Csegment->flags &= ~SF_RORG;
}

void v_align(char *str, MNE *dummy)
{
    SYMBOL *sym = eval(str, 0);
    ubyte   fill = 0;
    ubyte   rorg = Csegment->flags & SF_RORG;

    if (rorg)
        Csegment->rflags |= SF_REF;
    else
        Csegment->flags |= SF_REF;
    if (sym->next)
    {
        if (sym->next->flags & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_ALIGN_NOT_RESOLVED;
        }
        else
        {
            fill = sym->value;
        }
    }
    if (rorg)
    {
        if ((Csegment->rflags | sym->flags) & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_ALIGN_RELOCATABLE_ORIGIN_NOT_KNOWN;
        }
        else
        {
            long n = sym->value - (Csegment->rorg % sym->value);
            if (n != sym->value)
                genfill(fill, n, 1);
        }
    }
    else
    {
        if ((Csegment->flags | sym->flags) & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_ALIGN_NORMAL_ORIGIN_NOT_KNOWN;
        }
        else
        {
            long n = sym->value - (Csegment->org % sym->value);
            if (n != sym->value)
                genfill(fill, n, 1);
        }
    }
    freesymbollist(sym);
    programlabel();
}

void v_subroutine(char *str, MNE *dummy)
{
    ++Lastlocalindex;
    Localindex = Lastlocalindex;
    programlabel();
}

void v_equ(char *str, MNE *dummy)
{
    SYMBOL *sym = eval(str, 0);
    SYMBOL *lab;

#if OlafDotAssign
    /*
    * If we encounter a line of the form
    *   . = expr    ; or . EQU expr
    * treat it as one of
    *     org expr
    *     rorg expr
    * depending on whether we have a relocatable origin now or not.
    */
    if (strlen(Av[0]) == 1 && (Av[0][0] == '.'
#if OlafStar
        || (Av[0][0] == '*' && (Av[0][0] = '.') && 1)
#endif
        ))
    {
        /* Av[0][0] = '\0'; */
        if (Csegment->flags & SF_RORG)
        {
            v_rorg(str, dummy);
        }
        else
        {
            v_org(str, dummy);
        }
        return;
    }
#endif

    lab = findsymbol(Av[0], strlen(Av[0]));
    if (!lab)
        lab = createsymbol(Av[0], strlen(Av[0]));
    if (!(lab->flags & SYM_UNKNOWN))
    {
        if (sym->flags & SYM_UNKNOWN)
        {
            ++Redo;
            Redo_why |= REASON_EQU_NOT_RESOLVED;
        }
        else
        {
            if (lab->value != sym->value)
            {
                asmerr( ERROR_EQU_VALUE_MISMATCH, false, NULL );
                printf("old value: $%04x  new value: $%04x\n",
                    lab->value, sym->value);
                ++Redo;
                Redo_why |= REASON_EQU_VALUE_MISMATCH;
            }
        }
    }

    lab->value = sym->value;
    lab->flags = sym->flags & (SYM_UNKNOWN|SYM_STRING);
    lab->string = sym->string;
    sym->flags &= ~(SYM_STRING|SYM_MACRO);

#if 1 || OlafListEqu
    /* List the value */
    {
        ulong v = lab->value;

        Glen = 0;
        if (v > 0x0000FFFF)
        {
            Gen[Glen++] = v >> 24;
            Gen[Glen++] = v >> 16;
        }
        Gen[Glen++] = v >>  8;
        Gen[Glen++] = v;
    }
#endif

    freesymbollist(sym);
}

void v_eqm(char *str, MNE *dummy)
{
    SYMBOL *lab;
    int len = strlen(Av[0]);

    if ((lab = findsymbol(Av[0], len)) != NULL)
    {
        if (lab->flags & SYM_STRING)
            free(lab->string);
    }
    else
    {
        lab = createsymbol(Av[0], len);
    }
    lab->value = 0;
    lab->flags = SYM_STRING | SYM_SET | SYM_MACRO;
    lab->string = strcpy(ckmalloc(strlen(str)+1), str);
}

void v_echo(char *str, MNE *dummy)
{
    SYMBOL *sym = eval(str, 0);
    SYMBOL *s;
    char buf[256];

    for (s = sym; s; s = s->next)
    {
        if (!(s->flags & SYM_UNKNOWN))
        {
            if (s->flags & (SYM_MACRO|SYM_STRING))
                sprintf(buf,"%s", s->string);
            else
                sprintf(buf,"$%x", s->value);
            if (FI_listfile)
                fprintf(FI_listfile, " %s", buf);
            printf(" %s", buf);
        }
    }
    puts("");
    if (FI_listfile)
        putc('\n', FI_listfile);
}

void v_set(char *str, MNE *dummy)
{
    SYMBOL *sym = eval(str, 0);
    SYMBOL *lab;

    lab = findsymbol(Av[0], strlen(Av[0]));
    if (!lab)
        lab = createsymbol(Av[0], strlen(Av[0]));
    lab->value = sym->value;
    lab->flags = sym->flags & (SYM_UNKNOWN|SYM_STRING);
    lab->string = sym->string;
    sym->flags &= ~(SYM_STRING|SYM_MACRO);
    freesymbollist(sym);
}

void v_execmac(char *str, MACRO *mac)
{
    INCFILE *inc;
    STRLIST *base;
    STRLIST **psl, *sl;
    char *s1;

    programlabel();

    if (Mlevel == MAXMACLEVEL)
    {
        puts("infinite macro recursion");
        return;
    }
    ++Mlevel;
    base = (STRLIST *)ckmalloc(sizeof(STRLIST)-STRLISTSIZE+strlen(str)+1);
    base->next = NULL;
    strcpy(base->buf, str);
    psl = &base->next;
    while (*str && *str != '\n')
    {
        s1 = str;
        while (*str && *str != '\n' && *str != ',')
            ++str;
        sl = (STRLIST *)ckmalloc(sizeof(STRLIST)-STRLISTSIZE+1+(str-s1));
        sl->next = NULL;
        *psl = sl;
        psl = &sl->next;
        memcpy(sl->buf, s1, (str-s1));
        sl->buf[str-s1] = 0;
        if (*str == ',')
            ++str;
        while (*str == ' ')
            ++str;
    }

    inc = (INCFILE *)zmalloc(sizeof(INCFILE));
    inc->next = Incfile;
    inc->name = mac->name;
    inc->fi   = Incfile->fi;    /* garbage */
    inc->lineno = 0;
    inc->flags = INF_MACRO;
    inc->saveidx = Localindex;
#if OlafDol
    inc->savedolidx = Localdollarindex;
#endif
    inc->strlist = mac->strlist;
    inc->args     = base;
    Incfile = inc;

    ++Lastlocalindex;
    Localindex = Lastlocalindex;
#if OlafDol
    ++Lastlocaldollarindex;
    Localdollarindex = Lastlocaldollarindex;
#endif
}

//void v_end(char *str, MNE *dummy)
//{
//#if OlafEnd
//    /* Only ENDs current file and any macro calls within it */
//
//    while (Incfile->flags & INF_MACRO)
//        v_endm(NULL, NULL);
//
//    fseek(Incfile->fi, 0, SEEK_END);
//#else
//    puts("END not implemented yet");
//#endif
//}

void v_endm(char *str, MNE *dummy)
{
    INCFILE *inc = Incfile;
    STRLIST *args, *an;

    /* programlabel(); contrary to documentation */
    if (inc->flags & INF_MACRO)
    {
        --Mlevel;
        for (args = inc->args; args; args = an)
        {
            an = args->next;
            free(args);
        }
        Localindex = inc->saveidx;
#if OlafDol
        Localdollarindex = inc->savedolidx;
#endif
        Incfile = inc->next;
        free(inc);
        return;
    }
    puts("not within a macro");
}

void v_mexit(char *str, MNE *dummy)
{
    v_endm(NULL, NULL);
}

void v_ifconst(char *str, MNE *dummy)
{
    SYMBOL *sym;

    programlabel();
    sym = eval(str, 0);
    pushif(sym->flags == 0);
    freesymbollist(sym);
}

void v_ifnconst(char *str, MNE *dummy)
{
    SYMBOL *sym;

    programlabel();
    sym = eval(str, 0);
    pushif(sym->flags != 0);
    freesymbollist(sym);
}

void v_if(char *str, MNE *dummy)
{
    SYMBOL *sym;

    if (!Ifstack->xtrue || !Ifstack->acctrue)
    {
        pushif(0);
        return;
    }
    programlabel();
    sym = eval(str, 0);
    if (sym->flags)
    {
        ++Redo;
        Redo_why |= REASON_IF_NOT_RESOLVED;
        pushif(0);
        Ifstack->acctrue = 0;
#if OlafPhase
        Redo_if |= 1;
#endif
    }
    else
    {
        pushif(!!sym->value);
    }
    freesymbollist(sym);
}

void v_else(char *str, MNE *dummy)
{
    if (Ifstack->acctrue && !(Ifstack->flags & IFF_BASE))
    {
        programlabel();
        Ifstack->xtrue = !Ifstack->xtrue;
    }
}

void v_endif(char *str, MNE *dummy)
{
    IFSTACK *ifs = Ifstack;

    if (!(ifs->flags & IFF_BASE))
    {
        if (ifs->acctrue)
            programlabel();
        if (ifs->file != Incfile)
        {
            puts("too many endif's");
        }
        else
        {
            Ifstack = ifs->next;
            free(ifs);
        }
    }
}

void v_repeat(char *str, MNE *dummy)
{
    REPLOOP *rp;
    SYMBOL *sym;

    if (!Ifstack->xtrue || !Ifstack->acctrue)
    {
        pushif(0);
        return;
    }
    programlabel();
    sym = eval(str, 0);
    if (sym->value == 0)
    {
        pushif(0);
        freesymbollist(sym);
        return;
    }

#ifdef DAD

    /* Don't allow negative values for REPEAT loops */

    if ( sym->value < 0 )
    {
        pushif( 0 );
        freesymbollist( sym );

        asmerr( ERROR_REPEAT_NEGATIVE, false, NULL );
        return;
    }

#endif

    rp = (REPLOOP *)zmalloc(sizeof(REPLOOP));
    rp->next = Reploop;
    rp->file = Incfile;
    if (Incfile->flags & INF_MACRO)
        rp->seek = (long)Incfile->strlist;
    else
        rp->seek = ftell(Incfile->fi);
    rp->lineno = Incfile->lineno;
    rp->count = sym->value;
    if ((rp->flags = sym->flags) != 0)
    {
        ++Redo;
        Redo_why |= REASON_REPEAT_NOT_RESOLVED;
    }
    Reploop = rp;
    freesymbollist(sym);
    pushif(1);
}

void v_repend(char *str, MNE *dummy)
{
    if (!Ifstack->xtrue || !Ifstack->acctrue)
    {
        v_endif(NULL,NULL);
        return;
    }
    if (Reploop && Reploop->file == Incfile)
    {
        if (Reploop->flags == 0 && --Reploop->count)
        {
            if (Incfile->flags & INF_MACRO)
                Incfile->strlist = (STRLIST *)Reploop->seek;
            else
                fseek(Incfile->fi,Reploop->seek,0);
            Incfile->lineno = Reploop->lineno;
        }
        else
        {
            rmnode((void **)&Reploop, sizeof(REPLOOP));
            v_endif(NULL,NULL);
        }
        return;
    }
    puts("no repeat");
}

#if OlafIncdir

STRLIST *incdirlist;

void v_incdir(char *str, MNE *dummy)
{
    STRLIST **tail;
    char *buf;
    int found = 0;

    buf = getfilename(str);

    for (tail = &incdirlist; *tail; tail = &(*tail)->next)
    {
        if (strcmp((*tail)->buf, buf) == 0)
            found = 1;
    }

    if (!found)
    {
        STRLIST *newdir;

        newdir = (STRLIST *)permalloc(STRLISTSIZE + 1 + strlen(buf));
        strcpy(newdir->buf, buf);
        *tail = newdir;
    }

    if (buf != str)
        free(buf);
}

void addpart(char *dest, const char *dir, const char *file)
{
#if 0   /* not needed here */
    if (strchr(file, ':'))
    {
        strcpy(dest, file);
    }
    else
#endif
    {
        int pos;

        strcpy(dest, dir);
        pos = strlen(dest);
        if (pos > 0 && dest[pos-1] != ':' && dest[pos-1] != '/')
        {
            dest[pos] = '/';
            pos++;
        }
        strcpy(dest + pos, file);
    }
}

FILE * pfopen(const char *name, const char *mode)
{
    FILE *f;
    STRLIST *incdir;
    char *buf;

    f = fopen(name, mode);
    if (f)
        return f;

    /* Don't use the incdirlist for absolute pathnames */
    if (strchr(name, ':'))
        return NULL;

    buf = zmalloc(512);

    for (incdir = incdirlist; incdir; incdir = incdir->next)
    {
        addpart(buf, incdir->buf, name);

        f = fopen(buf, mode);
        if (f)
            break;
    }

    free(buf);
    return f;
}

#endif

static long Seglen;
static long Seekback;
int maxorgsofar=0;
void generate(void)
{
    long seekpos;
    static ulong org;
    int i;
    int read_len;

    if (!Redo)
    {
        if (!(Csegment->flags & SF_BSS))
        {
            for (i = Glen - 1; i >= 0; --i)
                CheckSum += Gen[i];

            if (Fisclear)
            {
                Fisclear = 0;
                if (Csegment->flags & SF_UNKNOWN)
                {
                    ++Redo;
                    Redo_why |= REASON_OBSCURE;
                    return;
                }

                org = Csegment->org;

                if (F_format < 3)
                {
                    fputc((org & 0xFF), FI_temp);
                    fputc(((org >> 8) & 0xFF), FI_temp);

                    if (F_format == 2)
                    {
                        Seekback = ftell(FI_temp);
                        Seglen = 0;
                        fputc(0, FI_temp);
                        fputc(0, FI_temp);
                    }
                }
            }

            switch(F_format)
            {
            default:
            case 3:
            case 1:

                if (Csegment->org < org)
                {
                    // -=[iAN CooG/HVSC]=-
                    {
                        unsigned short int curLA;
                        unsigned char ccurLA[2];

                        seekpos = ftell(FI_temp);
                        fseek(FI_temp, 0, SEEK_SET);
                        read_len = fread(ccurLA,1,2,FI_temp);
                        if (read_len < 0) break;
                        curLA=ccurLA[0]|(ccurLA[1]<<8);

                        if(curLA<=Csegment->org)  // $801, org $900 = seek $900-$801+2bytes
                        {
                            fseek(FI_temp, Csegment->org - curLA, SEEK_CUR);
                            org=Csegment->org;
                        }
                        else
                        {
                            printf("TO BE IMPLEMENTED!\nsegment: %s %s  vs current org: %04x\n",
                                Csegment->name, sftos(Csegment->org, Csegment->flags), org);
                            asmerr( ERROR_ORIGIN_REVERSE_INDEXED, true, NULL );
                            //exit(1);

                        }
                    }
                    fwrite(Gen, Glen, 1, FI_temp);
                    break;
                }

                while (Csegment->org != org)
                {
                    if(maxorgsofar<=org)
                    {
                        fputc(OrgFill, FI_temp);
                        maxorgsofar++;
                    }
                    else
                    {
                        fseek(FI_temp, 1, SEEK_CUR);
                    }
                    ++org;
                }
                fwrite(Gen, Glen, 1, FI_temp);
                /* iAN */
                if(maxorgsofar<Csegment->org+Glen)
                   maxorgsofar=Csegment->org+Glen;

                break;

            case 2:

                if (org != Csegment->org)
                {
                    org = Csegment->org;
                    seekpos = ftell(FI_temp);
                    fseek(FI_temp, Seekback, 0);
                    putc((Seglen & 0xFF), FI_temp);
                    putc(((Seglen >> 8) & 0xFF), FI_temp);
                    fseek(FI_temp, seekpos, 0);
                    putc((org & 0xFF), FI_temp);
                    putc(((org >> 8) & 0xFF), FI_temp);
                    Seekback = ftell(FI_temp);
                    Seglen = 0;
                    putc(0, FI_temp);
                    putc(0, FI_temp);
                }

                fwrite(Gen, Glen, 1, FI_temp);
                Seglen += Glen;
            }
            org += Glen;
        }
    }
    else
    {
        if(org){
            while (Csegment->org > org)
            {
                if(maxorgsofar<=Csegment->org)
                {
                    fputc(OrgFill, FI_temp);
                    maxorgsofar++;
                }
                else
                {
                    fseek(FI_temp, 1, SEEK_CUR);
                }
                ++org;
            }
        }
    }

    Csegment->org += Glen;

    if (Csegment->flags & SF_RORG)
    {
        lastrorg= Csegment->rorg;
        Csegment->rorg += Glen;
    }
    else
        lastrorg=0;
}

void closegenerate(void)
{
    if (!Redo)
    {
        if (F_format == 2)
        {
            fseek(FI_temp, Seekback, 0);
            putc((Seglen & 0xFF), FI_temp);
            putc(((Seglen >> 8) & 0xFF), FI_temp);
            fseek(FI_temp, 0L, 2);
        }
    }
}

void genfill(long fill, long entries, int size)
{
    long bytes = entries;  /*   multiplied later    */
    int i;
    ubyte c3,c2,c1,c0;

    if (!bytes)
        return;

    c3 = fill >> 24;
    c2 = fill >> 16;
    c1 = fill >> 8;
    c0 = fill;
    switch(size)
    {
    case 1:
        memset(Gen, c0, sizeof(Gen));
        break;

    case 2:
        bytes <<= 1;
        for (i = 0; i < sizeof(Gen); i += 2)
        {
            if (MsbOrder)
            {
                Gen[i+0] = c1;
                Gen[i+1] = c0;
            }
            else
            {
                Gen[i+0] = c0;
                Gen[i+1] = c1;
            }
        }
        break;

    case 4:
        bytes <<= 2;
        for (i = 0; i < sizeof(Gen); i += 4)
        {
            if (MsbOrder)
            {
                Gen[i+0] = c3;
                Gen[i+1] = c2;
                Gen[i+2] = c1;
                Gen[i+3] = c0;
            }
            else
            {
                Gen[i+0] = c0;
                Gen[i+1] = c1;
                Gen[i+2] = c2;
                Gen[i+3] = c3;
            }
        }
        break;
    }

    for (Glen = sizeof(Gen); bytes > sizeof(Gen); bytes -= sizeof(Gen))
        generate();
    Glen = bytes;
    generate();
}

void pushif(bool xbool)
{
    IFSTACK *ifs = (IFSTACK *)zmalloc(sizeof(IFSTACK));
    ifs->next = Ifstack;
    ifs->file = Incfile;
    ifs->flags = 0;
    ifs->xtrue  = xbool;
    ifs->acctrue = Ifstack->acctrue && Ifstack->xtrue;
    Ifstack = ifs;
}
