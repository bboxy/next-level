/*
*  MAIN.C
*
*  (c)Copyright 1988, Matthew Dillon, All Rights Reserved.
*     Freely Distributable (for non-profit) ONLY.  No redistribution
*     of any modified text files or redistribution of a subset of the
*     source is allowed.  Redistribution of modified binaries IS allowed
*     under the above terms.
*
*  DASM   sourcefile
*
*  NOTE: must handle mnemonic extensions and expression decode/compare.
*/

#include "asm.h"

#define ISEGNAME    "INITIAL CODE SEGMENT"

#ifndef _WIN32
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif

char *cleanup(char *buf);
MNE *parse(char *buf);
void panic(char *str);
MNE *findmne(char *str);
void clearsegs(void);
void clearrefs(void);
int notresolv=0;

static uword hash1(char *str);
static void outlistfile(char *);

extern MNE    Mne6502[];
extern int maxorgsofar;

/*
    AD - 15/July/2003
uword _fmode = 0;

*/
ubyte     Disable_me;
ubyte     StopAtEnd = 0;
char     *Extstr;
ubyte     Listing = 1;
int     pass=0;
#if OlafListAll
ubyte     F_ListAllPasses = 0;
#endif
#if OlafPasses
ubyte    F_Passes=0;
ubyte    F_passes = 32 ;
#else
#define  F_passes 10
#endif


const char name[] = "DASM Macro Assembler V2.20.07-iAN-rev-O (C)1988-2018";
const char copr[] = "Mods by iAN CooG/HVSC & TLR/VICE Team    "__DATE__;

int nTableSort = 0;                 /* Sorting preference for symbol table output */
int OlafFreeFormat = 1;

char *Errors[] =
{

        "OK",
        "Check command-line format.",
        "Unable to open file.",
        "Source is not resolvable.",
        "Too many passes",
        "Syntax Error '%s'.",
        "Expression table overflow.",
        "Unbalanced Braces [].",
        "Division by zero.",
        "Unknown Mnemonic '%s'.",
        "Illegal Addressing mode '%s'.",
        "Illegal forced Addressing mode on '%s'.",
        "Not enough args passed to Macro.",
        "Premature EOF.",
        "Illegal character '%s'.",
        "Branch out of range (%s bytes).",
        "ERR pseudo-op encountered.",
        "Origin Reverse-indexed.",
        "EQU: Value mismatch.",
        "Value in '%s' must be <$100.",
        "Illegal bit specification.",
        "Not enough args.",
        "Label mismatch...\n --> %s",
        "Value Undefined.",
        "",/*"Processor '%s' not supported.",*/
        "REPEAT parameter < 0 (ignored).",        /* 21 ERROR_REPEAT_NEGATIVE */
        NULL
};

int CountUnresolvedSymbols(void)
{
    SYMBOL *sym;
    int nUnresolved = 0;
    int i;

    /* Pre-count unresolved symbols */
    for (i = 0; i < SHASHSIZE; ++i)
        for (sym = SHash[i]; sym; sym = sym->next)
            if ( sym->flags & SYM_UNKNOWN )
                nUnresolved++;

    return nUnresolved;
}

int ShowUnresolvedSymbols(void)
{
    SYMBOL *sym;
    int i;

    int nUnresolved = CountUnresolvedSymbols();
    if ( nUnresolved )
    {
        printf( "--- Unresolved Symbol List\n" );

        /* Display unresolved symbols */
        for (i = 0; i < SHASHSIZE; ++i)
            for (sym = SHash[i]; sym; sym = sym->next)
                if ( sym->flags & SYM_UNKNOWN )
                    printf( "%-24s %s\n", sym->name, sftos( sym->value, sym->flags ) );

        printf( "--- %d Unresolved Symbol%c\n\n", nUnresolved, ( nUnresolved == 1 ) ? ' ' : 's' );
    }

    return nUnresolved;
}

int CompareAlpha( const void *arg1, const void *arg2 )
{
    /* Simple alphabetic ordering comparison function for quicksort */
    const SYMBOL *sym1 = *(SYMBOL * const *) arg1;
    const SYMBOL *sym2 = *(SYMBOL * const *) arg2;
    return strcasecmp(sym1->name, sym2->name);
}

int CompareAddress( const void *arg1, const void *arg2 )
{
    /* Simple numeric ordering comparison function for quicksort */

    SYMBOL **sym1, **sym2;

    sym1 = (SYMBOL **) arg1;
    sym2 = (SYMBOL **) arg2;

    return (*sym1)->value - (*sym2)->value;
}

