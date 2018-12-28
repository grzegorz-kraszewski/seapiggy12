/****i* utf8enc **************************************************************
* NAME
*   utf8enc -- validates Unicode codepoint and encodes as UTF-8
* SYNOPSIS
*   error = utf8enc(codepoint, dest)
*   D0              D0         A0
*
*   ULONG utf8enc(ULONG, UBYTE*);
* FUNCTION
*   1. Checks if passed codepoint is Unicode valid. UTF-16 surrogate codes and
*      codes above $10FFFF (beyond Plane 16) are rejected.
*   2. Encodes as UTF-8 and places encoded bytes at 'dest'.
* INPUTS
*   codepoint - codepoint to be encoded
*   dest - memory pointer, where encoded bytes will be placed. No checks done.
* RESULT
*   error - 0 on success, negative error code if codepoint is invalid:
*     EVSTR_U8_SURROGATE - codepoint represents UTF-16 surrogate
*     EVSTR_OUT_OF_RANGE - codepoint beyond Plane 16.
* NOTES
*   For valid codepoint A0 register is updated, so it points to a next byte
*   after just encoded character. Then utf8enc can be called in a loop and
*   destination pointer updates automatically. 
*
*****************************************************************************/

/* Error codes */

E_OUT_OF_RANGE	= -3
E_SURROGATE	= -7

		.global	_utf8enc
			
_utf8enc:
		CMPI.L	#0x00000080,d0
		BCC.S	twobytes
		MOVE.B	d0,(a0)+
		MOVEQ	#0,d0
		RTS
		
twobytes:	CMPI.L	#0x00000800,d0
		BCC.S	threebytes
		ADDQ.L	#2,a0
		MOVEA.L	a0,a1
		BSR.S	storecont
		ANDI.B	#0x1F,d0
		ORI.B	#0xC0,d0
		MOVE.B	d0,-(a1)
		MOVEQ	#0,d0
		RTS
		
threebytes:	CMPI.L	#0x00010000,d0
		BCC.S	fourbytes
		MOVE.L	d0,d1
		ANDI.W	#0xF800,d1
		CMPI.W	#0xD800,d1
		BEQ.S	surrogate
		ADDQ.L	#3,a0
		MOVEA.L	a0,a1
		BSR.S	storecont
		BSR.S	storecont
		ANDI.B	#0x0F,d0
		ORI.B	#0xE0,d0
		MOVE.B	d0,-(a1)
		MOVEQ	#0,d0
		RTS

fourbytes:	CMPI.L	#0x00110000,d0
		BCC.S	outofrange
		ADDQ.L	#4,a0
		MOVEA.L	a0,a1
		BSR.S	storecont
		BSR.S	storecont
		BSR.S	storecont
		ANDI.B	#0x07,d0
		ORI.B	#0xF0,d0
		MOVE.B	d0,-(a1)
		MOVEQ	#0,d0	
		RTS

surrogate:	MOVEQ	#E_SURROGATE,d0
		RTS

outofrange:	MOVEQ	#E_OUT_OF_RANGE,d0
		RTS
		
storecont:	MOVE.L	d0,d1
		ANDI.B	#0x3F,d1
		LSR.L	#6,d0
		ORI.B	#0x80,d1
		MOVE.B	d1,-(a1)
		RTS
