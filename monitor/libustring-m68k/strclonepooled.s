/****** StrClonePooled *******************************************************
* NAME
*   StrClonePooled -- creates a copy of 8-bit string in a memory pool
* SYNOPSIS
*   newstr = StrClonePooled(mempool, string)
*   D0                      A0       A1
*
*   UBYTE* StrClonePooled(APTR, const UBYTE*);
* FUNCTION
*   Creates a copy of 8-bit string, allocating memory for it from given memory
*   pool. The clone may be freed later with FreeVecPooled, or discarded with
*   the whole pool.
* INPUTS
*   mempool - memory pool
*   string - string to be cloned
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for any 8-bit codepage and UTF-8.
* SEE ALSO
*   StrClone, StrClonePooledW, StrClonePooledL
*
*****************************************************************************/

		.global	_StrClonePooled
			
		.xref	_StrSize
		.xref	_CloneMemPooled
								
_StrClonePooled:
		MOVEM.L	a0/a1,-(sp)
		BSR.S	_StrSize		
		MOVEM.L	(sp)+,a0/a1
		BSR.S	_CloneMemPooled
		RTS
