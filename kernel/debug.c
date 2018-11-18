/* debug functions */

#include "debug.h"

/*-------------------------------------------------------*/
/* khex32() - prints 32-bit value as hexadecimal string. */
/*-------------------------------------------------------*/

void khex32(uint32_t x)
{
	char t[9];
	int i, y;

	for (i = 7; i >= 0; i--)
	{
		y = (x & 0xF) + 48;
		if (y > 57) y += 7;
		t[i] = y;
		x >>= 4;
	}

	t[8] = 0x00;
	kputs(t);	
}


/*-------------------------------------------------------*/
/* khex64() - prints 64-bit value as hexadecimal string. */
/*-------------------------------------------------------*/

void khex64(uint64_t x)
{
	char t[17];
	int i, y;

	for (i = 15; i >= 0; i--)
	{
		y = (x & 0xF) + 48;
		if (y > 57) y += 7;
		t[i] = y;
		x >>= 4;
	}

	t[16] = 0x00;
	kputs(t);	
}
