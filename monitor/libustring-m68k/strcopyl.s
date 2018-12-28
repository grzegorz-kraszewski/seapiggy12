/****** StrCopyL *************************************************************
* NAME
*   StrCopyL -- copies a 32-bit Unicode string
* SYNOPSIS
*   ptr = StrCopyL(src, dest)
*   D0             A0   A1
*
*   ULONG* StrCopyL(const ULONG*, ULONG*);
* FUNCTION
*   Copies a zero-terminated 32-bit (UTF-32/UCS-4) string from one address to
*   another.
* INPUTS
*   src - address of a zero-terminated 32-bit string.
*   dst - address of memory space big enough to hold the copy.
* RESULT
*   Addres of zero-terminator of copy. Can be passed as dest to another
*   StrCopyL call to concatenate strings, assuming the destination buffer is
*   big enough. 
* NOTES
*   Can be used for both big and little endian strings.
* SEE ALSO
*   StrNewL, StrCopy, StrCopyW
*
*****************************************************************************/

		.global	_StrCopyL
			
_StrCopyL:
		MOVE.L	(a0)+,(a1)+
		BNE.S	_StrCopyL
		MOVE.L	a1,d0
		SUBQ.L	#4,d0
		RTS
