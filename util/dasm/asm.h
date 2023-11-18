
/*
 *  ASM65.H
 *
 *  (c)Copyright 1988, Matthew Dillon, All Rights Reserved.
 *  Modifications Copyright 1995 by Olaf Seibert. All Rights Reserved.
 *
 *  Structures and definitions
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#define MAXLINE 2048

#if !defined(Olaf) || Olaf
#define Olaf        1        /* Olaf Seibert's (KosmoSoft) Improvements */
#define OlafM       1        /* -M option */
#define OlafColon   1        /* Allow label:mne */
#define OlafDol     1        /* Allow 0$ labels */
#define OlafStar    1        /* Allow * for . */
#define OlafByte    1        /* Allow BYTE,etc for DC.B,etc */
#define OlafAsgn    1        /* Allow = for EQU */
#define OlafDotop   1        /* Allow .OP for OP */
//#define OlafFreeFormat    0    /* Decide on looks of word if it is opcode */
//#define OlafHashFormat    1    /* Decide on # and ^ if it is an opcode */
#define OlafIncbin  1        /* INCBIN operation */
#define OlafIncdir  1        /* INCDIR operation */
#define OlafPhase   1        /* silence phase errors sometimes */
#define OlafList    1        /* LIST ON/OFF */
#define OlafListAll 1        /* Option to list all passes, not just last */
#define OlafPasses  1        /* Option to specify max #passes */
#define OlafEnd     1        /* Implement END */
#define OlafDotAssign    1   /* Allow ". EQU expr" to change origin */
#endif

//#if OlafHashFormat && OlafFreeFormat
//#error This cannot be!
//#endif

#define DAD

#ifdef DAD

#ifndef bool
#define bool int
#define false 0
#define true 1
#endif


    enum ASM_ERROR_EQUATES
    {
        ERROR_NONE = 0,
        ERROR_COMMAND_LINE,                             /* Check format of command-line */
        ERROR_FILE_ERROR,                               /* Unable to open file */
        ERROR_NOT_RESOLVABLE,                           /* Source is not resolvable */
        ERROR_TOO_MANY_PASSES,                          /* Too many passes - something wrong */

        ERROR_SYNTAX_ERROR,                             /*  0 */
        ERROR_EXPRESSION_TABLE_OVERFLOW,                /*  1 */
        ERROR_UNBALANCED_BRACES,                        /*  2 */
        ERROR_DIVISION_BY_0,                            /*  3 */
        ERROR_UNKNOWN_MNEMONIC,                         /*  4 */
        ERROR_ILLEGAL_ADDRESSING_MODE,                  /*  5 */
        ERROR_ILLEGAL_FORCED_ADDRESSING_MODE,           /*  6 */
        ERROR_NOT_ENOUGH_ARGUMENTS_PASSED_TO_MACRO,     /*  7 */
        ERROR_PREMATURE_EOF,                            /*  8 */
        ERROR_ILLEGAL_CHARACTER,                        /*  9 */
        ERROR_BRANCH_OUT_OF_RANGE,                      /* 10 */
        ERROR_ERR_PSEUDO_OP_ENCOUNTERED,                /* 11 */
        ERROR_ORIGIN_REVERSE_INDEXED,                   /* 12 */
        ERROR_EQU_VALUE_MISMATCH,                       /* 13 */
        ERROR_ADDRESS_MUST_BE_LT_100,                   /* 14 */
        ERROR_ILLEGAL_BIT_SPECIFICATION,                /* 15 */
        ERROR_NOT_ENOUGH_ARGS,                          /* 16 */
        ERROR_LABEL_MISMATCH,                           /* 17 */
        ERROR_VALUE_UNDEFINED,                          /* 18 */
        ERROR_PROCESSOR_NOT_SUPPORTED,                  /* 20 */
        ERROR_REPEAT_NEGATIVE,                          /* 21 */
    };


    enum REASON_CODES
    {
        REASON_MNEMONIC_NOT_RESOLVED = 1 << 0,
        REASON_OBSCURE = 1 << 1,                        /* fix this! */
        REASON_DC_NOT_RESOLVED = 1 << 2,
        REASON_DV_NOT_RESOLVED_PROBABLY = 1 << 3,
        REASON_DV_NOT_RESOLVED_COULD = 1 << 4,
        REASON_DS_NOT_RESOLVED = 1 << 5,
        REASON_ALIGN_NOT_RESOLVED = 1 << 6,
        REASON_ALIGN_RELOCATABLE_ORIGIN_NOT_KNOWN = 1 << 7,
        REASON_ALIGN_NORMAL_ORIGIN_NOT_KNOWN = 1 << 8,
        REASON_EQU_NOT_RESOLVED = 1 << 9,
        REASON_EQU_VALUE_MISMATCH = 1 << 10,
        REASON_IF_NOT_RESOLVED = 1 << 11,
        REASON_REPEAT_NOT_RESOLVED = 1 << 12,
        REASON_FORWARD_REFERENCE = 1 << 13,
        REASON_PHASE_ERROR = 1 << 14,
    };