void ShowSymbols( FILE *file )
{
    /* Display sorted (!) symbol table - if it runs out of memory, table will be displayed unsorted */

    SYMBOL **symArray;
    SYMBOL *sym;
    int i;
    int nSymbols = 0;
    char buf[512];
    char buf2[256],*pbuf;
    if(nTableSort<2)
        fprintf( file, "--- Symbol List");

    /* Sort the symbol list either via name, or by value */

    /* First count the number of symbols */
    for (i = 0; i < SHASHSIZE; ++i)
        for (sym = SHash[i]; sym; sym = sym->next)
            nSymbols++;

    /* Malloc an array of pointers to data */

    symArray = malloc( sizeof( SYMBOL * ) * nSymbols );
    if ( !symArray )
    {
        if(nTableSort<2)
        {
            fprintf( file, " (unsorted - not enough memory to sort!)\n" );

            /* Display complete symbol table */
            for (i = 0; i < SHASHSIZE; ++i)
                for (sym = SHash[i]; sym; sym = sym->next)
                    fprintf( file, "%-24s %s\n", sym->name, sftos( sym->value, sym->flags ) );
        }
        else
        {

            for (i = 0; i < SHASHSIZE; ++i)
                for (sym = SHash[i]; sym; sym = sym->next)
                {
                    sprintf(buf,"al C:$%-12s",
                            sftos( sym->value, sym->flags )
                    );
                    buf[10]=0;
                    pbuf=strchr(sym->name,'.');
                    if(pbuf==NULL)
                    {
	                    sprintf(buf+10," .%-24s", sym->name);
                    }
                    else
                    {
                    	strcpy(buf2,sym->name);
                    	pbuf=strchr(buf2,'.');
                        *pbuf='_';
                    	sprintf(buf+10," ._%-24s", buf2);
                    }

                    fprintf( file, "%s\n",buf);
                }
        }
    }
    else
    {
        /* Copy the element pointers into the symbol array */

        //bool bRepeat;
        int nPtr = 0;

        for (i = 0; i < SHASHSIZE; ++i)
            for (sym = SHash[i]; sym; sym = sym->next)
                symArray[ nPtr++ ] = sym;

        if ( nTableSort )
        {
            if(nTableSort<2)
                fprintf( file, " (sorted by address)\n" );
            qsort( symArray, nPtr, sizeof( SYMBOL * ), CompareAddress );           /* Sort via address */
        }
        else
        {
            fprintf( file, " (sorted by symbol)\n" );
            qsort( symArray, nPtr, sizeof( SYMBOL * ), CompareAlpha );              /* Sort via name */
        }

        /* now display sorted list */

        if(nTableSort<2)
        {
            for ( i = 0; i < nPtr; i++ )
            {
                fprintf( file, "%-24s %-12s", symArray[ i ]->name,
                    sftos( symArray[ i ]->value, symArray[ i ]->flags ) );
                if ( symArray[ i ]->flags & SYM_STRING )
                    fprintf( file, " \"%s\"", symArray[ i ]->string );                  /* If a string, display actual string */
                fprintf( file, "\n" );
            }
        }
        else
        {   // vice labels
            for ( i = 0; i < nPtr; i++ )
            {
                sprintf(buf,"al C:$%-12s",
                        sftos( symArray[ i ]->value, symArray[ i ]->flags )
                );
                buf[10]=0;
                pbuf=strchr(symArray[ i ]->name,'.');
                if(pbuf==NULL)
                {
                	sprintf(buf+10," .%-24s", symArray[ i ]->name );
                }
                else
                {
                    strcpy(buf2,symArray[ i ]->name);
                    pbuf=strchr(buf2,'.');
                    *pbuf='_';
                    sprintf(buf+10," ._%-24s", buf2);
                }
                fprintf( file, "%s\n",buf);
            }
        }

        free( symArray );
    }
    if(nTableSort<2)
        fputs( "--- End of Symbol List.\n", file );

}

void ShowSegments(void)
{
    SEGMENT *seg;
    char *bss;

    printf("\n----------------------------------------------------------------------\n");
    printf(  "SEGMENT NAME                 INIT PC | FINAL PC | INIT RPC | FINAL RPC\n" );

    for (seg = Seglist; seg; seg = seg->next)
    {
        bss = (seg->flags & SF_BSS) ? "[u]" : "   ";
        printf( "%-24s %-3s  $%04X  |  $%04X   |  $%04X   |  $%04X\n", seg->name, bss,
            (unsigned int)seg->initorg,
            (unsigned int)seg->org,
            (unsigned int)seg->initrorg,
            (unsigned int)seg->rorg );

    }
    puts("----------------------------------------------------------------------");

    printf( "%d references to unknown symbols.\n", (unsigned int)Redo_eval );
    printf( "%d events requiring another assembler pass.\n", (unsigned int)Redo );

    if ( Redo_why )
    {
        if ( Redo_why & REASON_MNEMONIC_NOT_RESOLVED )
            printf( " - Expression in mnemonic not resolved.\n" );

        if ( Redo_why & REASON_OBSCURE )
            printf( " - Obscure reason - to be documented :)\n" );

        if ( Redo_why & REASON_DC_NOT_RESOLVED )
            printf( " - Expression in a DC not resolved.\n" );

        if ( Redo_why & REASON_DV_NOT_RESOLVED_PROBABLY )
            printf( " - Expression in a DV not resolved (probably in DV's EQM symbol).\n" );

        if ( Redo_why & REASON_DV_NOT_RESOLVED_COULD )
            printf( " - Expression in a DV not resolved (could be in DV's EQM symbol).\n" );

        if ( Redo_why & REASON_DS_NOT_RESOLVED )
            printf( " - Expression in a DS not resolved.\n" );

        if ( Redo_why & REASON_ALIGN_NOT_RESOLVED )
            printf( " - Expression in an ALIGN not resolved.\n" );

        if ( Redo_why & REASON_ALIGN_RELOCATABLE_ORIGIN_NOT_KNOWN )
            printf( " - ALIGN: Relocatable origin not known (if in RORG at the time).\n" );

        if ( Redo_why & REASON_ALIGN_NORMAL_ORIGIN_NOT_KNOWN )
            printf( " - ALIGN: Normal origin not known  (if in ORG at the time).\n" );

        if ( Redo_why & REASON_EQU_NOT_RESOLVED )
            printf( " - EQU: Expression not resolved.\n" );

        if ( Redo_why & REASON_EQU_VALUE_MISMATCH )
            printf( " - EQU: Value mismatch from previous pass (phase error).\n" );

        if ( Redo_why & REASON_IF_NOT_RESOLVED )
            printf( " - IF: Expression not resolved.\n" );

        if ( Redo_why & REASON_REPEAT_NOT_RESOLVED )
            printf( " - REPEAT: Expression not resolved.\n" );

        if ( Redo_why & REASON_FORWARD_REFERENCE )
            printf( " - Label defined after it has been referenced (forward reference).\n" );

        if ( Redo_why & REASON_PHASE_ERROR )
            printf( " - Label value is different from that of the previous pass (phase error).\n" );
    }

    printf( "\n" );

}

