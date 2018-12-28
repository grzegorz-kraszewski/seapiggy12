/****** StrClonePooledW ******************************************************
* NAME
*   StrClonePooledW -- creates a copy of 16-bit string in a memory pool
* SYNOPSIS
*   newstr = StrClonePooledW(mempool, string)
*   D0                       A0       A1
*
*   UWORD* StrClonePooledW(APTR, const UWORD*);
* FUNCTION
*   Creates a copy of 16-bit string, allocating memory for it from given memory
*   pool. The clone may be freed later with FreeVecPooled, or discarded with
*   the whole pool.
* INPUTS
*   mempool - memory pool
*   string - string to be cloned
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for UTF-16/UCS-2, both endians.
* SEE ALSO
*   StrCloneW, StrClonePooled, StrClonePooledL
*
*****************************************************************************/

		.global	_StrClonePooledW
			
		.xref	_StrSizeW
		.xref	_CloneMemPooled
								
_StrClonePooledW:
		MOVEM.L	a0/a1,-(sp)
		BSR.S	_StrSizeW		
		MOVEM.L	(sp)+,a0/a1
		BSR.S	_CloneMemPooled
		RTS
