/****i* utf8dec **************************************************************
* NAME
*   utf8dec -- attempts to decode an UTF-8 character
* SYNOPSIS
*   codepoint = utf8dec(src)
*   D0                  A0
* FUNCTION
*   Attempts to decode UTF-8 sequence pointed by A0. If decoding succeeds,
*   D0 cointains the codepoint, A0 is updated to point to the next byte after
*   the sequence. In case of broken sequence, D0 contains negative error code,
*   A0 is unchanged.
*
*   This is strict decoder, it fails on overlong sequences, or tricks like
*   Updated UTF-8 or WTF-8. 
* INPUTS
*   src - pointer to UTF-8 sequence to be decoded.
* RESULT
*   D0 - codepoint, negative error code on failure.
*   A0 - moved to the next byte after sequence on success.
*
*****************************************************************************/
	

/* Error codes */

E_OUT_OF_RANGE	= -3                   /* codepoint higher than $10FFFF */
E_UNEXP_CONT	= -4                   /* unexpected continuation byte */
E_INVALID_BYTE	= -5                   /* $FE or $FF */
E_CONT_MISS     = -6                   /* missing continuation byte */
E_SURROGATE	= -7                   /* decoded UTF-16 surrogate */
E_OVERLONG      = -8                   /* decoded UTF-8 overlong encoding */

		.global	_utf8dec

/*----------------------------------------------------------------------------
  First stage calculates number of leading '1' bits in the first byte,
  decreased by 1, which is equal to number of expected continuation bytes:
  
  byte        calc. number     further action
  ----------------------------------------------------
  0xxxxxxx         -1           single byte sequence
  10xxxxxx          0           unexpected continuator
  110xxxxx          1           1 continuation byte
  1110xxxx          2           2 continuation bytes
  11110xxx          3           3 continuation bytes
  111110xx          4           4 continuation bytes
  1111110x          5           5 continuation bytes
  11111110          6           illegal byte $FE
  11111111          7           illegal byte $FF
  
  At the end of this stage calculated number is in D0. 68000 code uses a loop
  with shifting examined byte left. 68020 code uses BFFFO instruction after
  bitwise negation of the examined byte.
  
  Single byte sequence is the most probable, so it is made the shortest
  execution path by fast testing of bit 7.
----------------------------------------------------------------------------*/

_utf8dec:
		MOVEQ	#0,d0				
		MOVE.B	(a0)+,d0
		BMI.S	not7bit
		RTS

not7bit:
		MOVEM.L	d2-d4,-(sp)
		MOVE.L	d0,d2
		
		.if CPU==68020
		
		NOT.B	d0
		BFFFO	d0{24:8},d0
		SUBI.B	#25,d0
		
		.else
		
		MOVEQ	#7,d1
		TST.B	d0
		BRA.S	zero2
zero1:		LSL.B	#1,d0
zero2:		DBPL	d1,zero1       /* keep shifting on '1' bit */
		MOVE.B	d1,d0
		NEG.B	d0
		ADDQ.B	#6,d0
		
		.endif
		
/*----------------------------------------------------------------------------
  This simple section rejects unexpected continuation bytes (D0 contains 0)
  and illegal $FE, $FF values (D0 contains 6 or 7).
----------------------------------------------------------------------------*/
	
		BNE.S	notcont
		MOVEQ	#E_UNEXP_CONT,d0
		BRA.W	exit
		
notcont:	CMPI.B	#6,d0
		BCS.S	bitmasking
		MOVEQ	#E_INVALID_BYTE,d0
		BRA.W	exit
				
/*----------------------------------------------------------------------------
  Now bitmask is created to extract codepoint most significant bits. The first
  byte introducing 'n' following continuation bytes carries 6 - 'n' bits of
  decoded codepoint. Mask is created by shifting 1 value 'n' bits left and
  subtracting 1. These bits are always right-aligned, so 68020 optimization
  using BFINS is not feasible, because both bitfield offset and width would
  have to be calculated, also extracted bitfield needs not to be shifted.
----------------------------------------------------------------------------*/
		
bitmasking:	MOVE.W	d0,d3
		MOVEQ	#1,d1
		NEG.L	d0
		ADDQ.L	#6,d0
		LSL.L	d0,d1
		SUBQ.L	#1,d1
		AND.L	d1,d2				

