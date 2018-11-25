/*-------------------*/
/* SeaPiggy 12 boot. */
/*-------------------*/

GPIO_BASE		= 0x20200000

GPFSEL0			= 0x00    /* alternative function select for GPIO 0-9 */
GPFSEL1			= 0x04    /* alternative function select for GPIO 10-19 */
GPSET0			= 0x1C    /* setting pins high */
GPCLR0			= 0x28    /* setting pins low */
GPEDS0			= 0x40    /* event detect status register for GPIO 0-31 */
GPAFEN0			= 0x88    /* asynchronous falling edge detector for GPIO 0-31 */
GPPUD			= 0x94    /* pull-up/down control */
GPPUDCLK0		= 0x98    /* pull-up/down apply */

INT_BASE		= 0x2000B200

INTFIQ			= 0x0C    /* FIQ enable and source select */


				.section ".text"

				.xdef	_start
				.xref	Main

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

				MOV		r8,#0x20000000
				ORR		r8,#0x00200000			/* GPIO base */
				MOV		r9,#0x40                /* pin 6 */
				STR		r9,[r8,#GPSET0]			/* goes high */
				MOV		r9,#0x20
				STR		r9,[r8,#GPEDS0]         /* clear interrupt on pin 5 */
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

				/* test, set pin 6 high */

				LDR		r0,=GPIO_BASE
				MOV		r1,#0x40
				STR		r1,[r0,#GPSET0]

				BL		Pins
				BL		MiniUart

				/* test, set pin 6 high, low, high */

				LDR		r0,=GPIO_BASE
				MOV		r1,#0x40
				STR		r1,[r0,#GPSET0]
				STR		r1,[r0,#GPCLR0]
				STR		r1,[r0,#GPSET0]

				BL		SetFiq

				/* test, set pin 6 low, it triggers FIQ, which sets it back high */

				LDR		r0,=GPIO_BASE
				MOV		r1,#0x40
				STR		r1,[r0,#GPCLR0]

				BL		Main
infinity:
				B		infinity

/*=================================================*/


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


/*--------------------------------------------*/
/* Pins() - initialization of used GPIO pins. */
/*--------------------------------------------*/

Pins:			MOV		r3,lr
				LDR		r1,=GPIO_BASE
				MOV		r2,#0
				MCR		p15,#0,r2,c7,c10,#5     /* memory barrier before accessing a peripherial */
				STR		r2,[r1,#GPPUD]          /* no pull-up, no pull-down */
				BL		Wait200
				MOV		r2,#0x00000060          /* GPIO 5 and 6 */
				STR		r2,[r1,#GPPUDCLK0]
				BL		Wait200
				MOV		r2,#0
				STR		r2,[r1,#GPPUDCLK0]

/* Set GPIO 5 as input and GPIO 6 as output. */

				LDR		r2,[r1,#GPFSEL0]        /* currently selected functions */
				BIC		r2,r2,#0x001C0000       /* clear 20:18 field for GPIO6 */
				ORR		r2,r2,#0x00040000       /* set 20:18 to 001 = output */
				BIC		r2,r2,#0x00038000       /* clear 17:15 field for GPIO5, 000 = input, no ORR needed */
				STR		r2,[r1,#GPFSEL0]

				/* tests, set pull-up on pin 5 */

				MOV		r2,#2                   /* pull-up */
				STR		r2,[r1,#GPPUD]						
				BL		Wait200
				MOV		r2,#0x00000020          /* GPIO 5 */
				STR		r2,[r1,#GPPUDCLK0]
				BL		Wait200
				MOV		r2,#0
				STR		r2,[r1,#GPPUDCLK0]

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
/* 1. Sets falling detection circuit on GPIO5. */
/* 2. Sets this detection as FIQ source.       */
/* 3. Enables FIQ.                             */ 
/*---------------------------------------------*/

SetFiq:			MOV		r0,#0x20                /* GPIO 5 */
				LDR		r1,=GPIO_BASE
				STR		r0,[r1,#GPAFEN0]        /* enable falling edge async detector */

				MOV		r0,#0xB1                /* FIQ enable + source 49 (GPIO_INT0) */
				LDR		r1,=INT_BASE
				STR		r0,[r1,#INTFIQ]

				MRS		r0,cpsr
				ORR		r0,#0x80				/* disable IRQ */
				BIC		r0,#0x40				/* enable FIQ */
				MSR		cpsr,r0

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