void DumpSymbolTable(void)
{
    if (F_symfile)
    {
        FILE *fi = fopen(F_symfile, "w");
        if (fi)
        {
            ShowSymbols( fi );
            fclose(fi);
        }
        else
        {
            printf("Warning: Unable to open Symbol Dump file '%s'\n", F_symfile);
        }
    }

}

void Skipendofbuf(char *buf)
{
    int c;
    c=strlen(buf);
    if(c == (MAXLINE-2))
    {
        while(( c = fgetc(Incfile->fi) ) != EOF)
        {
            if(c == 0x0a)
                break;
        }
    }
    return;
}


int MainShadow(int ac, char **av)
{
    int nError = ERROR_NONE;

    char buf[MAXLINE+16]={0};
    int i;
    MNE *mne;
    ulong oldredo = -1;
    ulong oldwhy = 0;
    ulong oldeval = 0;

    MsbOrder = 0;
    Processor = 6502;

    addhashtable(Ops);
    addhashtable(Mne6502);
    pass = 1;

    puts(name);
    puts(copr);
    puts("redistributable for non-profit only");
    if (ac < 2)
    {

fail:
        puts("");
        puts("DASM sourcefile [options]");
        puts(" -f#      output format");
        puts(" -oname   output file");
        puts(" -lname   list file");
#if OlafListAll
        puts(" -Lname   list file, containing all passes");
#endif
        puts(" -sname   symbol dump");
        puts(" -v#      verboseness");
        puts(" -t#      Symbol Table sorting preference \n"
             "           -t0 = alphabetic (default)\n"
             "           -t1 = by address\n"
             "           -t2 = by address, Vice label mode"
                        );
        puts(" -H       use HashFormat for parsing, default is FreeFormat");
        puts(" -Dname=exp   define label");
        puts(" -Mname=exp   define label as in EQM");


#if OlafIncdir
        puts(" -Idir    search directory for include and incbin");
#endif
#if OlafPasses
        puts(" -p#      max number of passes");
        puts(" -P#      max number of passes, with less checks");
#endif
        return ERROR_COMMAND_LINE;
    }

    for (i = 2; i < ac; ++i)
    {
        if ( ( av[i][0] == '-' ) || ( av[i][0] == '/' ) )
        {
            char *str = av[i]+2;
            switch(av[i][1])
            {

            case 'T':
            case 't':
                nTableSort = atoi( str );
                break;

            case 'd':
                Xdebug = atoi(str) != 0;
                printf( "Debug trace %s\n", Xdebug ? "ON" : "OFF" );
                break;

            case 'H':
                OlafFreeFormat = 0;
                break;

            case 'M':
            case 'D':
                while (*str && *str != '=')
                    ++str;
                if (*str == '=')
                {
                    *str = 0;
                    ++str;
                }
                else
                {
                    str = "0";
                }
                Av[0] = av[i]+2;

                if (av[i][1] == 'M')
                    v_eqm(str, NULL);
                else
                    v_set(str, NULL);
                break;

            case 'f':   /*  F_format    */
                F_format = atoi(str);
                if (F_format < 1 || F_format > 3)
                    panic("Illegal format specification");
                break;

            case 'o':   /*  F_outfile   */
                F_outfile = str;
nofile:
                if (*str == 0)
                {
                    sprintf(buf,"-%c Switch requires file name.",av[i][1]);
                    panic(buf);
                }
                break;
#if OlafListAll
            case 'L':
                F_ListAllPasses = 1;
                /* fall through to 'l' */
#endif
            case 'l':   /*  F_listfile  */
                F_listfile = str;
                goto nofile;
#if OlafPasses
            case 'P':   /*  F_Passes   */
                F_Passes = 1;
                /* fall through to 'p' */
            case 'p':   /*  F_passes   */
                F_passes = atoi(str);
                break;
#endif
            case 's':   /*  F_symfile   */
                F_symfile = str;
                goto nofile;
            case 'v':   /*  F_verbose   */
                F_verbose = atoi(str);
                break;
            //case 't':   /*  F_temppath  */
                //F_temppath = str;
                //break;
#if OlafIncdir
            case 'I':
                v_incdir(str, NULL);
                break;
#endif
            default:
                goto fail;
            }
            continue;
        }
        goto fail;
    }

    /*    INITIAL SEGMENT */

    {
        SEGMENT *seg = (SEGMENT *)permalloc(sizeof(SEGMENT));
        seg->name = strcpy(permalloc(sizeof(ISEGNAME)), ISEGNAME);
        seg->flags= seg->rflags = seg->initflags = seg->initrflags = SF_UNKNOWN;
        Csegment = Seglist = seg;
    }
    /*    TOP LEVEL IF    */
    {
        IFSTACK *ifs = (IFSTACK *)zmalloc(sizeof(IFSTACK));
        ifs->file = NULL;
        ifs->flags = IFF_BASE;
        ifs->acctrue = 1;
        ifs->xtrue  = 1;
        Ifstack = ifs;
    }


nextpass:


    if ( F_verbose )
    {
        puts("");
        printf("START OF PASS: %d\n", pass);
    }

    Localindex = Lastlocalindex = 0;
#if OlafDol
    Localdollarindex = Lastlocaldollarindex = 0;
#endif
    /*_fmode = 0x8000;*/
    if(pass==1)
        FI_temp = fopen(F_outfile, "w+b");
    else
        FI_temp = fopen(F_outfile, "r+b");
    /*_fmode = 0;*/
    Fisclear = 1;
    CheckSum = 0;
    if (FI_temp == NULL)
    {
        printf("Warning: Unable to [re]open '%s'\n", F_outfile);
        return ERROR_FILE_ERROR;
    }
    if (F_listfile)
    {
#if OlafListAll
        FI_listfile = fopen(F_listfile,
            F_ListAllPasses && (pass > 1)? "a" : "w");
#else
        FI_listfile = fopen(F_listfile, "w");
#endif
        if (FI_listfile == NULL)
        {
            printf("Warning: Unable to [re]open '%s'\n", F_listfile);
            return ERROR_FILE_ERROR;
        }
    }
    pushinclude(av[1]);

    while (Incfile)
    {
        for (;;)
        {
            char *comment;
            //int c;
            if (Incfile->flags & INF_MACRO)
            {
                if (Incfile->strlist == NULL)
                {
                    Av[0] = "";
                    v_mexit(NULL, NULL);
                    continue;
                }
                memset(buf,0,sizeof(buf));
                strcpy(buf, Incfile->strlist->buf);
                Incfile->strlist = Incfile->strlist->next;
            } else
            {
                memset(buf,0,sizeof(buf));
                if (fgets(buf, MAXLINE-1, Incfile->fi) == NULL)
                    break;
            }
            buf[MAXLINE-1]=0;
            /* let's ignore long lines exceeding chars */
            Skipendofbuf(buf);

            if (Xdebug)
                printf("%08lx %s\n", (unsigned long)Incfile, buf);

            comment = cleanup(buf);
            ++Incfile->lineno;
            mne = parse(buf);

            if (Av[1][0])
            {
                if (mne)
                {
                    if ((mne->flags & MF_IF) || (Ifstack->xtrue && Ifstack->acctrue))
                        (*mne->vect)(Av[2], mne);
                }
                else
                {
                    if (Ifstack->xtrue && Ifstack->acctrue)
                        asmerr( ERROR_UNKNOWN_MNEMONIC, false, Av[1] );
                }

            }
            else
            {
                if (Ifstack->xtrue && Ifstack->acctrue)
                    programlabel();
            }

            if (F_listfile && ListMode)
                outlistfile(comment);
        }

        while (Reploop && Reploop->file == Incfile)
            rmnode((void **)&Reploop, sizeof(REPLOOP));

        while (Ifstack->file == Incfile)
            rmnode((void **)&Ifstack, sizeof(IFSTACK));

        fclose(Incfile->fi);
        free(Incfile->name);
        --Inclevel;
        rmnode((void **)&Incfile, sizeof(INCFILE));

        if (Incfile)
        {
            /*
            if (F_verbose > 1)
            printf("back to: %s\n", Incfile->name);
            */
            if (F_listfile)
                fprintf(FI_listfile, "------- FILE %s\n", Incfile->name);
        }
    }


    if ( F_verbose >= 1 )
        ShowSegments();

    if ( F_verbose >= 3 )
    {
        if ( !Redo || ( F_verbose == 4 ) )
            ShowSymbols( stdout );

        ShowUnresolvedSymbols();
    }

    closegenerate();
    fclose(FI_temp);
    if (FI_listfile)
        fclose(FI_listfile);

    if (Redo)
    {
#if OlafPasses
        if (!F_Passes)
#endif
        if (Redo == oldredo && Redo_why == oldwhy && Redo_eval == oldeval)
        {
            ShowUnresolvedSymbols();
            if (++notresolv == 2 )
               return ERROR_NOT_RESOLVABLE;
        }

        oldredo = Redo;
        oldwhy = Redo_why;
        oldeval = Redo_eval;
        Redo = 0;
        Redo_why = 0;
        Redo_eval = 0;
#if OlafPhase
        Redo_if <<= 1;
#endif
        ++pass;

        if (StopAtEnd)
        {
            printf("Unrecoverable error(s) in pass, aborting assembly!\n");
        }
        else if (pass > F_passes)
        {
            printf("%s Pass=%d maxpasses=%d\n",Errors[ERROR_TOO_MANY_PASSES],pass,F_passes);
            return ERROR_TOO_MANY_PASSES;
        }
        else
        {
            clearrefs();
            clearsegs();
            goto nextpass;
        }
    }

    printf( "Complete.\n" );

    return nError;
}