#endif


typedef unsigned char ubyte;
typedef unsigned int uword;
#ifdef _WIN32
typedef int ulong;
#else
typedef int myulong;
#define ulong myulong
#endif

#define MNE         struct _MNE
#define MACRO       struct _MACRO
#define INCFILE     struct _INCFILE
#define REPLOOP     struct _REPLOOP
#define IFSTACK     struct _IFSTACK
#define SEGMENT     struct _SEGMENT
#define SYMBOL      struct _SYMBOL
#define STRLIST     struct _STRLIST

#define DEFORGFILL  0
#define SHASHSIZE   1024
#define MHASHSIZE   1024
#define SHASHAND    0x03FF
#define MHASHAND    0x03FF
#define ALLOCSIZE   16384
#define MAXMACLEVEL 32
#define TAB         9

#define OUTFORM1    0
#define OUTFORM2    1
#define OUTFORM3    2

#define AM_IMP          0      /* implied             */
#define AM_IMM8         1      /* immediate 8  bits   */
#define AM_IMM16        2      /* immediate 16 bits   */
#define AM_BYTEADR      3      /* address 8 bits      */
#define AM_BYTEADRX     4      /* address 16 bits     */
#define AM_BYTEADRY     5      /* relative 8 bits     */
#define AM_WORDADR      6      /* index x 0 bits      */
#define AM_WORDADRX     7      /* index x 8 bits      */
#define AM_WORDADRY     8      /* index x 16 bits     */
#define AM_REL          9      /* bit inst. special   */
#define AM_INDBYTEX    10      /* bit-bra inst. spec. */
#define AM_INDBYTEY    11      /* index y 0 bits      */
#define AM_INDWORD     12      /* index y 8 bits      */
#define AM_0X          13      /* index x 0 bits      */
#define AM_0Y          14      /* index y 0 bits      */
#define AM_BITMOD      15      /* ind addr 8 bits     */
#define AM_BITBRAMOD   16      /* ind addr 16 bits    */
#define NUMOC          17

#define AF_IMP          (1L << 0 )
#define AF_IMM8         (1L << 1 )
#define AF_IMM16        (1L << 2 )
#define AF_BYTEADR      (1L << 3 )
#define AF_BYTEADRX     (1L << 4 )
#define AF_BYTEADRY     (1L << 5 )
#define AF_WORDADR      (1L << 6 )
#define AF_WORDADRX     (1L << 7 )
#define AF_WORDADRY     (1L << 8 )
#define AF_REL          (1L << 9 )
#define AF_INDBYTEX     (1L << 10)
#define AF_INDBYTEY     (1L << 11)
#define AF_INDWORD      (1L << 12)
#define AF_0X           (1L << 13)
#define AF_0Y           (1L << 14)
#define AF_BITMOD       (1L << 15)
#define AF_BITBRAMOD    (1L << 16)

