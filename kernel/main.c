#include <stdint.h>

#include "vccomm.h"
#include "memory.h"
#include "debug.h"

volatile uint32_t Fifo;
volatile uint32_t b[16];


extern uint32_t __bss_start__, __bss_end__;

#if 0

static void BssClear(void)
{
	uint32_t *bss = &__bss_start__;

	while (bss < &__bss_end__) *bss++ = 0;
}

#endif

/*----------------------------------------------------------------------------*/

static void AllocatorSetup(void)
{
	uint8_t *low_mem, *high_mem;
	struct ArmMemory mem;

	GetArmMemory(&mem);
	low_mem = (uint8_t*)&__bss_end__;
	high_mem = (uint8_t*)mem.BlockStart + mem.BlockSize;
	kputs("Initial free memory block from $");
	khex32((uint32_t)low_mem);
	kputs(" to $");
	khex32((uint32_t)(high_mem - 1));
	kputs(", $");
	khex32((uint32_t)(high_mem - low_mem));
	kputs(" bytes.\r\n");
	StartAllocator(low_mem, high_mem - low_mem);	
}

/*----------------------------------------------------------------------------*/


void Main(void)
{
	AllocatorSetup();
}
