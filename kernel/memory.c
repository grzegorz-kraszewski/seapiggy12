/*------------------------------*/
/* SeaPiggy12                   */ 
/* TLSF based memory allocator. */
/* RastPort 2018                */
/*------------------------------*/

#include <stdint.h>
#include <stddef.h>
#include "debug.h"

#define clz(x) __builtin_clz((x))
#define ctz(x) __builtin_ctz((x))

/* probably will be moved to some global header */

#define NULL 0


/******* TODO: FreeMem() and block merging. ********/


/*
Allocator uses modified TLSF. There are 32 logarithmic ranges. As RPi Zero has
512 MB of memory, three largest ranges are unused. Also four smallest ranges
are unused, the first used range is 16 to 31 bytes. Then smallest raw block is
16 bytes, it means smallest user allocation is 8 bytes. Smaller allocations
are internally rounded up to 8. Also all the allocations are internally rounded
up to nearest multiple of 4 bytes.

This implementation uses merged bitmap of both logarithmic ranges and linear
subranges. The whole bitmap takes 4 32-bit words:

[0]:  R(7)  R(6)  R(5)  R(4)  R(3)  R(2)  R(1)  R(0)
[1]: R(15) R(14) R(13) R(12) R(11) R(10)  R(9)  R(8)
[2]: R(23) R(22) R(21) R(20) R(19) R(18) R(17) R(16) 
[3]: R(31) R(30) R(29) R(28) R(27) R(26) R(25) R(24)

Each R(n) consists of 4 bits: R(n,3) R(n,2) R(n,1) R(n,0).

In effect the whole bitmap can be seen as one 128-bit word with bits for
memory block ranges ordered from the smallest to the largest (stored in little
endian).

After the bitmap, pointers to block lists are stored, again starting from the
smallest linear subrange (R(4,0), 16 bytes blocks) to the largest. However
16 pointers for classes R(0) to R(3) are omitted, as well as 12 pointers for
ranges R(29) to R(31). Then there are 25 logarithmic classes, having 4
linear subranges each, so there are 100 pointers total.
*/

#define BLOCK_BUSY 2
#define LAST_IN_POOL 1
#define FLAGS_MASK (BLOCK_BUSY | LAST_IN_POOL)

struct Node
{
	struct Node *Next;
	struct Node *Prev;
};

struct List
{
	struct Node *Head;
	struct Node *Tail;
	struct Node *TailPred;
};

struct BusyHeader
{
	uint32_t Size;                      /* bit 1 = free/busy, bit 0 = last in pool */
	struct BusyHeader* PrevPhys;
};

struct FreeHeader
{
	struct BusyHeader Header;
	struct Node Free;                   /* in given subrange */
};

struct MemRoot
{
	uint32_t BitMap[4];
	struct List Lists[100];
};


static struct MemRoot *Allocator;


void InitList(struct List *list)
{
	list->Head = (struct Node*)&list->Tail;
	list->Tail = NULL;
	list->TailPred = (struct Node*)&list->Head;
}


int ListIsEmpty(struct List *list)
{
	return list->Head->Next == NULL;
}


struct Node* Remove(struct Node *node)
{
	node->Next->Prev = node->Prev;
	node->Prev->Next = node->Next;
	return node;
}


struct Node* RemHead(struct List *list)
{
	if (ListIsEmpty(list)) return NULL;
	else return Remove(list->Head);
}


void Insert(struct Node *after, struct Node *node)
{
	after->Next->Prev = node;
	node->Next = after->Next;
	node->Prev = after;
	after->Next = node;
}


void AddHead(struct List *list, struct Node *node)
{
	Insert((struct Node*)&list->Head, node);
}
 


/****i* memory/InsertFreeBlock ***********************************************
* 
* NAME
*   InsertFreeBlock -- Inserts initialized free block into allocator.
*
* SYNOPSIS
*   InsertFreeBlock(block)
*   void InsertFreeBlock(struct FreeHeader*);
*
* FUNCTION
*   Inserts free block of given address and size to the allocator. Block
*   header should have initialized 'Size' field (with flags) and 'PrevPhys'
*   pointer. Block range and subrange is calculated, then block is inserted as
*   the first in subrange list. Bitmap is updated.
*
* INPUTS
*   block - address of the block
*
* OUTPUT
*   None.
*
* NOTES
*   It is assumed, that raw block size is always at least 16 bytes and it is
*   less than 512 MB.
*
******************************************************************************
*/

void InsertFreeBlock(struct FreeHeader *block)
{
	struct List* list;
	uint32_t range, subrange, listindex, wordindex, bitindex, mask, size;

	size = block->Header.Size;
	range = clz(size);
	subrange = (size >> (29 - range)) & 3;
	range = 32 - range;

	/* calculate list array index for subrange */

	listindex = (range << 2) + subrange - 16;
	list = &Allocator->Lists[listindex];

	/* insert into subrange list */

	AddHead(list, &block->Free);

	/* mark subrange in bitmap as having free blocks */

	wordindex = range >> 3;
	bitindex = ((range & 7) << 2) + subrange;
	mask = 1 << bitindex;
	Allocator->BitMap[wordindex] |= mask;
}	


