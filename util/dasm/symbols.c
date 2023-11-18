
/*
 *  SYMBOLS.C
 *
 *  (c)Copyright 1988, Matthew Dillon, All Rights Reserved.
 */

#include "asm.h"

static uword hash1(char *str, int len);
SYMBOL *allocsymbol(void);

static SYMBOL org;
static SYMBOL special;
static SYMBOL specchk;

void setspecial(int value, int flags)
{
    special.value = value;
    special.flags = flags;
}

SYMBOL * findsymbol(char *str, int len)
{
    uword h1;
    SYMBOL *sym;
    char buf[MAXLINE];

    if (len > 50)
        len = 50;
    if (str[0] == '.')
    {
        if (len == 1)
        {
			/* -D.=$1000 bugfix start*/
			if(!Csegment) 
				return NULL;
			/* -D.=$1000 bugfix end*/
            if (Csegment->flags & SF_RORG)
            {
                org.flags = Csegment->rflags & SYM_UNKNOWN;
                org.value = Csegment->rorg;
            }
            else
            {
                org.flags = Csegment->flags & SYM_UNKNOWN;
                org.value = Csegment->org;
            }
            return(&org);
        }
        if (len == 2 && str[1] == '.')
            return(&special);
        if (len == 3 && str[1] == '.' && str[2] == '.')
        {
            specchk.flags = 0;
            specchk.value = CheckSum;
            return(&specchk);
        }
        sprintf(buf, "%d%.*s", Localindex, len, str);
        len = strlen(buf);
        str = buf;
    }
#if OlafDol
    else if (str[len - 1] == '$')
    {
        sprintf(buf, "%d$%.*s", Localdollarindex, len, str);
        len = strlen(buf);
        str = buf;
    }
#endif
    h1 = hash1(str, len);
    for (sym = SHash[h1]; sym; sym = sym->next)
    {
        if ((sym->namelen == len) && !memcmp(sym->name, str, len))
            break;
    }
    return(sym);
}

SYMBOL * createsymbol(char *str, int len)
{
    SYMBOL *sym;
    uword h1;
    char buf[MAXLINE];

    if (len > 50)
        len = 50;
    if (str[0] == '.')
    {
        sprintf(buf, "%d%.*s", Localindex, len, str);
        len = strlen(buf);
        str = buf;
    }
#if OlafDol
    else if (str[len - 1] == '$')
    {
        sprintf(buf, "%d$%.*s", Localdollarindex, len, str);
        len = strlen(buf);
        str = buf;
    }
#endif
    sym = (SYMBOL *)allocsymbol();
    sym->name = permalloc(len+1);
    memcpy(sym->name, str, len);    /*  permalloc zeros the array for us */
    sym->namelen = len;
    h1 = hash1(str, len);
    sym->next = SHash[h1];
    sym->flags= SYM_UNKNOWN;
    SHash[h1] = sym;
    return(sym);
}

static uword hash1(char *str, int len)
{
    uword result = 0;

    while (len--)
        result = (result << 2) ^ *str++;
    return(result & SHASHAND);
}

/*
 *  Label Support Routines
 */

void programlabel(void)
{
    int len;
    SYMBOL *sym;
    SEGMENT *cseg = Csegment;
    char *str;
    ubyte   rorg = cseg->flags & SF_RORG;
    ubyte   cflags = (rorg) ? cseg->rflags : cseg->flags;
    ulong   pc = (rorg) ? cseg->rorg : cseg->org;

    Plab = cseg->org;
    Pflags = cseg->flags;
    str = Av[0];
    if (*str == 0)
        return;
    len = strlen(str);
#if !OlafColon  /* not needed - handled by parsing */
    if (str[len-1] == ':')
        --len;
#endif
#if OlafDol
    if (str[0] != '.' && str[len-1] != '$')
    {
        Lastlocaldollarindex++;
        Localdollarindex = Lastlocaldollarindex;
    }
#endif

    /*
     *  Redo:   unknown and referenced
     *      referenced and origin not known
     *      known and phase error    (origin known)
     */

    if ((sym = findsymbol(str, len)) != NULL)
    {
        if ((sym->flags & (SYM_UNKNOWN|SYM_REF)) == (SYM_UNKNOWN|SYM_REF))
        {
            ++Redo;
            Redo_why |= REASON_FORWARD_REFERENCE;
            if (Xdebug)
                printf("redo 13: '%s' %04x %04x\n", sym->name, sym->flags, cflags);
        }
        else if ((cflags & SYM_UNKNOWN) && (sym->flags & SYM_REF))
        {
            ++Redo;
            Redo_why |= REASON_FORWARD_REFERENCE;
        }
        else if (!(cflags & SYM_UNKNOWN) && !(sym->flags & SYM_UNKNOWN))
        {
            if (pc != sym->value)
            {
#if OlafPhase
            /*
             * If we had an unevaluated IF expression in the
             * previous pass, don't complain about phase errors
             * too loudly.
             */
                if (F_verbose >= 1 || !(Redo_if & (REASON_OBSCURE)))
#endif
                {
                    char sBuffer[ 128 ];
                    sprintf( sBuffer, "%s %s", sym->name, sftos( sym->value, 0 ) );
                    /*, sftos(sym->value,
                        sym->flags) ); , sftos(pc, cflags & 7));*/
                    asmerr( ERROR_LABEL_MISMATCH, false, sBuffer );
                }
                ++Redo;
                Redo_why |= REASON_PHASE_ERROR;
            }
        }
    }
    else
    {
        sym = createsymbol(str, len);
    }
    sym->value = pc;
    sym->flags = (sym->flags & ~SYM_UNKNOWN) | (cflags & SYM_UNKNOWN);
}

SYMBOL *SymAlloc;

SYMBOL * allocsymbol(void)
{
    SYMBOL *sym;

    if (SymAlloc)
    {
        sym = SymAlloc;
        SymAlloc = SymAlloc->next;
        memset(sym, 0, sizeof(SYMBOL));
    }
    else
    {
        sym = (SYMBOL *)permalloc(sizeof(SYMBOL));
    }
    return(sym);
}

void freesymbol(SYMBOL *sym)
{
    sym->next = SymAlloc;
    SymAlloc = sym;
}

void freesymbollist(SYMBOL *sym)
{
    SYMBOL *next;

    while (sym)
    {
        next = sym->next;
        sym->next = SymAlloc;
        if (sym->flags & SYM_STRING)
            free(sym->string);
        SymAlloc = sym;
        sym = next;
    }
}

