/****** StrClonePooledL ******************************************************
* NAME
*   StrClonePooledL -- creates a copy of 32-bit string in a memory pool
* SYNOPSIS
*   newstr = StrClonePooledL(mempool, string)
*   D0                       A0       A1
*
*   ULONG* StrClonePooledL(APTR, const ULONG*);
* FUNCTION
*   Creates a copy of 32-bit string, allocating memory for it from given
*   memory pool. The clone may be freed later with FreeVecPooled, or discarded
*   with the whole pool.
* INPUTS
*   mempool - memory pool
*   string - string to be cloned
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for UTF-32/UCS-4, both endians.
* SEE ALSO
*   StrCloneL, StrClonePooled, StrClonePooledW
*
*****************************************************************************/

		.global	_StrClonePooledL
			
		.xref	_StrSizeL
		.xref	_CloneMemPooled
								
_StrClonePooledL:
		MOVEM.L	a0/a1,-(sp)
		BSR.S	_StrSizeL		
		MOVEM.L	(sp)+,a0/a1
		BSR.S	_CloneMemPooled
		RTS
