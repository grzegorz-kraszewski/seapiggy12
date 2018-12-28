/****** CloneMem *************************************************************
* NAME
*   CloneMem -- creates a copy of memory block with contents
* SYNOPSIS
*   block = CloneMem(source, size)
*   D0               A0      D0
*
*   APTR CloneMem(const APTR, ULONG);
* FUNCTION
*   Creates a copy of given memory block in a newly allocated memory area.
*   Memory is allocated with exec.library/AllocVec() function, so it should
*   be later freed with exec.library/FreeVec(). Memory is allocated with
*   MEMF_ANY flag. Data copying is performed with exec.library/CopyMem().
* INPUTS
*   source - pointer to the source block
*   size - block size in bytes
* RESULT
*   Pointer to a newly created copy, or NULL if memory allocation failed.
* NOTES
*   Depends on external _SysBase symbol.
* SEE ALSO
*   CloneMemPooled
*
*****************************************************************************/

		.global	_CloneMem
			
		.xref	_SysBase
			
CopyMem		= -624 
AllocVec	= -684
MEMF_ANY	= 0
						
_CloneMem:	
		MOVEM.L	d2/a2/a6,-(sp)
		MOVE.L	d0,d2              
		MOVEA.L	a0,a2
		MOVEA.L	_SysBase,a6
		MOVEQ	#MEMF_ANY,d1
		JSR	AllocVec(a6)

		TST.L	d0
		BEQ.S	nomemory
		MOVEA.L	d0,a1
		MOVEA.L	a2,a0
		EXG	d2,d0			
		JSR	CopyMem(a6)

		MOVE.L	d2,d0
nomemory:	MOVEM.L	(sp)+,d2/a2/a6
		RTS	
