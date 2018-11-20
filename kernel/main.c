#include <stdint.h>

#include "video.h"


extern uint32_t __bss_start__, __bss_end__;


static void BssClear(void)
{
	uint32_t *bss = &__bss_start__;

	while (bss < &__bss_end__) *bss++ = 0;
}


void Main(void)
{
	BssClear();
	
	/* 
	   Enable cp10 an cp11 coprocessors. These are VFP Single (cp10) and 
	   double (cp11) precision
	*/

/*
	asm volatile("mrc p15, 0, %0, c1, c0, 2" : "=r"(tmp));
	tmp |= (3 << 20) | (3 << 22); // Full access to cp10 and cp11
	asm volatile("mcr p15, 0, %0, c1, c0, 2" ::"r"(tmp));
*/
	/* 
	    VFP coprocessors enabled. Now set the EN bit of FPEXC register in order
	    to allow VFP instructions
	*/
/*
	tmp = (1 << 30); // The EN bit
	asm volatile("fmxr fpexc, %0"::"r"(tmp));
*/	
	SetVideoMode(640, 512);	
	while (1);
}
