#include <stdint.h>

#include "video.h"
#include "debug.h"


extern uint32_t __bss_start__, __bss_end__;

#if 0

static void BssClear(void)
{
	uint32_t *bss = &__bss_start__;

	while (bss < &__bss_end__) *bss++ = 0;
}

#endif

void Main(void)
{
	uint32_t i;

	kputs("Main() reached.\r\n");

	while (1);
}
