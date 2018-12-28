/****** StrCountW *************************************************************
* NAME
*   StrCountW -- counts characters in UTF-16 string
* SYNOPSIS
*   count = StrCountW(string)
*   D0                A0
*
*   LONG StrCount(const UWORD*);
* FUNCTION
*   Counts characters in a 16-bit string. If UTF-16 surrogate pair is
*   encountered, it is counted as one character. Surrogate pairs are
*   validated, broken encodings stop the function and return a negative error
*   value. Terminating zero is not counted.
* INPUTS
*   string - string to be sized.
* RESULT
*   Zero or positive - number of characters in the string.
*   Negative - one of error constants:
*   - EVSTR_U16_LOW_SURROGATE_UNEXPECTED, is returned when low surrogate
*     does not follow a high one. 
*   - EVSTR_U16_LOW_SURROGATE_MISSING, is returned when there is no low
*     surrogate after high one.
* NOTES
*   Only for big endian strings.
* SEE ALSO
*   StrSize, StrCount, StrCountU, StrCountL
*
*****************************************************************************/

		.global	_StrCountW

E_LOW_UNEXP	= -1
E_LOW_MISS	= -2
						
_StrCountW:
		MOVEQ	#-1,d0                  /* char counter */
charplus:	ADDQ.L	#1,d0
		MOVE.W	(a0)+,d1
		BEQ.S	endstr
		CMPI.W	#0xD800,d1              /* $0000-$D7FF */
		BCS.S	charplus                /* is regular character */
		CMPI.W	#0xE000,d1              /* $E000-$FFFF */
		BCC.S	charplus                /* is regular character */
		CMPI.W	#0xDC00,d1		/* $D800-$DBFF */
		BCS.S	lowsurr                 /* is high surrogate */
		MOVEQ	#E_LOW_UNEXP,d0
		BRA.S	endstr
lowsurr:	MOVE.W	(a0)+,d1
		CMPI.W	#0xDC00,d1
		BCS.S	lowmiss
		CMPI.W	#0xE000,d1
		BCC.S	charplus
lowmiss:	MOVEQ	#E_LOW_MISS,d0
endstr:		RTS