int tabit(char *buf1, char *buf2)
{
    char *bp, *ptr;
    int j, k;

    bp = buf2;
    ptr= buf1;
    for (j = 0; *ptr && *ptr != '\n'; ++ptr, ++bp, j = (j+1)&7)
    {
        *bp = *ptr;
        if (*ptr == '\t')
        {
            /* optimize out spaces before the tab */
            while (j > 0 && bp[-1] == ' ')
            {
                bp--;
                j--;
            }
            j = 0;
            *bp = '\t';         /* recopy the tab */
        }
        if (j == 7 && *bp == ' ' && bp[-1] == ' ')
        {
            k = j;
            while (k-- >= 0 && *bp == ' ')
                --bp;
            *++bp = '\t';
        }
    }
    while (bp != buf2 && (bp[-1] == ' ' || bp[-1] == '\t'))
        --bp;
    *bp++ = '\n';
    *bp = '\0';
    return((int)(bp - buf2));
}

static void outlistfile(char *comment)
{
    char xtrue;
    char c;
    static char buf1[MAXLINE+64];
    static char buf2[MAXLINE+64];
    char *ptr;
    char *dot;
    int i, j;

#if OlafList
    if (Incfile->flags & INF_NOLIST)
        return;
#endif

    xtrue = (Ifstack->xtrue && Ifstack->acctrue) ? ' ' : '-';
    c = (Pflags & SF_BSS) ? 'U' : ' ';
    ptr = Extstr;
    dot = "";
    if (ptr)
        dot = ".";
    else
        ptr = "";

    sprintf(buf1, "%7d %c%s", Incfile->lineno, c, sftos(Plab, Pflags & 7));
    j = strlen(buf1);
    for (i = 0; i < Glen && i < 4; ++i, j += 3)
        sprintf(buf1+j, "%02x ", Gen[i]);
    if (i < Glen && i == 4)
        xtrue = '*';
    for (; i < 4; ++i)
    {
        buf1[j] = buf1[j+1] = buf1[j+2] = ' ';
        j += 3;
    }
    sprintf(buf1+j-1, "%c%-10s %s%s%s\t%s\n",
        xtrue, Av[0], Av[1], dot, ptr, Av[2]);
    if (comment[0])
    { /*  tab and comment */
        j = strlen(buf1) - 1;
        sprintf(buf1+j, "\t;%s", comment);
    }
    fwrite(buf2, tabit(buf1,buf2), 1, FI_listfile);
    Glen = 0;
    Extstr = NULL;
}

