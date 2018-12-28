/* VString library header file for GCC */

#include <exec/types.h>

/* memory blocks */

APTR AllocVecPooled(APTR pool __asm("a0"), ULONG size __asm("d0"));
APTR CloneMem(const APTR src __asm("a0"), ULONG size __asm("d0"));
APTR CloneMemPooled(APTR pool __asm("a0"), const APTR src __asm("a1"), ULONG size __asm("d0"));
void FreeVecPooled(APTR pool __asm("a0"), APTR block __asm("a1"));

/* string copying */

UBYTE* StrCopy(const UBYTE *s __asm("a0"), UBYTE *d __asm("a1"));
UWORD* StrCopyW(const UWORD *s __asm("a0"), UWORD *d __asm("a1"));
ULONG* StrCopyL(const ULONG *s __asm("a0"), ULONG *d __asm("a1"));
#define StrCopyU(s) StrCopy(s)

/* string cloning */

UBYTE* StrClone(const UBYTE *s __asm("a0"));
UWORD* StrCloneW(const UWORD *s __asm("a0"));
ULONG* StrCloneL(const ULONG *s __asm("a0"));
#define StrCloneU(s) StrClone(s)
UBYTE* StrClonePooled(APTR pool __asm("a0"), const UBYTE *s __asm("a1"));
UWORD* StrClonePooledW(APTR pool __asm("a0"), const UWORD *s __asm("a1"));
ULONG* StrClonePooledL(APTR pool __asm("a0"), const ULONG *s __asm("a1"));
#define StrClonePooledU(p,s) StrClonePooled(p,s)

/* string size and character count */

ULONG StrSize(const UBYTE *s __asm("a0"));
ULONG StrSizeW(const UWORD *s __asm("a0"));
ULONG StrSizeL(const ULONG *s __asm("a0"));
#define StrSizeU(s) StrSize(s)
LONG StrCount(const UBYTE *s __asm("a0"));
/* LONG StrCountU(__asm("a0") const UBYTE *s); */
LONG StrCountW(const UWORD *s __asm("a0"));
LONG StrCountL(const ULONG *s __asm("a0"));

/* UTF-8 support */

ULONG Utf8Size(ULONG cp __asm("d0"));

/* error codes */

#define EVSTR_U16_LOW_SURROGATE_UNEXPECTED    -1
#define EVSTR_U16_LOW_SURROGATE_MISSING       -2
#define EVSTR_U32_OUT_OF_RANGE                -3