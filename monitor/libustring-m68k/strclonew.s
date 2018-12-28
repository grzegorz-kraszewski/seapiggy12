/****** StrCloneW ************************************************************
* NAME
*   StrCloneW -- creates a copy of a 16-bit string
* SYNOPSIS
*   newstr = StrCloneW(string)
*   D0               A0
*
*   UWORD* StrCloneW(const UWORD*);
* FUNCTION
*   Sizes the string, allocates memory for a copy, then copies the string into
*   the allocated buffer. The clone must be later freed with
*   exec.library/FreeVec.
* INPUTS
*   string - string to be cloned.
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for UCS-2 and UTF-16, any endian.
* SEE ALSO
*   StrClonePooledW, StrClone, StrCloneL
*
*****************************************************************************/

		.global	_StrCloneW

		.xref	_StrSizeW
		.xref	_CloneMem

_StrCloneW:
		MOVE.L	a2,-(sp)
		MOVEA.L	a0,a2
		BSR.S	_StrSizeW	
		MOVEA.L	a2,a0
		BSR.S	_CloneMem
		MOVEA.L (sp)+,a2
		RTS
