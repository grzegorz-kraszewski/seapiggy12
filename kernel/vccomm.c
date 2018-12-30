/* framebuffer setup */

#include "vccomm.h"
#include "debug.h"

#define data_synchronization_barrier() asm volatile ("mcr p15,#0,%[zero],c7,c10,#4" : : [zero] "r" (0))
#define data_memory_barrier() asm volatile ("mcr p15,#0,%[zero],c7,c10,#5" : : [zero] "r" (0))


/* status register flags */

#define MBOX_TX_FULL (1UL << 31)
#define MBOX_RX_EMPTY (1UL << 30)
#define MBOX_CHANMASK 0xF

/* VideoCore tags used. */

#define VCTAG_GET_ARM_MEMORY     0x00010005
#define VCTAG_GET_CLOCK_RATE     0x00030002

#define VCCLOCK_PIXEL            9

/*----------------------------------------------------------------------------*/

static uint32_t mbox_recv(int channel)
{
	volatile uint32_t *mbox_read = (uint32_t*)0x2000B880;
	volatile uint32_t *mbox_status = (uint32_t*)0x2000B898;
	uint32_t response, status;

	do
	{
		do
		{
			status = *mbox_status;
			data_synchronization_barrier();
		}
		while (status & MBOX_RX_EMPTY);

		data_memory_barrier();
		response = *mbox_read;
		data_memory_barrier();
	}
	while ((response & MBOX_CHANMASK) != channel);

	return (response & ~MBOX_CHANMASK);
}

/*----------------------------------------------------------------------------*/

static void mbox_send(int channel, uint32_t data)
{
	volatile uint32_t *mbox_write = (uint32_t*)0x2000B8A0;
	volatile uint32_t *mbox_status = (uint32_t*)0x2000B898;
	uint32_t status;

	data &= ~MBOX_CHANMASK;
	data |= channel & MBOX_CHANMASK;

	do
	{
		status = *mbox_status;
		data_synchronization_barrier();
	}
	while (status & MBOX_TX_FULL);

	data_memory_barrier();
	*mbox_write = data;
}


uint32_t FBReq[32] __attribute__((aligned(16)));

/*----------------------------------------------------------------------------*/

void GetArmMemory(struct ArmMemory *mem)
{
	FBReq[0] = 32;
	FBReq[1] = 0;
	FBReq[2] = VCTAG_GET_ARM_MEMORY;
	FBReq[3] = 8;
	FBReq[4] = 0;
	FBReq[5] = 0;              /* response: base address */
	FBReq[6] = 0;              /* response: byte size */
	FBReq[7] = 0;

	mbox_send(8, (uint32_t)FBReq);
	mbox_recv(8);

	mem->BlockStart = (void*)FBReq[5];
	mem->BlockSize = FBReq[6];
}

/*----------------------------------------------------------------------------*/

void GetPixelClock(uint32_t *clock)
{
	FBReq[0] = 32;
	FBReq[1] = 0;
	FBReq[2] = VCTAG_GET_CLOCK_RATE;
	FBReq[3] = 8;
	FBReq[4] = 0;
	FBReq[5] = VCCLOCK_PIXEL;
	FBReq[6] = 0;              /* response: frequency in Hz */
	FBReq[7] = 0;

	mbox_send(8, (uint32_t)FBReq);
	mbox_recv(8);

	*clock = FBReq[6];
}

/*----------------------------------------------------------------------------*/

int SetVideoMode(int width, int height)
{
	uint32_t *d;
	uint32_t *fb;
	uint32_t i;

	FBReq[0] = 88;             /* message length in bytes */
	FBReq[1] = 0;              /* message is a request */
	FBReq[2] = 0x00048003;     /* display dimensions */
	FBReq[3] = 8;              /* tag data field size */
	FBReq[4] = 0;              /* tag is a request */
	FBReq[5] = 320;            /* display width */
	FBReq[6] = 256;            /* display height */
	FBReq[7] = 0x00048004;     /* framebuffer dimensions */
	FBReq[8] = 8;              /* tag data field size */
	FBReq[9] = 0;              /* tag is a request */
	FBReq[10] = 320;           /* framebuffer width */
	FBReq[11] = 256;           /* framebuffer height */
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
	d = (uint32_t*)mbox_recv(8);

	while (*d++ != 0x00040001);

	/* framebuffer simple test to be discarded later */

	fb = (uint32_t*)(d[2] & 0x3FFFFFFF);

	for (i = 0; i < 320; i++) fb[i] = 0x00FF8080;
	for (i = 255 * 320; i < 256 * 320; i++) fb[i] = 0x00FF8080;

	return 0;
}
