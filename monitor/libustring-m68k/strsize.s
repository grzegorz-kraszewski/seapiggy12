/****** StrSize **************************************************************
* NAME
*   StrSize -- calculates size of an 8-bit string
* SYNOPSIS
*   size = StrSize(string)
*   D0             A0
*
*   ULONG StrSize(const UBYTE*);
* FUNCTION
*   Calculates byte size of given string. Size includes terminating zero.
* INPUTS
*   string - string to be sized.
* RESULT
*   String size in bytes. It is guarranted to be at least 1.
* NOTES
*   May be used for any 8-bit codepage and UTF-8.
* SEE ALSO
*   StrSizeW, StrSizeL, StrCount
*
*****************************************************************************/

		.global	_StrSize
			
_StrSize:
		MOVEA.L	a0,a1
loop:		TST.B	(a0)+
		BNE.S	loop
		SUBA.L	a1,a0
		MOVE.L	a0,d0
		RTS
