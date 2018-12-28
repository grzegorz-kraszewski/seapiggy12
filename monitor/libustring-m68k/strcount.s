/****** StrCount **************************************************************
* NAME
*   StrCount -- counts characters in 8-bit string
* SYNOPSIS
*   count = StrCount(string)
*   D0               A0
*
*   LONG StrCount(const UBYTE*);
* FUNCTION
*   Counts characters in 8-bit string. Terminating zero is not counted. The
*   function is equivalent to standard library strlen().
* INPUTS
*   string - string to be sized.
* RESULT
*   Zero or positive - number of characters in the string.
*   Negative result is never returned, this function never fails.
* NOTES
*   Do not use it for UTF-8, use StrCountU instead.
* SEE ALSO
*   StrSize, StrCountU, StrCountW, StrCountL
*
*****************************************************************************/

		.global	_StrCount

		.xref	_StrSize
						
_StrCount:
		BSR.S	StrSize
		SUBQ.L	#1,d0
		RTS
