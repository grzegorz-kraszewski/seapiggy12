/****** StrSizeW *************************************************************
* NAME
*   StrSizeW -- calculates size of a 16-bit string
* SYNOPSIS
*   size = StrSizeW(string)
*   D0              A0
*
*   ULONG StrSizeW(const UWORD*);
* FUNCTION
*   Calculates byte size of given string. Size includes terminating zero.
* INPUTS
*   string - string to be sized.
* RESULT
*   String size in bytes. It is guarranted to be at least 2 and even.
* NOTES
*   May be used for UCS-2 and UTF-16, any endian.
* SEE ALSO
*   StrSize, StrSizeL, StrCountW
*
*****************************************************************************/

		.global	_StrSizeW
			
_StrSizeW:
		MOVEA.L	a0,a1
loop:		TST.W	(a0)+
		BNE.S	loop
		SUBA.L	a1,a0
		MOVE.L	a0,d0
		RTS
