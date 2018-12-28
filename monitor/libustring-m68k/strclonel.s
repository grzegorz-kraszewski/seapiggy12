/****** StrCloneL ************************************************************
* NAME
*   StrCloneL -- creates a copy of a 32-bit string
* SYNOPSIS
*   newstr = StrCloneL(string)
*   D0                 A0
*
*   ULONG* StrCloneL(const ULONG*);
* FUNCTION
*   Sizes the string, allocates memory for a copy, then copies the string into
*   the allocated buffer. The clone must be later freed with
*   exec.library/FreeVec.
* INPUTS
*   string - string to be cloned string.
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for UTF-32/UCS-4, any endian.
* SEE ALSO
*   StrClonePooledL, StrClone, StrCloneW
*
*****************************************************************************/

		.global	_StrCloneL
			
		.xref	_StrSizeL
		.xref	_CloneMem
								
_StrCloneL:
		MOVE.L	a2,-(sp)
		MOVEA.L	a0,a2
		BSR.S	_StrSizeL
		MOVEA.L	a2,a0
		BSR.S	_CloneMem
		MOVEA.L (sp)+,a2
		RTS
