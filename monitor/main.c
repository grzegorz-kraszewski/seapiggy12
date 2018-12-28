/*------------------------*/
/* seapiggy.monitor       */
/* (c) RastPort 2018      */
/* main code file         */
/*------------------------*/

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/graphics.h>
#include <proto/utility.h>

#include <graphics/monitor.h>
#include <graphics/gfxbase.h>
#include <utility/tagitem.h>

extern struct Library *DOSBase, *SysBase;

struct Library *GfxBase, *UtilityBase;










/****i* main/GetLibs ********************************************************
* 
* NAME
*   GetLibs -- Opens needed libraries, closes after use.
*
* SYNOPSIS
*   succes = GetLibs()
*   BOOL GetLibs(void);
*
* FUNCTION
*   Opens folowing libraries:
*   - graphics.library
*   - utility.library
*   If all of them are opened succesfully, calls
*   UpdateDisplayInfoDataBase(). Then all succesfully opened libraries are
*   closed.
* 
* INPUTS
*   None.
*
* OUTPUT
*   FALSE if any of libraries could not be opened. Otherwise it returns
*   result of GetMemoryPool().
*
* SEE ALSO
*   displayinfo/UpdateDisplayInfoDataBase()
*
*****************************************************************************
*/


static BOOL GetLibs(void)
{
	BOOL result = FALSE;

	if (GfxBase = OpenLibrary("graphics.library", 39))
	{
		if (UtilityBase = OpenLibrary("utility.library", 39))
		{
			result = UpdateDisplayInfoDataBase();
			CloseLibrary(UtilityBase);
		}
		
		CloseLibrary(GfxBase);
	}

	return result;
} 



ULONG Main(void)
{
	BOOL result = TRUE;
	
	result = GetLibs();
	if (!result) PutStr("Failed.\n");
	return 0;
}