/*----------------------------------------------------------------------------
  Bit extraction from continuation byte 1. If byte 1 is the last one,
  codepoint is rejected as overlong if it is less than $80.
----------------------------------------------------------------------------*/

		BSR.W	contextract
		BEQ.S	cont1over
		MOVEQ	#E_CONT_MISS,d0
		BRA.W	exit
		
cont1over:	SUBQ.B	#1,d3
		BNE.S	contbyte2
		CMPI.W	#0x0080,d2
		BCS.S	overlong
		MOVE.L	d2,d0
		BRA.S	exit
		
/*----------------------------------------------------------------------------
  Bit extraction from continuation byte 2. If byte 2 is the last one,
  codepoint is rejected as overlong if it is less than $800. Also UTF-16
  surrogates range ($D800-$DFFF) is rejected.
----------------------------------------------------------------------------*/

contbyte2:	BSR.S	contextract
		BEQ.S	cont2over
		MOVEQ	#E_CONT_MISS,d0
		BRA.S	exit

cont2over:	SUBQ.B	#1,d3
		BNE.S	contbyte3
		CMPI.W	#0x0800,d2
		BCS.S	overlong
		
		MOVE.W	d2,d0
		ANDI.W	#0xF800,d0
		CMPI.W	#0xD800,d0
		BEQ.S	surrogate
		MOVE.L	d2,d0
		BRA.S	exit
		
surrogate:	MOVEQ	#E_SURROGATE,d0
		BRA.S	exit

/*----------------------------------------------------------------------------
  Bit extraction from continuation byte 3. If byte 3 is the last one,
  codepoint is rejected as overlong if it is less than $10000. Code is
  rejected as out of range if it is $110000 or more.
----------------------------------------------------------------------------*/

contbyte3:	BSR.S	contextract
		BEQ.S	cont3over
		MOVEQ	#E_CONT_MISS,d0
		BRA.S	exit

cont3over:	SUBQ.B	#1,d3
		BNE.S	contbyte4
		CMPI.L	#0x00010000,d2
		BCS.S	overlong
		CMPI.L	#0x00110000,d2
		BCS.S	inrange
		MOVEQ	#E_OUT_OF_RANGE,d0
		BRA.S	exit
		
inrange:	MOVE.L	d2,d0
		BRA.S	exit	

/*----------------------------------------------------------------------------
  Bit extraction from continuation byte 4. It is considered overlong if less
  than $110000, out of range otherwise.
----------------------------------------------------------------------------*/

contbyte4:	BSR.S	contextract
		BEQ.S	cont4over
		MOVEQ	#E_CONT_MISS,d0
		BRA.S	exit
		
cont4over:	SUBQ.B	#1,d3
		BNE.S	contbyte5
		CMPI.L	#0x00110000,d2
		BCS.S	overlong
		MOVEQ	#E_OUT_OF_RANGE,d0
		BRA.S	exit

/*----------------------------------------------------------------------------
  Bit extraction from continuation byte 5. It is considered overlong if less
  than $110000, out of range otherwise.
----------------------------------------------------------------------------*/

contbyte5:	BSR.S	contextract
		BEQ.S	cont5over
		MOVEQ	#E_CONT_MISS,d0
		BRA.S	exit
		
cont5over:	CMPI.L	#0x00110000,d2
		BCS.S	overlong
		MOVEQ	#E_OUT_OF_RANGE,d0
				
exit:		MOVEM.L	(sp)+,d2-d4
		RTS

overlong:	MOVEQ	#E_OVERLONG,d0
		BRA.S	exit		

/*----------------------------------------------------------------------------
  Bit extraction subroutine from continuation byte.
  - Byte is loaded from memory.
  - Byte is checked that it starts from '10' bits, if not, error is set in D0.
  - D2 is moved left by 6 bits to make place for bits from continuation byte.
  - Bits from the byte are inserted into D2.
----------------------------------------------------------------------------*/

contextract:	MOVE.B	(a0)+,d1
		SPL	d0
		BTST	#6,d1
		SNE	d0
		LSL.L	#6,d2
		
		.if CPU == 68020
		
		BFINS	d1,d2{26:6}
		
		.else
		
		ANDI.B	#0x3F,d1
		OR.B	d1,d2
		
		.endif
		
		TST.B	d0
		RTS
