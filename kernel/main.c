#include <stdint.h>


extern uint32_t *__bss_start__, *__bss_end__;


static void BssClear(void)
{
	uint32_t *bss = __bss_start__;

	while (bss < __bss_end__) *bss++ = 0;
}


void Main(void)
{
	uint32_t tmp;
	BssClear();
	
	/* Enable caches and branch prediction. Enable unaligned accesses */
	asm volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(tmp));
	tmp |= (1 << 2) | (1 << 12) | (1 << 11); // D-Cache, I-Cache, Branch prediction, in that order
	tmp = (tmp | (1 << 22)) & ~(1 << 1);     // Unaligned loads and stores enabled, Strict alignment disabled
	asm volatile("mcr p15, 0, %0, c1, c0, 0" ::"r"(tmp));
	
	
	
	while (1);
}