char * sftos(int val, int flags)
{

    static char buf[MAXLINE+16];
    static char c;
    char *ptr = (c) ? buf : buf + 32;

    memset( buf, 0, MAXLINE );

    c = 1 - c;

    sprintf(ptr, "%04x ", val);

    if (flags & SYM_UNKNOWN)
        strcat( ptr, "???? ");
    else
    {
        if(Csegment->flags & SF_RORG )
        {
            char tm[8];
            sprintf(tm, "%04x ", lastrorg);
            strcat( ptr, tm );
        }
        else
            strcat( ptr, "     " );
    }
    if (flags & SYM_STRING)
        strcat( ptr, "str ");
    else
        strcat( ptr, "    " );

    if (flags & SYM_MACRO)
        strcat( ptr, "eqm ");
    else
        strcat( ptr, "    " );


    if (flags & (SYM_MASREF|SYM_SET))
    {
        strcat( ptr, "(" );
    }
    else
        strcat( ptr, " " );

    if (flags & (SYM_MASREF))
        strcat( ptr, "R" );
    else
        strcat( ptr, " " );


    if (flags & (SYM_SET))
        strcat( ptr, "S" );
    else
        strcat( ptr, " " );

    if (flags & (SYM_MASREF|SYM_SET))
    {
        strcat( ptr, ")" );
    }
    else
        strcat( ptr, " " );


    return ptr;

}

void clearsegs(void)
{
    SEGMENT *seg;

    for (seg = Seglist; seg; seg = seg->next)
    {
		seg->org=seg->rorg=0; /* at 2nd pass always set as end of prg */
        seg->flags = (seg->flags & SF_BSS) | SF_UNKNOWN;
        seg->rflags= seg->initflags = seg->initrflags = SF_UNKNOWN;
    }
}

void clearrefs(void)
{
    SYMBOL *sym;
    short i;

    for (i = 0; i < SHASHSIZE; ++i)
        for (sym = SHash[i]; sym; sym = sym->next)
            sym->flags &= ~SYM_REF;
}

