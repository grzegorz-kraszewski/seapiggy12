/*-------------------*/
/* SeaPiggy 12 boot. */
/*-------------------*/

/* GPIO assignments

GPIO  function  pull  description
---------------------------------
  0    unused   def.  reserved 
  1    unused   def.  reserved
  2     input   none  IORD from Amiga
  3     input   none  SPARE_CS from Amiga, triggers FIQ
  4     input   none  A2 from Amiga
  5    unused   def.  unused
  6     input   none  D16 (D0) from Amiga
  7     input   none  D17 (D1) from Amiga 
  8     input   none  D18 (D2) from Amiga
  9     input   none  D19 (D3) from Amiga
 10     input   none  D20 (D4) from Amiga
 11     input   none  D21 (D5) from Amiga
 12     input   none  D22 (D6) from Amiga
 13     input   none  D23 (D7) from Amiga
 14      UART   def.  TxD for debug
 15     input   none  A3 from Amiga
 16    output   none  D16 (D0) to Amiga
 17    output   none  D17 (D1) to Amiga
 18    output   none  D18 (D2) to Amiga
 19    output   none  D19 (D3) to Amiga
 20    output   none  D20 (D4) to Amiga
 21    output   none  D21 (D5) to Amiga
 22    output   none  D22 (D6) to Amiga
 23    output   none  D23 (D7) to Amiga
 24    output   down  INT6 to Amiga
 25    unused   def.  NC
 26    unused   def.  NC
 27    unused   def.  NC
 28    unused   def.  NC
 29    unused   def.  NC
 30    unused   def.  NC
 31    unused   def.  NC
*/

GPIO_BASE		= 0x20200000

GPFSEL0			= 0x00    /* alternative function select for GPIO 0-9 */
GPFSEL1			= 0x04    /* alternative function select for GPIO 10-19 */
GPFSEL2			= 0x08    /* alternative function select for GPIO 20-29 */
GPSET0			= 0x1C    /* setting output pins high */
GPCLR0			= 0x28    /* setting output pins low */
GPLEV0			= 0x34    /* pin input levels */
GPEDS0			= 0x40    /* event detect status register for GPIO 0-31 */
GPFEN0			= 0x58
GPAFEN0			= 0x88    /* asynchronous falling edge detector for GPIO 0-31 */
GPPUD			= 0x94    /* pull-up/down control */
GPPUDCLK0		= 0x98    /* pull-up/down apply */

INT_BASE		= 0x2000B200

INTFIQ			= 0x0C    /* FIQ enable and source select */


				.section ".text"

				.xdef	_start
				.xref	Main
				.xref	Fifo

_start:			B		start                   /* jump over the interrupts table */

/*---------------------------------*/
/* Interrupt vectors and FIQ code. */
/*---------------------------------*/