/****i* memory/FindFreeBlock *************************************************
* 
* NAME
*   FindFreeBlock -- Finds block big enough for requested raw size.
*
* SYNOPSIS
*   block = FindFreeBlock(size)
*   struct FreeBlock* FindFreeBlock(uint32_t);
*
* FUNCTION
*   Finds possibly best fitted block for allocation of given raw size.
*   1. Word and bit indexes are calculated from rawsize.
*   2. Bitmap mask is generated from the above indexes. The mask has '1' bits
*      for all subranges holding block big enough to satisfy the request, '0'
*      bits elsewhere.
*   3. Bitmap is masked with the mask and rightmost '1' bit is located.
*   4. This bit points to block subrange containing at least one free block.
*   5. First block from the list of the above subrange is removed from the
*      list and returned.
*   6. Block bitmap is updated if the block was last free in a given subrange.
*
* INPUTS
*   size - raw size of the block in bytes, including the header.
*
* OUTPUT
*   block - address of block or NULL if no matching block was found.
*
******************************************************************************
*/

static struct FreeHeader* FindFreeBlock(uint32_t size)
{
	uint32_t range, subrange, wordindex, bitindex, mask, bmword, listindex;

	range = clz(size);
	subrange = (size >> (29 - range)) & 3;
	range = 32 - range;
	bitindex = ((range & 7) << 2) + subrange;
	mask = 1 << bitindex;
	mask |= mask << 1;
	mask |= mask << 2;
	mask |= mask << 4;
	mask |= mask << 8;
	mask |= mask << 16;
	bitindex = 32;

	for (wordindex = range >> 3; wordindex < 4; wordindex++)
	{
		bmword = Allocator->BitMap[wordindex];
		bmword &= mask;

		if (bmword)
		{
			bitindex = ctz(bmword);
			break;
		}

		mask = ~0;
	}

	if (bitindex < 32)
	{
		struct Node *blknode;
		struct FreeHeader *block;

		listindex = (wordindex << 5) + bitindex - 16;
		blknode = RemHead(&Allocator->Lists[listindex]);
		block = (struct FreeHeader*)((uint8_t*)blknode - offsetof(struct FreeHeader, Free));
		
		return block;
	}

	return NULL;
}


/****i* memory/ClearBitOnMap *************************************************
* 
* NAME
*   ClearBitOnMap -- Clears a bit on the allocator bitmap.
*
* SYNOPSIS
*   ClearBitOnMap(subrangeptr)
*   void ClearBitOnMap(struct FreeHeader**);
*
* FUNCTION
*   Locates bit in the allocator bitmap corresponding to given address of
*   subrange pointer.
*
* INPUTS
*   subrangeptr - address of subrange pointer
*
* OUTPUT
*   None.
*
******************************************************************************
*/

void ClearBitOnMap(struct FreeHeader **subrangeptr)
{
	uint32_t bitindex, wordindex, mask;

	bitindex = subrangeptr - Allocator->Pointers + 16;  /* 16 smallest subranges omitted */
	wordindex = bitindex >> 5;
	bitindex &= 31;
	mask = 1 << bitindex;
	Allocator->BitMap[wordindex] &= ~mask;
}


/****i* memory/SplitBlock ****************************************************
* 
* NAME
*   SplitBlock -- Splits a memory block into two.
*
* SYNOPSIS
*   SplitBlock(block, size);
*   void SplitBlock(struct FreeHeader*, uint32_t);
*
* FUNCTION
*   Splits a free memory block into two parts. The first one is truncated to
*   specified size. The second one is the remainder. Free block header is
*   created in it then it is added to the allocator as free block.
*
*   If the block being splitted is physically the last one in the pool,
*   remainder block retains this property.
*
* INPUTS
*   block - block to be splitted
*   newsize - raw size of the first part, it is assumed this size is at least
*     16 bytes less than current block size
*
* OUTPUT
*   None.
*
******************************************************************************
*/

void SplitBlock(struct FreeHeader *block, uint32_t newsize)
{
	uint32_t currsize;
	uint32_t lastflag;
	struct FreeHeader *remainder;
	struct BusyHeader *nextphys;

	currsize = block->Size & ~FLAGS_MASK;
	lastflag = block->Size & LAST_IN_POOL;
	remainder = (struct FreeHeader*)((uint8_t*)block + newsize);

	if (!lastflag)
	{
		nextphys = (struct BusyHeader*)((uint8_t*)block + currsize); 
		nextphys->PrevPhys = (struct BusyHeader*)remainder;
	}

	InsertFreeBlock(remainder, currsize - newsize, (struct BusyHeader*)block, lastflag);
}