#define AM_SYMBOL       (NUMOC+0)
#define AM_EXPLIST      (NUMOC+1)

#define AM_BYTE         AM_BYTEADR
#define AM_WORD         AM_WORDADR
#define AM_LONG         (NUMOC+2)
#define AM_BSS          (NUMOC+3)


STRLIST {
    STRLIST *next;
    char    buf[4];
};

#define STRLISTSIZE    sizeof(STRLIST *)

#define MF_IF       0x04
#define MF_MACRO    0x08
#define MF_MASK     0x10    /* has mask argument (byte) */
#define MF_REL      0x20    /* has rel. address (byte)  */
#define MF_IMOD     0x40    /* instruction byte mod.    */
#define MF_ENDM     0x80    /* is v_endm                */

MNE {
    MNE     *next;                  /* hash          */
    void    (*vect)(char *, MNE *); /* dispatch      */
    char    *name;                  /* actual name   */
    ubyte   flags;                  /* special flags */
    ulong   okmask;
    uword   opcode[NUMOC];          /* hex codes, byte or word (>xFF) opcodes */
};

MACRO {
    MACRO   *next;
    void    (*vect)(char *, MACRO *);
    char    *name;
    ubyte   flags;
    STRLIST *strlist;
};

#define INF_MACRO   0x01
#define INF_NOLIST  0x02

INCFILE {
    INCFILE *next;      /* previously pushed context*/
    char    *name;      /* file name                */
    FILE    *fi;        /* file handle              */
    ulong   lineno;     /* line number in file      */
    ubyte   flags;      /* flags (macro)            */

    /*    Only if Macro    */

    STRLIST *args;      /*  arguments to macro     */
    STRLIST *strlist;   /*  current string list    */
    ulong   saveidx;    /*  save localindex        */
#if OlafDol
    ulong   savedolidx; /*  save localdollarindex  */
#endif
};

#define RPF_UNKNOWN 0x01    /*      value unknown     */

REPLOOP {
    REPLOOP *next;      /* previously pushed context    */
    ulong   count;      /* repeat count                 */
    long   seek;       /* seek to top of repeat        */
    ulong   lineno;     /* line number of line before   */
    INCFILE *file;      /* which include file are we in */
    ubyte   flags;
};

#define IFF_UNKNOWN 0x01    /* value unknown */
#define IFF_BASE    0x04

IFSTACK {
    IFSTACK *next;      /* previous IF                  */
    INCFILE *file;      /* which include file are we in */
    ubyte   flags;
    ubyte   xtrue;      /* 1 if true, 0 if false        */
    ubyte   acctrue;    /* accumulatively true (not incl this one) */
};

#define SF_UNKNOWN  0x01    /* ORG unknown                  */
#define SF_REF      0x04    /* ORG referenced               */
#define SF_BSS      0x10    /* uninitialized area (U flag)  */
#define SF_RORG     0x20    /* relocatable origin active    */

SEGMENT {
    SEGMENT *next;      /* next segment in segment list */
    char    *name;      /* name of segment              */
    ubyte   flags;      /* for ORG                      */
    ubyte   rflags;     /* for RORG                     */
    ulong   org;        /* current org                  */
    ulong   rorg;       /* current rorg                 */
    ulong   initorg;
    ulong   initrorg;
    ubyte   initflags;
    ubyte   initrflags;
};

#define SYM_UNKNOWN 0x01    /* value unknown        */
#define SYM_REF     0x04    /* referenced           */
#define SYM_STRING  0x08    /* result is a string   */
#define SYM_SET     0x10    /* SET instruction used */
#define SYM_MACRO   0x20    /* symbol is a macro    */
#define SYM_MASREF  0x40    /* master reference     */

SYMBOL {
    SYMBOL  *next;          /* next symbol in hash list       */
    char    *name;          /* symbol name or string if expr. */
    char    *string;        /* if symbol is actually a string */
    ubyte   flags;          /* flags                          */
    ubyte   addrmode;       /* addressing mode (expressions)  */
    ulong   value;          /* current value                  */
    uword   namelen;        /* name length                    */
};