intvec:			B		0x8004 + _start;        /* reset */
				B		0x8004 + infinity       /* undefined instruction */
				B		0x8004 + infinity       /* SWI */
				B		0x8004 + infinity		/* prefetch abort */
				B		0x8004 + infinity		/* data abort */
				B		0x8004 + infinity		/* reserved */
				B		0x8004 + infinity		/* IRQ */

				/* FIQ is the last vector, so handler can be placed just here. */
				/* FIQ banked registers layout (preloaded in SetFiq()):        */
				/* r8 = GPIO base (0x20200000)                                 */
				/* r9 = write pointer to FIFO                                  */

				MOV		r10,#0x08
				STR		r10,[r8,#GPEDS0]         /* clear interrupt on pin 3 */
				LDR		r10,[r8,#GPLEV0]
				MOV		r10,r10,LSR #6
				STRB	r10,[r9],#1
				SUBS	pc,lr,#4

/*---------------------------------*/

start:			LDR		r1,=_start
				MOV		sp,r1                   /* stack setup */

				MRC		p15,#0,r0,c1,c0,#0      /* processor setup */
				ORR		r0,r0,#0x00001000       /* L1 I-Cache on */
				ORR		r0,r0,#0x00000004       /* L1 D-Cache on */
				ORR		r0,r0,#0x00000800       /* branch prediction on */
				ORR		r0,r0,#0x00000002       /* strict alignment exception on */
				BIC		r0,r0,#0x00400000       /* disable unaligned access */
				MCR		p15,#0,r0,c1,c0,#0

				/* copy interrupt vectors to $00000000 */

				.set	intcode_len, (start - intvec) >> 2

				MOV		r0,#0                   /* destination */
				LDR		r1,=intvec              /* source */
				MOV		r2,#intcode_len         /* word counter */
intcopy:		LDR		r3,[r1],#4
				STR		r3,[r0],#4
				SUBS	r2,#1
				BNE		intcopy

				BL		Pins
				BL		MiniUart
				BL		SetFiq
				BL		Main
infinity:
				B		infinity

/*=================================================*/

/*--------------------------*/
/* Mini UART initialization */
/*--------------------------*/

AUX_BASE		= 0x20215000

AUXENB			= 0x04
AUXMUIO			= 0x40    /* UART data */
AUXMUIER		= 0x48
AUXMULSR		= 0x54
AUXMULCR		= 0x4C
AUXMUCNTL		= 0x60
AUXMUBAUD		= 0x68

MiniUart:
				/* Enable mini UART. Pin 14 function is already set in Pins(). */

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
				BX		lr


/*--------------------------------------------*/
/* Pins() - initialization of used GPIO pins. */
/*--------------------------------------------*/

Pins:			MOV		r3,lr
				LDR		r1,=GPIO_BASE
				MOV		r2,#0
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */

				/* pull-up and pull-down config */

				STR		r2,[r1,#GPPUD]          /* no pull-up, no pull-down */
				BL		Wait200
				LDR		r2,=0x00FFFFDC			/* GPIO 23-6, 4-2 */
				STR		r2,[r1,#GPPUDCLK0]
				BL		Wait200
				MOV		r2,#0
				STR		r2,[r1,#GPPUDCLK0]

				/* Set functions for pins 0 - 9 */

				LDR		r2,[r1,#GPFSEL0]        /* currently selected functions */
				BIC		r2,r2,#0x3F000000       /* GPIO 9,8,7,6,4,3,2 = inputs */
				BIC		r2,r2,#0x00FC0000       /* GPIO 5,0,1 = not modified */
				BIC		r2,r2,#0x00007F00
				BIC		r2,r2,#0x000000C0
				STR		r2,[r1,#GPFSEL0]

				/* Set functions for pins 10 - 19 */

				LDR		r2,[r1,#GPFSEL1]        /* currently selected functions */
				BIC		r2,r2,#0x3F000000       /* GPIO 19,18,17,16 = outputs */
				BIC		r2,r2,#0x00FF0000       /* GPIO 15,13,12,11,10 = inputs */
				BIC		r2,r2,#0x0000FF00       /* GPIO 14 = alt5 (mini UART TxD) */
				BIC		r2,r2,#0x000000FF
				ORR		r2,r2,#0x09000000
				ORR		r2,r2,#0x00240000
				ORR		r2,r2,#0x00002000
				STR		r2,[r1,#GPFSEL1]

				/* Set functions for pins 20 - 29 */

				LDR		r2,[r1,#GPFSEL2]        /* currently selected functions */
				BIC		r2,r2,#0x00007F00       /* GPIO 24,23,22,21,20 = outputs */
				BIC		r2,r2,#0x000000FF
				ORR		r2,r2,#0x00001200
				BIC		r2,r2,#0x00000049
				STR		r2,[r1,#GPFSEL2]

				MOV		r0,#0x01000000
				STR		r0,[r1,#GPSET0]         /* test, set GPIO24 */

				BX		r3


/*------------------------------------------------------*/
/* Wait200() - repeats NOP 200 times to create a delay. */
/*------------------------------------------------------*/

Wait200:		MOV		r0,#200
.L1:			NOP
				ADDS	r0,#-1
				BNE		.L1
				BX		lr


/*---------------------------------------------*/
/* SetFiq()                                    */ 
/* 1. Sets falling detection circuit on GPIO3. */
/* 2. Sets this detection as FIQ source.       */
/* 3. Enables FIQ.                             */ 
/*---------------------------------------------*/

SetFiq:			MOV		r0,#0x08                /* GPIO 3 */
				LDR		r1,=GPIO_BASE
				STR		r0,[r1,#GPFEN0]         /* enable falling edge async detector */

				MOV		r0,#0xB1                /* FIQ enable + source 49 (GPIO_INT0) */
				LDR		r1,=INT_BASE
				STR		r0,[r1,#INTFIQ]

				/* preloading FIQ registers */

				CPSID	if,#17					/* disable IRQ & FIQ, enter FIQ mode */
				LDR		r8,=GPIO_BASE
				LDR		r9,=Fifo
				MOV		r11,#0
				CPSIE	f,#19					/* back to supervisor, enable FIQ */

				BX		lr


/*-----------------------------------------------------*/
/* kputs() - sends zero terminated string to mini UART */
/* r0 = zero terminated string to send                 */
/*-----------------------------------------------------*/

				.xdef	kputs
				.type	kputs,%function

kputs:			LDR		r3,=AUX_BASE
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
.L2:			LDRB	r1,[r0],#1
				CMP		r1,#0
				BXEQ	lr
.L3:			LDR		r2,[r3,#AUXMULSR]
				ANDS	r2,r2,#32               /* bit 5 clear = FIFO full */
				BEQ		.L3
				STR		r1,[r3,#AUXMUIO]		/* write byte to FIFO */
				B		.L2

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
.L4:			LDR		r2,[r3,#VCTIMLO]
				LDR		r1,[r3,#VCTIMHI]
				LDR		r0,[r3,#VCTIMLO]
				CMP		r2,r0
				BCS		.L4
				BX		lr
