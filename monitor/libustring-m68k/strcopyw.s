/****** StrCopyW *************************************************************
* NAME
*   StrCopyW -- copies a 16-bit Unicode string
* SYNOPSIS
*   ptr = StrCopyW(src, dest)
*   D0             A0   A1
*
*   UWORD* StrCopyW(const UWORD*, UWORD*);
* FUNCTION
*   Copies a zero-terminated 16-bit (UTF-16/UCS-2) string from one address to
*   another. 
* INPUTS
*   src - address of a zero-terminated 16-bit string.
*   dst - address of memory space big enough to hold the copy.
* RESULT
*   Addres of zero-terminator of copy. Can be passed as dest to another
*   StrCopyW call to concatenate strings, assuming the destination buffer is
*   big enough. 
* NOTES
*   Can be used with both big and little endian strings.
* SEE ALSO
*   StrNewW, StrCopy, StrCopyL
*
*****************************************************************************/

		.global	_StrCopyW
		
_StrCopyW:
		MOVE.W	(a0)+,(a1)+
		BNE.S	_StrCopyW
		MOVE.L	a1,d0
		SUBQ.L	#2,d0
		RTS
