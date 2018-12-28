/****** StrCopy **************************************************************
* NAME
*   StrCopy -- copies an 8-bit string
* SYNOPSIS
*   ptr = StrCopy(src, dest)
*   D0            A0   A1
*
*   UBYTE* StrCopy(const UBYTE*, UBYTE*);
* FUNCTION
*   Copies a zero-terminated string from one address to another.
* INPUTS
*   src - pointer to a zero-terminated string.
*   dst - points to memory space big enough to hold the copy.
* RESULT
*   Addres of zero-terminator of copy. Can be passed as dest to another
*   StrCopy call to concatenate strings, assuming the destination buffer is
*   big enough. 
* NOTES
*   May be used for any 8-bit codepage and UTF-8.
* EXAMPLE
*   String concatenation:
*
*   UBYTE *s1 = "abcd";
*   UBYTE *s2 = "efghi";
*   UBYTE d[10];
*
*   StrCopy(s2, StrCopy(s1, d));
*
*   Now 'd' contains "abcdefghi", zero-terminated.
* SEE ALSO
*   StrNew, StrCopyW, StrCopyL
*
*****************************************************************************/

		.global	_StrCopy
			
_StrCopy:
		MOVE.B	(a0)+,(a1)+
		BNE.S	_StrCopy
		MOVE.L	a1,d0
		SUBQ.L	#1,d0
		RTS
