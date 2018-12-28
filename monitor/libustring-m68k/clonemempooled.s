/****** CloneMemPooled *******************************************************
* NAME
*   CloneMemPooled -- clones memory block in a memory pool
*
* SYNOPSIS
*   block = CloneMemPooled(pool, source, size)
*   D0                     A0    A1      D0
*
*   APTR CloneMemPooled(const APTR, ULONG);
* FUNCTION
*   Creates a copy of given memory block in a newly allocated memory from
*   given pool. Memory is allocated with AllocVecPooled function, so it should
*   be later freed with FreeVecPooled. Data copying is performed with
*   exec.library/CopyMem().
* INPUTS
*   pool - memory pool handle
*   source - pointer to the source block
*   size - block size in bytes
* RESULT
*   Pointer to a newly created copy, or NULL if memory allocation failed.
* NOTES
*   Depends on external _SysBase symbol.
*   Functon does not perform any sanity checks on arguments.
* SEE ALSO
*   AllocVecPooled, FreeVecPooled, CloneMem
*
*****************************************************************************/

		.global	_CloneMemPooled

		.xref	_SysBase
		.xref	_AllocVecPooled

CopyMem		=	-624 
MEMF_ANY	=	0

_CloneMemPooled:	
		MOVEM.L d2/a2/a6,-(sp)
		MOVE.L	d0,d2
		MOVEA.L	a1,a2
		BSR.S	_AllocVecPooled
		TST.L	d0
		BEQ.S	nomemory
		MOVEA.L	a2,a0
		MOVEA.L	d0,a1
		MOVEA.L	_SysBase,a6
		EXG	d2,d0
		JSR	CopyMem(a6)
		MOVE.L	d2,d0
nomemory:	MOVEM.L	(sp)+,d2/a2/a6
		RTS			
