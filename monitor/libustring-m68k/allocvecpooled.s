/****** AllocVecPooled *******************************************************
* NAME
*   AllocVecPooled -- allocates memory block from a pool and remembers size
* SYNOPSIS
*   block = AllocVecPooled(pool, size)
*   D0                     A0    D0
*
*   APTR AllocVecPooled(APTR, ULONG);
* FUNCTION
*   Allocates a block of memory of specified size from given memory pool.
*   Stores block size, so the block can be later freed using FreeVecPooled.
*   Alternatively block will be freed when the pool is deleted.
* INPUTS
*   pool - valid memory pool handle, is not tested against NULL
*   size - block size, not tested against 0
* RESULT
*   Block address to be used by application, or NULL if allocation failed.
* NOTES
*   Requires external _SysBase symbol.
* SEE ALSO
*   FreeVecPooled
*
*****************************************************************************/

		.global	_AllocVecPooled
		.xref	_SysBase
			
AllocPooled 	= -708

_AllocVecPooled:
		MOVEM.L	d2/a6,-(sp)
		ADDQ.L	#4,d0
		MOVE.L	d0,d2
		MOVEA.L	_SysBase,a6
		JSR	AllocPooled(a6)
		TST.L	d0
		BEQ.S	nomemory
		MOVEA.L	d0,a0
		MOVE.L	d2,(a0)+
		MOVE.L	a0,d0
nomemory:	MOVEM.L	(sp)+,d2/a6
		RTS