/****** memory/AllocMem ******************************************************
* 
* NAME
*   AllocMem -- Allocates memory block.
*
* SYNOPSIS
*   block = AllocMem(size)
*   void* AllocMem(uint32_t);
*
* FUNCTION
*   Allocates block of memory of requested size.
*
* INPUTS
*   size - size of the block in bytes. Sizes below 8 bytes are rounded up to
*     8, also any size is rounded up to 4 bytes multiply.
*
* OUTPUT
*   block - pointer to allocated memory. NULL if requested block cannot be
*   allocated. Allocated block is always 4-byte aligned.
*
* NOTES
*   Zero sized alloc is succesful and results in allocation of 8 bytes. Will
*   be freed as usual.
*
******************************************************************************
*/

void* AllocMem(uint32_t size)
{
	uint32_t rawsize, remainder;
	struct FreeHeader **blockptr;

	if (size < 8) size = 8;
	size = (size + 3) & ~3;
	rawsize = size + sizeof(struct BusyHeader);

	blockptr = FindFreeBlock(rawsize);

	if (blockptr)
	{
		struct FreeHeader *block, *next;

		/*--------------------------------------------*/
		/* Remove the first block from subrange list. */
		/*--------------------------------------------*/

		block = *blockptr;
		next = block->NextFree;               /* may be NULL */
		*blockptr = next;

		if (next) next->PrevFree = NULL;      /* next is now first */
		else ClearBitOnMap(blockptr);         /* this block was the last free */

		/*----------------------------------------*/
		/* Check if block needs a split. Split if */
		/* remainder would be at least 16 bytes.  */
		/*----------------------------------------*/

		remainder = (block->Size & ~FLAGS_MASK) - rawsize;
		if (remainder >= 16) SplitBlock(block, rawsize);
		
		block->Size |= BLOCK_BUSY;
		return (void*)((uint8_t*)block + sizeof(struct BusyHeader));
	}

	return NULL;
}



/* debug */

void ListBlocksPhysically(void *lowmem)
{
	struct FreeHeader *block;
	uint32_t size;

	block = (struct FreeHeader*)lowmem;

	while (block)
	{
		uint32_t clsize;

		size = block->Size;
		clsize = size & ~FLAGS_MASK;

		if (size & BLOCK_BUSY) kputs("Busy block @ $");
		else kputs("Free block @ $");

		khex32((uint32_t)block);
		kputs(", $");
		khex32(clsize);
		kputs(" bytes.\r\n");

		if (size & LAST_IN_POOL) block = NULL;
		else block = (struct FreeHeader*)((uint8_t*)block + clsize);
	}
}


int FirstInPool(struct BusyHeader *block)
{
	return (!block->PrevPhys);
}


int LastInPool(struct BusyHeader *block)
{
	return (block->Size & LAST_IN_POOL);
}


struct BusyHeader* NextPhysBlock(struct BusyHeader *block)
{
	return (struct BusyHeader*)((uint8_t*)block + (block->Size & ~FLAGS_MASK));
}


int PrevBlockFree(struct BusyHeader *block)
{
	return !(block->PrevPhys->Size & BLOCK_BUSY);
}


int NextBlockFree(struct BusyHeader *block)
{
	return !(NextPhysBlock(block)->Size & BLOCK_BUSY);
}



struct BusyHeader* MergeBack(struct BusyHeader *block)
{
	struct BusyHeader *previous;

	previous = block->PrevPhys;
	previous->Size += block->Size;   /* this also takes care of LAST_IN_POOL flag */
	return previous;
}


struct BusyHeader* MergeForward(struct BusyHeader *block)
{
	struct BusyHeader *next;

	next = NextPhysBlock(block);

	if (!LastInPool(next))
	{
		struct BusyHeader *another;

		another = NextPhysBlock(next);
		another->PrevPhys = block;
	}

	block->Size += next->Size;   /* this also takes care of LAST_IN_POOL flag */
	return block;
}


void FreeMem(void *block)
{
	struct BusyHeader *real_block;

	real_block = (struct BusyHeader*)block - 1;
	real_block->Size &= ~BLOCK_BUSY;
	if (!FirstInPool(real_block) && PrevBlockFree(real_block)) real_block = MergeBack(real_block);
	if (!LastInPool(real_block) && NextBlockFree(real_block)) real_block = MergeForward(real_block);
	//InsertFreeBlock(real_block);
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
******************************************************************************
*/

void StartAllocator(void *lowmem, uint32_t size)
{
	struct FreeHeader *block;
	struct MemRoot *root;
	int i;

	/* Prepare empty MemRoot. */

	root = (struct MemRoot*)lowmem;
	size -= sizeof(struct MemRoot);
	lowmem = (uint8_t*)lowmem + sizeof(struct MemRoot);

	root->BitMap[0] = 0;
	root->BitMap[1] = 0;
	root->BitMap[2] = 0;
	root->BitMap[3] = 0;

	for (i = 0; i < 100; i++) InitList(&Lists[i]);

	/* now insert the block to allocator root */

	block = (struct FreeHeader*)lowmem;
	block->Size = size | LAST_IN_POOL;
	block->PrevPhys = NULL;
	InsertFreeBlock(block);	
	Allocator = root;

	// debug

	ListBlocksPhysically(lowmem);
}
