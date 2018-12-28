/****** StrSizeL *************************************************************
* NAME
*   StrSizeL -- calculates size of a 32-bit string
* SYNOPSIS
*   size = StrSizeL(string)
*   D0              A0
*
*   ULONG StrSizeL(const ULONG*);
* FUNCTION
*   Calculates byte size of given string. Size includes terminating zero.
* INPUTS
*   string - string to be sized.
* RESULT
*   String size in bytes. It is guarranted to be at least 4 and evenly
*   divisible by 4.
* NOTES
*   May be used for UCS-4/UTF-32, any endian.
* SEE ALSO
*   StrSize, StrSizeW, StrCountL
*
*****************************************************************************/

		.global	_StrSizeL
			
_StrSizeL:
		MOVEA.L	a0,a1
loop:		TST.L	(a0)+
		BNE.S	loop
		SUBA.L	a1,a0
		MOVE.L	a0,d0
		RTS