extern SYMBOL   *SHash[];
extern MNE      *MHash[];
extern INCFILE  *Incfile;
extern REPLOOP  *Reploop;
extern SEGMENT  *Seglist;
extern IFSTACK  *Ifstack;

extern SEGMENT  *Csegment;  /* current segment */
extern char     *Av[];
extern char     Avbuf[];
extern uword    Adrbytes[];
extern uword    Cvt[];
extern MNE      Ops[];
extern uword    Opsize[];
extern int      Mnext;      /* mnemonic extension */
extern uword    Mlevel;

extern ubyte    Xtrace;
extern bool     Xdebug;
extern ubyte    MsbOrder;
extern ubyte    Outputformat;
extern ulong    Redo, Redo_why, Redo_eval;
#if OlafPhase
extern ulong    Redo_if;
#endif
extern ulong    Localindex, Lastlocalindex;
#if OlafDol
extern ulong    Localdollarindex, Lastlocaldollarindex;
#endif

extern ubyte    F_format;
extern ubyte    F_verbose;
extern char    *F_outfile;
extern char    *F_listfile;
extern char    *F_symfile;
//extern char    *F_temppath;
extern FILE    *FI_listfile;
extern FILE    *FI_temp;
extern ubyte    Fisclear;
extern ulong    Plab, Pflags;
extern int lastrorg;
extern /*char*/ int     Inclevel;
extern char     ListMode;
extern ulong    Processor;

//extern uword _fmode;
extern ulong  CheckSum;

/* main.c */
extern  ubyte Listing;
void    findext(char *str);
int     asmerr(int err, bool abort, char *sText);
char   *sftos(int val, int flags);
void    rmnode(void **base, int bytes);
void    addhashtable(MNE *mne);
void    pushinclude(char *str);
char   *permalloc(int bytes);
char   *zmalloc(int bytes);
char   *ckmalloc(int bytes);
char   *strlower(char *str);

/* symbols.c */
void    setspecial(int value, int flags);
SYMBOL *allocsymbol(void);
SYMBOL *findsymbol(char *str, int len);
SYMBOL *createsymbol(char *str, int len);
void    freesymbollist(SYMBOL *sym);
void    programlabel(void);

/* ops.c */
extern  ubyte Gen[];
extern  int Glen;
void    v_set(char *str, MNE *);
void    v_setstr(char *str, MNE *);
void    v_mexit(char *str, MNE *);
void    closegenerate(void);
void    v_list(char *, MNE *), v_include(char *, MNE *),
        v_seg(char *, MNE *), v_dc(char *, MNE *), v_ds(char *, MNE *),
        v_org(char *, MNE *), v_rorg(char *, MNE *), v_rend(char *, MNE *),
        v_align(char *, MNE *), v_subroutine(char *, MNE *),
        v_equ(char *, MNE *), v_eqm(char *, MNE *), v_set(char *, MNE *),
        v_macro(char *, MNE *), v_endm(char *, MNE *),
        v_mexit(char *, MNE *), v_ifconst(char *, MNE *),
        v_ifnconst(char *, MNE *), v_if(char *, MNE *),
        v_else(char *, MNE *), v_endif(char *, MNE *),
        v_repeat(char *, MNE *), v_repend(char *, MNE *),
        v_err(char *, MNE *), v_hex(char *, MNE *), v_trace(char *, MNE *),
        v_end(char *, MNE *), v_echo(char *, MNE *),
        v_processor(char *, MNE *), v_incbin(char *, MNE *),
        v_incprg(char *, MNE *), v_incdir(char *, MNE *);
void    v_execmac(char *str, MACRO *mac);
void    v_mnemonic(char *str, MNE *mne);
#if OlafIncdir
FILE *pfopen(const char *, const char *);
#else
#define pfopen(name, mode)  fopen(name, mode)
#endif

/* exp.c */
SYMBOL *eval(char *str, int wantmode);

/* end of asm.h */
