/****** Utf8Size *************************************************************
* NAME
*   Utf8Size -- calculates byte size of UTF-8 encoded codepoint
* SYNOPSIS
*   size = Utf8Size(codepoint)
*   D0              D0
*
*   ULONG Utf8Size(ULONG);
* FUNCTION
*   Returns byte size of UTF-8 encoding of given Unicode codepoint.
* INPUTS
*   codepoint - codepoint to be sized. Note that the function does not check
*     if the codepoint is valid Unicode character. Passing UTF-16 surrogate
*     codes yields 2. Passing codes above Plane 16 yields 4. 
* RESULT
*   Number of bytes needed to encode a codepoint in UTF-8, always 1, 2, 3
*   or 4.
* NOTES
*   Lenght ranges are tested from the shortest up. Threshold values ($80,
*   $800, $10000) are constructed starting from $7F + $01, then shifting left.
*   Register usage:
*     D0 - calculated length
*     D1 - codepoint
*     D2 - comparision thresholds
*
*****************************************************************************/

		.global	_Utf8Size
			
_Utf8Size:
		MOVE.L	d2,-(sp)
		MOVEQ	#0x7F,d2
		MOVE.L	d0,d1
		ADDQ.L	#1,d2			
		MOVEQ	#1,d0
		CMP.L	d2,d1
		BCS.S	exit
		LSL.L	#4,d2
		ADDQ.L	#1,d0
		CMP.L	d2,d1
		BCS.S	exit
		LSL.L	#5,d2
		ADDQ.L	#1,d0
		CMP.L	d2,d1
		BCS.S	exit
		ADDQ.L	#1,d0
exit:		MOVE.L	(sp)+,d2
		RTS