char * cleanup(char *buf)
{
    char *str,*p;
    STRLIST *strlist;
    int arg, add;
    char *comment = "";

    for (str = buf; *str; ++str)
    {
        switch(*str)
        {
        case ';':
            comment = (char *)str + 1;
            p=comment+strlen(comment)-1;
            while( strchr("\r\n ",*p)!=NULL )
                *p-- = 0;
            /*    FALL THROUGH    */
        case '\r':
        case '\n':
            goto br2;
        case TAB:
            *str = ' ';
            break;
        case '\'':
            ++str;
            if (*str == TAB)
                *str = ' ';
            if (*str == '\n' || *str == 0)
            {
                str[0] = ' ';
                str[1] = 0;
            }
            if (str[0] == ' ')
                str[0] = '\x80';
            break;
        case '\"':
            ++str;
            while (*str && *str != '\"')
            {
                if (*str == ' ')
                    *str = '\x80';
                ++str;
            }
            if (*str != '\"')
            {
                asmerr( ERROR_SYNTAX_ERROR, false, buf );
                --str;
            }
            break;
        case '{':
            if (Disable_me)
                break;

            if (Xdebug)
                printf("macro tail: '%s'\n", str);

            arg = atoi(str+1);
            for (add = 0; *str && *str != '}'; ++str)
                --add;
            if (*str != '}')
            {
                puts("end brace required");
                --str;
                break;
            }
            --add;
            ++str;


            if (Xdebug)
                printf("add/str: %d '%s'\n", add, str);

            for (strlist = Incfile->args; arg && strlist;)
            {
                --arg;
                strlist = strlist->next;
            }

            if (strlist)
            {
                add += strlen(strlist->buf);

                if (Xdebug)
                    printf("strlist: '%s' %ld\n", strlist->buf, strlen(strlist->buf));

                if (str + add + strlen(str) + 1 > buf + MAXLINE)
                {
                    if (Xdebug)
                        printf("str %8ld buf %8ld (add/strlen(str)): %d %d\n",
                        (unsigned long)str, (unsigned long)buf, add, (int)strlen(str));
                    panic("failure1");
                }

                memmove(str + add, str, strlen(str)+1);
                str += add;
                if (str - strlen(strlist->buf) < buf)
                    panic("failure2");
                memmove(str - strlen(strlist->buf), strlist->buf, strlen(strlist->buf));
                str -= strlen(strlist->buf);
                if (str < buf || str >= buf + MAXLINE)
                    panic("failure 3");
                --str;      /*  for loop increments string    */
            }
            else
            {
                asmerr( ERROR_NOT_ENOUGH_ARGUMENTS_PASSED_TO_MACRO, false, NULL );
                goto br2;
            }
            break;
        }
    }

br2:
    while(str != buf && *(str-1) == ' ' )
        --str;
    *str = 0;

    return comment;
}

void panic(char *str)
{
    puts(str);
    exit(1);
}

/*
 *  .dir    direct                    x
 *  .ext    extended                  x
 *  .r      relative                  x
 *  .x      index, no offset          x
 *  .x8     index, byte offset        x
 *  .x16    index, word offset        x
 *  .bit    bit set/clr
 *  .bbr    bit and branch
 *  .imp    implied (inherent)        x
 *  .b                                x
 *  .w                                x
 *  .l                                x
 *  .u                                x
 */

void findext(char *str)
{
    Mnext = -1;
    Extstr = NULL;
#if OlafDotop
    if (str[0] == '.')
    {    /* Allow .OP for OP */
        return;
    }
#endif
    while (*str && *str != '.')
        ++str;
    if (*str)
    {
        *str = 0;
        ++str;
        Extstr = str;
        switch(str[0]|0x20)
        {
        case '0':
        case 'i':
            Mnext = AM_IMP;
            switch(str[1]|0x20)
            {
            case 'x':
                Mnext = AM_0X;
                break;
            case 'y':
                Mnext = AM_0Y;
                break;
            case 'n':
                Mnext = AM_INDWORD;
                break;
            }
            return;


        case 'd':
        case 'b':
        case 'z':
            switch(str[1]|0x20)
            {
            case 'x':
                Mnext = AM_BYTEADRX;
                break;
            case 'y':
                Mnext = AM_BYTEADRY;
                break;
            case 'i':
                Mnext = AM_BITMOD;
                break;
            case 'b':
                Mnext = AM_BITBRAMOD;
                break;
            default:
                Mnext = AM_BYTEADR;
                break;
            }
            return;

        case 'e':
        case 'w':
        //case 'a':
            switch(str[1]|0x20)
            {
            case 'x':
                Mnext = AM_WORDADRX;
                break;
            case 'y':
                Mnext = AM_WORDADRY;
                break;
            default:
                Mnext = AM_WORDADR;
                break;
            }
            return;

        case 'l':
            Mnext = AM_LONG;
            return;
        case 'r':
            Mnext = AM_REL;
            return;
        case 'u':
            Mnext = AM_BSS;
            return;
        }
    }
}

/*
*  bytes arg will eventually be used to implement a linked list of free
*  nodes.
*  Assumes *base is really a pointer to a structure with .next as the first
*  member.
*/

void rmnode(void **base, int bytes)
{
    void *node;

    if ((node = *base) != NULL)
    {
        *base = *(void **)node;
        free(node);
    }
}

