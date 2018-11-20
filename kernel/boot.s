				.section ".text"

				.xdef	_start
				.xref	Main


_start:			LDR		r1,=_start
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
				BL		MiniUart
				BL		Main
infinity:
				B		infinity

/*=================================================*/

/* Mini UART initialization */

GPIO_BASE		= 0x20200000
AUX_BASE		= 0x20215000

GPPUD			= 0x94    /* pull-up/down control */
GPPUDCLK0		= 0x98    /* pull-up/down apply */
GPFSEL1			= 0x04    /* alternative function select */

AUXENB			= 0x04
AUXMUIO			= 0x40    /* UART data */
AUXMUIER		= 0x48
AUXMULSR		= 0x54
AUXMULCR		= 0x4C
AUXMUCNTL		= 0x60
AUXMUBAUD		= 0x68

MiniUart:

/* Remove possible pull-up/down from GPIO14 pin. */

				MOV		r3,lr
				MOV		r2,#0
				LDR		r1,=GPIO_BASE
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
				STR		r2,[r1,#GPPUD]          /* no pull-up, no pull-down */
				BL		Wait200
				MOV		r2,#0x00004000          /* bit 14 */
				STR		r2,[r1,#GPPUDCLK0]
				BL		Wait200
				MOV		r2,#0
				STR		r2,[r1,#GPPUDCLK0]
				STR		r2,[r1,#GPPUD]

/* Set alternative function 5 for GPIO14 (miniUART TxD). */

				LDR		r2,[r1,#GPFSEL1]        /* currently selected functions */
				BIC		r2,r2,#0x00007000       /* clear 14:12 field for GPIO14 */
				ORR		r2,r2,#0x00002000       /* set 14:12 to 010 = alt func 5 */
				STR		r2,[r1,#GPFSEL1]

/* Enable mini UART. */

				LDR		r1,=AUX_BASE
				MOV		r2,#1
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
				STR		r2,[r1,#AUXENB]

/* Clear RX and TX FIFO buffers. */

				MOV		r2,#0
				STR		r2,[r1,#AUXMUIER]

/* Disable receiver and transmitter. */

				STR		r2,[r1,#AUXMUCNTL]

/* Set baudrate to about 115200 bps. */

				LDR		r2,=270
				STR		r2,[r1,#AUXMUBAUD]

/* Set 8 data bits. */

				MOV		r2,#3
				STR		r2,[r1,#AUXMULCR]

/* Enable transmitter (only). */

				MOV		r2,#2
				STR		r2,[r1,#AUXMUCNTL]
				BX		r3


/*------------------------------------------------------*/
/* Wait200() - repeats NOP 200 times to create a delay. */
/*------------------------------------------------------*/

Wait200:		MOV		r0,#200
.L1:			NOP
				ADDS	r0,#-1
				BNE		.L1
				BX		lr


/*-----------------------------------------------------*/
/* kputs() - sends zero terminated string to mini UART */
/* r0 = zero terminated string to send                 */
/*-----------------------------------------------------*/

				.xdef	kputs
				.type	kputs,%function

kputs:			LDR		r3,=AUX_BASE
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
				LDRB	r1,[r0],#1
				CMP		r1,#0
				BXEQ	lr
.L2:			LDR		r2,[r3,#AUXMULSR]
				ANDS	r2,r2,#32               /* bit 5 clear = FIFO full */
				BEQ		.L2
				STR		r1,[r3,#AUXMUIO]		/* write byte to FIFO */
				B		kputs

/*--------------------------------------------------------*/
/* ktime() - reads 64-bit VideoCore free running counter. */
/*--------------------------------------------------------*/

VCTIMER_BASE	= 0x20003000
VCTIMLO			= 0x04
VCTIMHI			= 0x08

				.xdef ktime
				.type ktime,%function

ktime:			LDR		r3,=VCTIMER_BASE
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
.L3:			LDR		r2,[r3,#VCTIMLO]
				LDR		r1,[r3,#VCTIMHI]
				LDR		r0,[r3,#VCTIMLO]
				CMP		r2,r0
				BCS		.L3
				BX		lr

