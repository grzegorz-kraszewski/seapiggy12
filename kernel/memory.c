/*------------------------------*/
/* SeaPiggy12                   */ 
/* TLSF based memory allocator. */
/* RastPort 2018                */
/*------------------------------*/

#include <stdint.h>

#define clz(x) __builtin_clz((x))
#define ctz(x) __builtin_ctz((x))

/*
Base TLSF structure placed at start of free memory block:

  0: main logarithmic bitmap. 4 lowest bits unused (minimal block is 2^4 bytes).
     Bits 31, 30, 29 also unused (we have up to 448 MB).
  4: pointer to first block, class 28, range 3
  8: pointer to first block, class 28, range 2
 12: pointer to first block, class 28, range 1
 16: pointer to first block, class 28, range 0
 20: pointer to first block, class 27, range 3
 ...
400: pointer to first block, class 4, range 0

Total size: 404 bytes.

The lowest bit of each pointer indicates if there are free blocks in this range.
'1' means no free blocks. '0' means at least one free block. If the rest of the
pointer is NULL, there are no blocks in the range (either free or busy).
*/

#define NULL 0
#define NO_FREE_BLOCKS 1

#define BLOCK_BUSY 2
#define LAST_IN_POOL 1
#define FLAG_MASK (BLOCK_BUSY | LAST_IN_POOL)


static struct MemRoot *Allocator;


struct MemRoot
{
	uint32_t LogBitMap;
	struct BusyHeader* Pointers[100];
};

struct FreeHeader
{
	uint32_t Size;                      /* bit 1 = free/busy, bit 0 = last in pool */
	struct BusyHeader* PrevPhysical;
	struct FreeHeader* NextFree;        /* in given range */
	struct FreeHeader* PrevFree;        /* in given range */
};

struct BusyHeader
{
	uint32_t Size;
	struct BusyHeader* PrevPhysical;
};


/****i* memory/GetRange ******************************************************
* 
* NAME
*   GetRange -- gets range pointer to list of blocks for given size
*
* SYNOPSIS
*   first_block = GetRange(size)
*   struct BusyHeader** GetRange(uint32_t);
*
* FUNCTION
*   Calculates logarithmic class and linear range from the size. Returns
*   address of range pointer from the array in memory root.
*
* INPUTS
*   size - size of the free block
*
* OUTPUT
*   Address of the range pointer. NULL for zero size. Returns class C(4)
*   range 0 (blocks of 16-19 bytes) for sizes < 16 bytes. NULL is also
*   returned for sizes >= 536 870 912 bytes.
*
*****************************************************************************
*/

static struct BusyHeader** GetRange(uint32_t size)
{
	int logclass;

	if (size)
	{
		logclass = clz(size);

		if (logclass < 3)                              /* rejects sizes >= 512 MB */
		{
			if (logclass > 27) logclass = 27;          /* smallest class for sizes < 16 B */
		} 
	}

	return NULL;
}


/****** memory/StartAllocator ************************************************
* 
* NAME
*   StartAllocator -- initializes memory allocator
*
* SYNOPSIS
*   StartAllocator(lowmem, size)
*                  r0      r1
*
*   void StartAllocator(void*, uint32_t);
*
* FUNCTION
*   Reserves space for TLFS root structure and initializes it. Creates a free
*   block from the rest of memory and inserts it into the root.
*
* INPUTS
*   lowmem - start of free memory area, alignment: 4 bytes
*   size - size of the free block in bytes, alignment: 4 bytes
*
* OUTPUT
*   None.
*
*****************************************************************************
*/

void StartAllocator(void *lowmem, uint32_t size)
{
	struct MemRoot *root;
	struct FreeHeader *main;
	int i;

	/* Prepare empty MemRoot. */

	root = (struct MemRoot*)lowmem;
	size -= sizeof(struct MemRoot);
	lowmem += sizeof(struct MemRoot);
	root->LogBitMap = 0;
	for (i = 0; i < 100; i++) root->Pointers[i] = (struct BusyHeader*)NO_FREE_BLOCKS;
	Allocator = root;

	/* Prepare header of the first block. */

	main = (struct FreeHeader*)lowmem;
	main->Size = size | LAST_IN_POOL;
	main->PrevPhysical = NULL;
	main->NextFree = NULL;
	main->PrevFree = NULL;

	/* now insert the block to allocator root */

	//InsertFreeBlock(main, size);
}
