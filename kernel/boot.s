				.section ".text"

				.xdef	_start
				.xref	Main
				.globl _start
_start:
				LDR		r1,=_start
				MOV		sp,r1
/*
				LDR		r1,=__bss_start
				LDR		r2,=__bss_size
				CBZ		r2,bss_cleared
clearing:
				STR		r0,[r1],#4
				SUB		r2,r2,#1
				CBNZ	r2,clearing
bss_cleared:
*/
				BL		Main
infinity:
				B		infinity

