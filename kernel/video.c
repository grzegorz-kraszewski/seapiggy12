/* framebuffer setup */

#include <stdint.h>

#define data_memory_barrier() asm volatile ("mcr p15,#0,%[zero],c7,c10,#5" : : [zero] "r" (0))
#define cache_flush() asm volatile ("mcr p15,#0,%[zero],c7,c14,#0" : : [zero] "r" (0))


/* status register flags */

#define MBOX_TX_FULL (1UL << 31)
#define MBOX_RX_EMPTY (1UL << 30)
#define MBOX_CHANMASK 0xF


/* mailbox 0 registers */

uint32_t mbox_recv(int channel)
{
	volatile uint32_t *mbox_read = (uint32_t*)0x20008B80;
	volatile uint32_t *mbox_status = (uint32_t*)0x20008B98;
	uint32_t response, status;

	do
	{
		do
		{
			status = *mbox_status;
		}
		while (status & MBOX_RX_EMPTY);

		response = *mbox_read;
	}
	while ((response & MBOX_CHANMASK) != channel);

	return (response & ~MBOX_CHANMASK);
}


void mbox_send(int channel, uint32_t data)
{
	volatile uint32_t *mbox_write = (uint32_t*)0x20008BA0;
	volatile uint32_t *mbox_status = (uint32_t*)0x20008B98;
	uint32_t status;

	data &= ~MBOX_CHANMASK;
	data |= channel & MBOX_CHANMASK;

	do
	{
		status = *mbox_status;
	}
	while (status & MBOX_TX_FULL);

	data_memory_barrier();
	*mbox_write = data;				
}


uint32_t FBReq[24] __attribute__((aligned(16)));


int SetVideoMode(int width, int height)
{
	FBReq[0] = 96;             /* message length in bytes */
	FBReq[1] = 0;              /* message is a request */
	FBReq[2] = 0x00048003;     /* display dimensions */
	FBReq[3] = 8;              /* tag data field size */
	FBReq[4] = 0;              /* tag is a request */
	FBReq[5] = 640;            /* display width */
	FBReq[6] = 512;            /* display height */
	FBReq[7] = 0x00048004;     /* framebuffer dimensions */
	FBReq[8] = 8;              /* tag data field size */
	FBReq[9] = 0;              /* tag is a request */
	FBReq[10] = 640;           /* framebuffer width */
	FBReq[11] = 512;           /* framebuffer height */
	FBReq[12] = 0x00048005;    /* framebufer bitdepth */
	FBReq[13] = 4;             /* tag data field size */
	FBReq[14] = 0;             /* tag is a request */
	FBReq[15] = 32;            /* bitdepth */
	FBReq[16] = 0x00040001;    /* allocate framebuffer */
	FBReq[17] = 8;             /* tag data field size */
	FBReq[18] = 0;             /* request */
	FBReq[19] = 16;            /* framebuffer alignmnent */
	FBReq[20] = 0;             /* place for fb address */
	FBReq[21] = 0;             /* endtag */
	
	mbox_send(8, (uint32_t)FBReq);
	return 0;
}
