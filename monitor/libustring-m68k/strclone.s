/****** StrClone ***************************************************************
* NAME
*   StrClone -- creates a copy of an 8-bit string
* SYNOPSIS
*   newstr = StrClone(string)
*   D0                A0
*
*   UBYTE* StrClone(const UBYTE*);
* FUNCTION
*   Sizes the string, allocates memory for a copy, then copies the string into
*   the allocated buffer. The clone must be later freed with
*   exec.library/FreeVec.
* INPUTS
*   string - string to be cloned
* RESULT
*   Pointer to the copy created, or NULL if memory allocation failed.
* NOTES
*   May be used for any 8-bit codepage and UTF-8.
* SEE ALSO
*   StrClonePooled, StrCloneW, StrCloneL
*
*****************************************************************************/

		.global	_StrClone
			
		.xref	_StrSize
		.xref	_CloneMem
								
_StrClone:
		MOVE.L	a2,-(sp)
		MOVEA.L	a0,a2
		BSR.S	_StrSize
		MOVEA.L	a2,a0
		BSR.S	_CloneMem
		MOVEA.L (sp)+,a2
		RTS
