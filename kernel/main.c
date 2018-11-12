#include <stdint.h>


extern uint32_t __bss_start__, __bss_end__;

asm ("	.section .startup	\n"
"	.globl	_start		\n"
"	.type	_start,%function\n"
"_start:			\n"
"	ldr	sp,=_start	\n"
"	bl	BssClear	\n"
"	bl	SetupCPU	\n"
"	bl	Main		\n"
"1:	b	1b		\n"
"	.text			\n"
"	.byte 0			\n"
"	.string \"$VER: SeaPiggy12 1.0 (" __DATE__ ")\"\n"
);


void BssClear(void)
{
	uint32_t *bss = &__bss_start__;

	while (bss < &__bss_end__) *bss++ = 0;
}

void SetupCPU(void)
{
	uint32_t tmp;

	/* Enable caches and branch prediction. Enable unaligned accesses */
	asm volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(tmp));
	tmp |= (1 << 2) | (1 << 12) | (1 << 11); // D-Cache, I-Cache, Branch prediction, in that order
	tmp = (tmp | (1 << 22)) & ~(1 << 1);     // Unaligned loads and stores enabled, Strict alignment disabled
	asm volatile("mcr p15, 0, %0, c1, c0, 0" ::"r"(tmp));
	
	/* 
	   Enable cp10 an cp11 coprocessors. These are VFP Single (cp10) and 
	   double (cp11) precision
	*/
	asm volatile("mrc p15, 0, %0, c1, c0, 2" : "=r"(tmp)); /* Coprocessor access register */
	tmp |= (3 << 20) | (3 << 22); // Full access to cp10 and cp11
	asm volatile("mcr p15, 0, %0, c1, c0, 2" ::"r"(tmp));
	/* 
	    VFP coprocessors enabled. Now set the EN bit of FPEXC register in order
	    to allow VFP instructions
	*/
	tmp = (1 << 30); // The EN bit
	asm volatile("fmxr fpexc, %0"::"r"(tmp));
}

void Main(void)
{
	while (1);
}
