/* Communication with VideoCore via mailbox interface. */

#include <stdint.h>


struct ArmMemory
{
	void* BlockStart;
	uint32_t BlockSize;
};


void GetArmMemory(struct ArmMemory *mem);
void GetPixelClock(uint32_t *clock);