/*
*  Parse into three arguments: Av[0], Av[1], Av[2]
*/
MNE * parse(char *buf)
{
    int i, j;
    char *eqp,*qp;
    int sl=0;

    MNE *mne = NULL;

    i = 0;
    j = 1;
    if( OlafFreeFormat )
    {
        /* Skip all initial spaces */
        while (buf[i] == ' ')
            ++i;

        /*
        experiment: label=$xxxx -> label = $xxxx
        works for both labels, ".=" & "*=" forms
        fix: don't bother = inside quotes
        */
        qp=strchr(buf+i,'"');
        eqp=strchr(buf+i,'=');
        if(eqp>0 && ((qp==NULL) || (qp>eqp)) )
        {
            // !=, <=, >=
            if((*(eqp-1)=='!')||
               (*(eqp-1)=='<')||
               (*(eqp-1)=='>') )
            {
                if(*(eqp-2)!=' ')
                {
                    sl=strlen(eqp-1);       // .if label!=1 -> .if label !=1
                    memmove(eqp,eqp-1,sl);
                    *(eqp-1) = ' ';
                    *(eqp+sl+1) = 0;
                    eqp++; // equal sign now is shifted 1 char right
                }
            }
            else if(*(eqp-1)!=' ') // =, ==
            {
                sl=strlen(eqp);       //  label=xxx -> label =xxx
                memmove(eqp+1,eqp,sl);
                *eqp = ' ';
                *(eqp+sl+1) = 0;
                eqp++; // equal sign now is shifted 1 char right
            }
            // keep "=="
            if(*(eqp+1)=='=')
                 eqp++;
            if( *(eqp+1)!=' ')
            {                            // covers both cases:
                sl=strlen(eqp);          // .if label ==1 -> .if label == 1
                memmove(eqp+2,eqp+1,sl); // label =xxx -> label = xxx
                *(eqp+1) = ' ';
                *(eqp+sl+1)=0;

            }
        }


    }
    else
    {
            /*
            * If the first non-space is a ^, skip all further spaces too.
            * This means what follows is a label.
            * If the first non-space is a #, what follows is a directive/opcode.
        */
        while (buf[i] == ' ')
            ++i;

        if (buf[i] == '^')
        {

            ++i;
            while (buf[i] == ' ')
                ++i;
        } else if (buf[i] == '#')
        {
            buf[i] = ' ';   /* label separator */
        } else
            i = 0;
    }

    Av[0] = Avbuf + j;
    while (buf[i] && buf[i] != ' ')
    {
#if OlafColon
        if (buf[i] == ':')
        {
            i++;
            break;
        }
#endif
        if ((unsigned char)buf[i] == 0x80)
            buf[i] = ' ';
        Avbuf[j++] = buf[i++];
    }
    Avbuf[j++] = 0;
    if( OlafFreeFormat )
    {
        /* Try if the first word is an opcode */
        findext(Av[0]);
        mne = findmne(Av[0]);
    }
    if (OlafFreeFormat &&(mne != NULL))
    {
    /* Yes, it is. So there is no label, and the rest
    * of the line is the argument
        */
        Avbuf[0] = 0;    /* Make an empty string */
        Av[1] = Av[0];    /* The opcode is the previous first word */
        Av[0] = Avbuf;    /* Point the label to the empty string */
    }
    else
    {    /* Parse the second word of the line */
        while (buf[i] == ' ')
            ++i;
        Av[1] = Avbuf + j;
        while (buf[i] && buf[i] != ' ')
        {
            if ((unsigned char)buf[i] == 0x80)
                buf[i] = ' ';
            Avbuf[j++] = buf[i++];
        }
        Avbuf[j++] = 0;
        /* and analyse it as an opcode */
        findext(Av[1]);
        mne = findmne(Av[1]);
    }
    /* Parse the rest of the line */
    while (buf[i] == ' ')
        ++i;
    Av[2] = Avbuf + j;
    while (buf[i])
    {
        if (buf[i] == ' ')
        {
            while(buf[i+1] == ' ')
                ++i;
        }
        if ((unsigned char)buf[i] == 0x80)
            buf[i] = ' ';
        Avbuf[j++] = buf[i++];
    }
    Avbuf[j] = 0;

    /******** -=[iAN CooG/HVSC]=-  ******/
    if(((stricmp(Av[1],"lsr")==0)||
        (stricmp(Av[1],"asl")==0)||
        (stricmp(Av[1],"rol")==0)||
        (stricmp(Av[1],"ror")==0)  ) &&
        (stricmp(Av[2],"a")==0))
    {
        //get rid of "a"
        Av[2][0]=0;
    }

    return mne;
}



MNE * findmne(char *str)
{
    int i;
    char c;
    MNE *mne;
    char buf[MAXLINE];

#if OlafDotop
    if (str[0] == '.')
    {    /* Allow .OP for OP */
        str++;
    }
#endif
    for (i = 0; (c = str[i]); ++i)
    {
        if (c >= 'A' && c <= 'Z')
            c += 'a' - 'A';
        buf[i] = c;
    }
    buf[i] = 0;
    for (mne = MHash[hash1(buf)]; mne; mne = mne->next)
    {
        if (strcmp(buf, mne->name) == 0)
            break;
    }
    return(mne);
}

void v_macro(char *str, MNE *dummy)
{
    STRLIST *base;
    int ddefined = 0;
    STRLIST **slp=NULL, *sl=NULL;
    MACRO *mac=NULL;    /* slp, mac: might be used uninitialised */
    MNE   *mne=NULL;
    uword i;
    char buf[MAXLINE];
    int skipit = !(Ifstack->xtrue && Ifstack->acctrue);

    strlower(str);
    if (skipit)
    {
        ddefined = 1;
    }
    else
    {
        ddefined = (findmne(str) != NULL);
        if (F_listfile && ListMode)
            outlistfile("");
    }
    if (!ddefined)
    {
        base = NULL;
        slp = &base;
        mac = (MACRO *)permalloc(sizeof(MACRO));
        i = hash1(str);
        mac->next = (MACRO *)MHash[i];
        mac->vect = v_execmac;
        mac->name = strcpy(permalloc(strlen(str)+1), str);
        mac->flags = MF_MACRO;
        MHash[i] = (MNE *)mac;
    }
    while (fgets(buf, MAXLINE-1, Incfile->fi))
    {
        char *comment;

        buf[MAXLINE-1]=0;
        /* let's ignore int lines exceeding chars */
        Skipendofbuf(buf);

        if (Xdebug)
            printf("%08lx %s\n", (unsigned long)Incfile, buf);

        ++Incfile->lineno;
        Disable_me = 1;
        comment = cleanup(buf);
        Disable_me = 0;
        mne = parse(buf);
        if (Av[1][0])
        {
            if (mne && mne->flags & MF_ENDM)
            {
                if (!ddefined)
                    mac->strlist = base;
                return;
            }
        }
        if (!skipit && F_listfile && ListMode)
            outlistfile(comment);
        if (!ddefined)
        {
            sl = (STRLIST *)permalloc(STRLISTSIZE+1+strlen(buf));
            strcpy(sl->buf, buf);
            *slp = sl;
            slp = &sl->next;
        }
    }
    asmerr( ERROR_PREMATURE_EOF, true, NULL );
}


