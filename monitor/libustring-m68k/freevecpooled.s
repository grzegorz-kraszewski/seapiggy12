/****** FreeVecPooled ********************************************************
* NAME
*   FreeVecPooled -- frees memory block allocated with AllocVecPooled
* SYNOPSIS
*   FreeVecPooled(pool, block)
*                 A0    A1
*
*   void FreeVecPooled(APTR, APTR);
* FUNCTION
*   Frees memory block allocated from given memory pool with AllocVecPooled.
* INPUTS
*   pool - memory pool handle
*   block - block to be freed
* RESULT
*   None.
* NOTES
*   Requires external _SysBase symbol.
*   No sanity checks are done on arguments.
* SEE ALSO
*   AllocVecPooled
*
*****************************************************************************/
		.global _FreeVecPooled
		.xref   _SysBase
			
FreePooled 	= -714

_FreeVecPooled:
		MOVE.L	a6,-(sp)
		MOVE.L	-(a1),d0
		MOVEA.L	_SysBase,a6
		JSR	FreePooled(a6)
		MOVEA.L	(sp)+,a6
		RTS
