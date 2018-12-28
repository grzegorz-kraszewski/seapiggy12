/****** StrCountL ************************************************************
* NAME
*   StrCountL -- counts characters in UTF-32 string
* SYNOPSIS
*   count = StrCountL(string)
*   D0                A0
*
*   LONG StrCount(const ULONG*);
* FUNCTION
*   Counts characters in a string. Terminating zero is not counted.
*   Codepoints above $0010FFFF (not in 17 defined planes) are rejected,
*   function stops with error.
* INPUTS
*   string - string to be counted.
* RESULT
*   Zero or positive - number of characters in the string.
*   Negative - EVSTR_U32_OUT_OF_RANGE, invalid codepoint encountered.
* NOTES
*   Only for big endian strings.
* SEE ALSO
*   StrSizeL, StrCount, StrCountW, StrCountU
*
*****************************************************************************/

		.global	_StrCountL

E_OUTOFRANGE	= -3

_StrCountL:
		MOVE.L	d2,-(sp)
		MOVEQ	#-1,d0
		MOVE.L	#0x00110000,d2
charplus:	ADDQ.L	#1,d0
		MOVE.L	(a0)+,d1
		BEQ.S	endstr
		CMP.L	d2,d1
		BCS.S	charplus			
		MOVEQ	#E_OUTOFRANGE,d0
endstr:		MOVE.L	(sp)+,d2
		RTS