void addhashtable(MNE *mne)
{
    int i, j;
    uword opcode[NUMOC];

    for (; mne->vect; ++mne)
    {
        memcpy(opcode, mne->opcode, sizeof(mne->opcode));
        for (i = j = 0; i < NUMOC; ++i)
        {
            mne->opcode[i] = 0;     /* not really needed */
            if (mne->okmask & (1L << i))
                mne->opcode[i] = opcode[j++];
        }
        i = hash1(mne->name);
        mne->next = MHash[i];
        MHash[i] = mne;
    }
}


static uword hash1(char *str)
{
    uword result = 0;

    while (*str)
        result = (result << 2) ^ *str++;
    return(result & MHASHAND);
}

void pushinclude(char *str)
{
    INCFILE *inf;
    FILE *fi;

    if ((fi = pfopen(str, "rb")) != NULL)
    {
        if (F_verbose > 1 && F_verbose != 5 )
            printf("%.*s Including file \"%s\"\n", Inclevel*4, "", str);
        ++Inclevel;
        if (F_listfile)
#if OlafPasses
            fprintf(FI_listfile, "------- FILE %s LEVEL %d PASS %d\n", str, Inclevel, pass);
#else
        fprintf(FI_listfile, "------- FILE %s\n", str);
#endif
        inf = (INCFILE *)zmalloc(sizeof(INCFILE));
        inf->next    = Incfile;
        inf->name    = strcpy(ckmalloc(strlen(str)+1), str);
        inf->fi = fi;
        inf->lineno = 0;
        Incfile = inf;
        return;
    }
    //printf("Warning: Unable to open '%s'\n", str);
    printf("include: Unable to open '%s'\nAborting\n", str);
    exit(1);
    return;
}

char Stopend[] = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 };

int asmerr(int err, bool abort, char *sText )
{
    char *str;
    INCFILE *incfile;

    if (Stopend[err])
        StopAtEnd = 1;
    for (incfile = Incfile; incfile && (incfile->flags & INF_MACRO); incfile=incfile->next);
    str = Errors[err];
    if(incfile)
    {

#ifdef DAD

    /* Error output format changed to be Visual-Studio compatible.
       Output now file (line): error: string
    */
    if (F_listfile)
    {
        fprintf(FI_listfile, "%s (%d): error: ", incfile->name, (int)incfile->lineno );
        fprintf(FI_listfile, str, sText ? sText : "" );
        fprintf(FI_listfile, "\n" );
    }
    printf( "%s (%d): error: ", incfile->name, (int)incfile->lineno );
    printf( str, sText ? sText : "" );
    printf( "\n" );


#else

    if (F_listfile)
        fprintf(FI_listfile, "*line %7ld %-10s %s\n", incfile->lineno, incfile->name, str);
    printf("line %7ld %-10s %s\n", incfile->lineno, incfile->name, str);

#endif
    }
    if ( abort )
    {
        puts("Aborting assembly");
        if (F_listfile)
            fputs("Aborting assembly\n", FI_listfile);

        exit( 1 );
    }

    return err;
}

char * zmalloc(int bytes)
{
    char *ptr = malloc(bytes);
    if (ptr)
    {
        memset(ptr, 0, bytes);
        return(ptr);
    }
    panic("unable to malloc");
    return NULL;
}

char * ckmalloc(int bytes)
{
    char *ptr = malloc(bytes);
    if (ptr)
    {
        return(ptr);
    }
    panic("unable to malloc");
    return NULL;
}

char * permalloc(int bytes)
{
    static char *buf;
    static int left;
    char *ptr;

    /* Assume sizeof(union align) is a power of 2 */

    union align
    {
        int l;
        void *p;
        void (*fp)(void);
    };

    bytes = (bytes + sizeof(union align)-1) & ~(sizeof(union align)-1);
    if (bytes > left)
    {
        if ((buf = malloc(ALLOCSIZE)) == NULL)
            panic("unable to malloc");
        memset(buf, 0, ALLOCSIZE);
        left = ALLOCSIZE;
        if (bytes > left)
            panic("software error");
    }
    ptr = buf;
    buf += bytes;
    left -= bytes;
    return(ptr);
}

char * strlower(char *str)
{
    char c;
    char *ptr;

    for (ptr = str; (c = *ptr); ++ptr)
    {
        if (c >= 'A' && c <= 'Z')
            *ptr = c | 0x20;
    }
    return(str);
}

int main(int ac, char **av)
{
    int nError = MainShadow( ac, av );

    if ( nError )
        printf( "Fatal assembly error: %s\n", Errors[ nError ] );
    if(maxorgsofar>0) printf("End address: $%04X\n",maxorgsofar-1);
    DumpSymbolTable();

    return nError;
}

