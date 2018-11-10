#include <stdint.h>


extern uint32_t *__bss_start__, *__bss_end__;


static void BssClear(void)
{
	uint32_t *bss = __bss_start__;

	while (bss < __bss_end__) *bss++ = 0;
}


void Main(void)
{
	BssClear();
	while (1);
}
