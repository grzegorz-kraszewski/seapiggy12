/*-------------------------------*/
/* seapiggy.monitor              */
/* (c) RastPort 2018             */
/* DisplayInfo database updater. */
/*-------------------------------*/

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/graphics.h>
#include <proto/utility.h>

#include <graphics/monitor.h>
#include <graphics/gfxbase.h>
#include <utility/tagitem.h>

#include "libustring-m68k/include/libustring.h"
#include "main.h"


/*--------------------------------------------*/
/* Definitions for SeaPiggy monitor and modes */
/*--------------------------------------------*/

#define SEAPIGGY_MONITOR_NAME "seapiggy.monitor"
#define SEAPIGGY_MONITOR_ID 0x00120000

struct ModeSpec
{
	STRPTR Name;
	UWORD ModeID;
	WORD Width;
	WORD Height;
	WORD HResolution;
	WORD VResolution;
};

struct ModeSpec Modes[5] = {
	{ "Piggy:Low Res", 0x0000, 320, 256, 44, 44 },
	{ "Piggy:High Res", 0x0001, 640, 256, 22, 44 },
	{ "Piggy:High Res Double", 0x0002, 640, 512, 22, 22 },
	{ "Piggy:Super-High Res", 0x0006, 1280, 512, 11, 22 },
	{ "Piggy:Super-High Res Double", 0x000A, 1280, 1024, 11, 11 },
};


/*====================================*/
/* Structures of DisplayInfo database */
/*====================================*/


/*------------------------------*/
/* Size: 56 bytes, 7 tag slots. */
/*------------------------------*/

struct DispInfoNode
{
	struct DispInfoNode *Succ;
	struct DispInfoNode *Pred;
	struct DispInfoNode *Child;
	struct DispInfoNode *Parent;
	ULONG Key;
	struct TagItem Tag;
	ULONG pad[3];
	struct Rectangle Overscan;
	ULONG reserved[2];
};


/*------------------------------*/
/* Size: 64 bytes, 8 tag slots. */
/*------------------------------*/

struct DimsInfoData
{
	UWORD MaxDepth;
	UWORD MinRasterWidth;
	UWORD MinRasterHeight;
	UWORD MaxRasterWidth;
	UWORD MaxRasterHeight;
	struct Rect32 Nominal;
	struct Rect32 MaxOScan;
	struct Rect32 VideoOScan;
	UBYTE pad[6];
};


/*------------------------------*/
/* Size: 72 bytes, 9 tag slots. */
/*------------------------------*/

struct MntrInfoData
{
	struct MonitorSpec *Mspc;
	Point ViewPosition;
	Point ViewResolution;
	struct Rectangle ViewPositionRange;
	UWORD TotalRows;
	UWORD TotalColorClocks;
	UWORD MinRow;
	WORD Compatibility;
	struct Rect32 TxtOverscan;
	struct Rect32 StdOverscan;
	Point MouseTicks;
	Point DefaultViewPosition;
	ULONG PreferredModeID;
};


/*------------------------------*/
/* Size: 32 bytes, 4 tag slots. */
/*------------------------------*/

struct DispInfoData
{
	UWORD NotAvailable;
	ULONG PropertyFlags;
	Point Resolution;
	UWORD PixelSpeed;
	UWORD NumStdSprites;
	UWORD PaletteRange;
	Point SpriteResolution;
	UBYTE pad[4];
	UBYTE RedBits;
	UBYTE GreenBits;
	UBYTE BlueBits;
	UBYTE pad2[5];
};


/*------------------------------*/
/* Size: 32 bytes, 4 tag slots. */
/*------------------------------*/

struct NameInfoData
{
	UBYTE Name[DISPLAYNAMELEN];
};



struct TagItem ModeTagList[32] = {
	{ DTAG_DISP, SEAPIGGY_MONITOR_ID },   /*  0 */
	{ TAG_SKIP, 4 },                      /*  1 */
	{ 0, 0 },                             /*  2, DispInfoData here */
	{ 0, 0 },                             /*  3 */
	{ 0, 0 },                             /*  4 */
	{ 0, 0 },                             /*  5 */
	{ TAG_MORE, 0 },                      /*  6 */
	{ DTAG_DIMS, SEAPIGGY_MONITOR_ID },   /*  7 */
	{ TAG_SKIP, 8 },                      /*  8 */
	{ 0, 0 },                             /*  9, DimsInfoData here */
	{ 0, 0 },                             /* 10 */
	{ 0, 0 },                             /* 11 */
	{ 0, 0 },                             /* 12 */
	{ 0, 0 },                             /* 13 */
	{ 0, 0 },                             /* 14 */
	{ 0, 0 },                             /* 15 */
	{ 0, 0 },                             /* 16 */
	{ TAG_MORE, 0 },                      /* 17 */
	{ DTAG_NAME, SEAPIGGY_MONITOR_ID },   /* 18 */
	{ TAG_SKIP, 4 },                      /* 19 */
	{ 0, 0 },                             /* 20, NameInfoData here */
	{ 0, 0 },                             /* 21 */
	{ 0, 0 },                             /* 22 */
	{ 0, 0 },                             /* 23 */
	{ TAG_END, 0 },                       /* 24 */
	{ 0, 0 },                             /* 25, DispInfoNode here */
	{ 0, 0 },                             /* 26 */
	{ 0, 0 },                             /* 27 */
	{ 0, 0 },                             /* 28 */
	{ 0, 0 },                             /* 29 */
	{ 0, 0 },                             /* 30 */
	{ 0, 0 }                              /* 31 */
};	


struct TagItem MonitorTagList[19] = {
	{ DTAG_MNTR, SEAPIGGY_MONITOR_ID },   /*  0 */
	{ TAG_SKIP, 9 },                      /*  1 */
	{ 0, 0 },                             /*  2, MntrInfoData here */
	{ 0, 0 },                             /*  3 */
	{ 0, 0 },                             /*  4 */
	{ 0, 0 },                             /*  5 */
	{ 0, 0 },                             /*  6 */
	{ 0, 0 },                             /*  7 */
	{ 0, 0 },                             /*  8 */
	{ 0, 0 },                             /*  9 */
	{ 0, 0 },                             /* 10 */
	{ TAG_END, 0 },                       /* 11 */
	{ 0, 0 },                             /* 12, DispInfoNode here */
	{ 0, 0 },                             /* 13 */
	{ 0, 0 },                             /* 14 */
	{ 0, 0 },                             /* 15 */
	{ 0, 0 },                             /* 16 */
	{ 0, 0 },                             /* 17 */
	{ 0, 0 }                              /* 18 */
};




static void DumpNode(struct DispInfoNode *node)
{
	struct DispInfoNode *child;
	struct TagItem *tag, *tagptr;
	
	Printf("Node @ $%08lx, child of $%08lx, key $%08lx. Data attached:\n", (ULONG)node, (ULONG)node->Parent,
		node->Key); 
	tagptr = &node->Tag;

	while (tag = NextTagItem(&tagptr))
	{
		Printf("[$%08lx, $%08lx]\n", tag->ti_Tag, tag->ti_Data);
	}

	PutStr("----------------------\n");
	
	Printf("Node overscan: (%ld x %ld) - (%ld, %ld).\n", node->Overscan.MinX, node->Overscan.MinY,
	 node->Overscan.MaxX, node->Overscan.MaxY);

	PutStr("----------------------\n");
	 
	for (child = node->Child; child; child = child->Succ)
	{
		DumpNode(child);
	}
}
	
	

static void DataBaseDump(void)
{
	struct GfxBase *gfxbase = (struct GfxBase*)GfxBase;
	
	DumpNode((struct DispInfoNode*)gfxbase->DisplayInfoDataBase);
}





/****i* displayinfo/AddAsLastChild ******************************************
* 
* NAME
*   AddAsLastChild -- Adds a displayinfo node as the last child of parent.
*
* SYNOPSIS
*   AddAsLastChild(parent, node)
*   void AddAsLastChild(struct DispInfoNode*, struct DispInfoNode*);
*
* FUNCTION
*   Checks parent node. If it has no children, new node is added as the first
*   and only child. Otherwise traverses list of children and adds new node at
*   the end of list.
*
* INPUTS
*   parent - the parent node
*   node - node to be inserted
*
* OUTPUT
*   None.
*
*****************************************************************************
*/

static void AddAsLastChild(struct DispInfoNode *parent, struct DispInfoNode *item)
{
	item->Parent = parent;

	if (parent->Child)
	{
		struct DispInfoNode *node;
		
		for (node = parent->Child; node->Succ; node = node->Succ);
		node->Succ = item;
		item->Pred = node;
	}
	else parent->Child = item;
}



/****i* displayinfo/InitDisplayInfo *****************************************
* 
* NAME
*   InitDisplayInfo -- initializes display info data
*
* SYNOPSIS
*   InitDisplayInfo(data, modespec)
*   void InitDisplayInfo(struct DispInfoData*, struct ModeSpec*);
*
* FUNCTION
*   Sets data in display info data structure related to given display mode.
*   Some data are taken from mode specification, some are hardcoded. List of
*   initializations:
*   - property flags "has sprites", "can be Workbench" and "foreign display"
*     are set,
*   - resolution aka "ticks per pixel" is taken from mode specification,
*   - pixel speed, 7 nanoseconds for super high res (1080p@60 HDMI timing),
*   - number of sprites is set to 16,
*   - sprite resolution is set equal to pixel resolution,
*   - RGB component bits are set to 8/8/8.
*
* INPUTS
*   data - points to data area of display info structure
*   modespec - display mode specification
*
* OUTPUT
*   None.
*
* NOTES
*   Pixel speed should be calculated based on physical display mode of the
*   monitor and logical/physical pixel ratio.
*
*****************************************************************************
*/

static void InitDisplayInfo(struct DispInfoData *d, struct ModeSpec *modespec)
{
	d->PropertyFlags = DIPF_IS_SPRITES | DIPF_IS_WB | DIPF_IS_FOREIGN;
	d->Resolution.x = modespec->HResolution;
	d->Resolution.y = modespec->VResolution;
	d->PixelSpeed = UDivMod32(7 * modespec->HResolution, 11);
	d->NumStdSprites = 16;
	d->PaletteRange = 0xFFFF;  /* obsolete, set to max possible */
	d->SpriteResolution.x = modespec->HResolution;
	d->SpriteResolution.y = modespec->VResolution;
	d->RedBits = 8;
	d->GreenBits = 8;
	d->BlueBits = 8;
}



/****i* displayinfo/InitDimensionInfo ***************************************
* 
* NAME
*   InitDimensionInfo - initializes dimensions info data
*
* SYNOPSIS
*   InitDimensionInfo(data, modespec)
*   void InitDimensionInfo(struct DimsInfoData*, struct ModeSpec*);
*
* FUNCTION
*   Sets data in display info data structure related to given display mode.
*   Some data are taken from mode specification, some are hardcoded. List of
*   initializations:
*   - colour depth is set to 24,
*   - minimum raster is set to 64 x 64 (arbitrary, not sure if it can be
*     smaller),
*   - maximum raster is set to 3840 x 2400 (maximum size of framebuffer on
*     Raspberry Pi).
*   - nominal display size is taken from mode specification,
*   - maximum overscan (expressed in 'ticks') is set to 1920 x 1080,
*   - video overscan is set to maximum overscan.
* 
* INPUTS
*   data - points to data area of dimensions info structure
*   modespec - display mode specification
*
* OUTPUT
*   None.
*
*****************************************************************************
*/


static void InitDimensionInfo(struct DimsInfoData *d, struct ModeSpec *modespec)
{
	d->MaxDepth = 24;
	d->MinRasterWidth = 64;
	d->MinRasterHeight = 64;
	d->MaxRasterWidth = 3840;
	d->MaxRasterHeight = 2400;
	
	d->Nominal.MinX = 0;
	d->Nominal.MinY = 0;
	d->Nominal.MaxX = modespec->Width * modespec->HResolution - 1;
	d->Nominal.MaxY = modespec->Height * modespec->VResolution - 1;
	
	d->MaxOScan.MinX = -320 * 11;
	d->MaxOScan.MinY = -28 * 11;
	d->MaxOScan.MaxX = 1600 * 11 - 1;
	d->MaxOScan.MaxY = 1052 * 11 - 1;
	
	d->VideoOScan = d->MaxOScan;
}



/****i* displayinfo/InitNameInfo ********************************************
* 
* NAME
*   InitNameInfo -- Initializes name info data.
*
* SYNOPSIS
*   InitNameInfo(data, modespec)
*   void InitNameInfo(struct NameInfoData*, struct ModeSpec*);
*
* FUNCTION
*   Copies display mode name from mode specification into the name info.
* 
* INPUTS
*   data - points to data area of name info structure
*   modespec - display mode specification
*
* OUTPUT
*   None.
*
* NOTES
*   Blindly assumes that mode name string is no longer than 32 bytes
*   including termination.
*
*****************************************************************************
*/

static void InitNameInfo(struct NameInfoData *d, struct ModeSpec *modespec)
{
	StrCopy(modespec->Name, d->Name);
}



/****i* displayinfo/InitMonitorInfo *****************************************
* 
* NAME
*   InitNameInfo -- Initializes monitor info data.
*
* SYNOPSIS
*   InitMonitorInfo(data, monspec)
*   void InitMonitorInfo(struct MntrInfoData*, struct MonitorSpec*);
*
* FUNCTION
*   Initializes monitor info data:
*   - sets pointer to MonitorSpec,
*   - sets total rows to 1122 (based on HDMI 1080p@60 timing),
*   - sets total color clocks to 53 (based on HDMI 1080p@60 timing and 280 ns
*     color clock period),
*   - sets default view position (1280 x 1024 centered on 1920 x 1080),
*   - sets compatibility flags (single viewport on view),
*   - sets mouse ticks and view resolution to 44/44,
*   - sets preferred mode ID to High Res,
*   - sets default text and standard overscan to nominal 1280 x 1024 field. 
* 
* INPUTS
*   data - points to data area of monitor info structure
*   monspec - pointer to MonitorSpec
*
* OUTPUT
*   None.
*
*****************************************************************************
*/


static void InitMonitorInfo(struct MntrInfoData *d, struct MonitorSpec *monspec)
{
	d->Mspc = monspec;
	d->TotalRows = 1122;
	d->TotalColorClocks = 53;
	d->ViewPositionRange = monspec->ms_LegalView;
	d->DefaultViewPosition.x = 80;
	d->DefaultViewPosition.y = 7;
	d->Compatibility = MCOMPAT_NOBODY;
	d->MouseTicks.x = 44;
	d->MouseTicks.y = 44;
	d->ViewResolution.x = 44;
	d->ViewResolution.y = 44;
	d->PreferredModeID = SEAPIGGY_MONITOR_ID | 0x0002;
	d->TxtOverscan.MinX = 0;
	d->TxtOverscan.MinY = 0;
	d->TxtOverscan.MaxX = 44 * 320 - 1;
	d->TxtOverscan.MaxY = 44 * 256 - 1;
	d->StdOverscan = d->TxtOverscan;
}



/****i* displayinfo/AddDisplayMode ******************************************
* 
* NAME
*   AddDisplayMode -- Adds display mode to the displayinfo database
*
* SYNOPSIS
*   AddDisplayMode(monitor_node, modespec, taglist)
*   void AddDisplayMode(struct DispInfoNode*, struct ModeSpec*, struct
*     TagItem*);
*
* FUNCTION
*   Initializes data structures describing a single display mode. Links them
*   together, then adds initialized entry as child of given monitor node. 
* 
* INPUTS
*   monitor_node - display mode node is added as a child of it
*   modespec - display mode specification used to initialize data
*   taglist - pointer to taglist representing structure to be initialized
*
* OUTPUT
*   None.
*
*****************************************************************************
*/

static void AddDisplayMode(struct DispInfoNode *monitor_node, struct ModeSpec *modespec, struct TagItem *tg)
{
	struct DispInfoNode *dispnode;
	struct DispInfoData *dsi;
	struct DimsInfoData *dmi;
	struct NameInfoData *nmi;

	CopyMem(ModeTagList, tg, 32 * sizeof(struct TagItem));

	dsi = (struct DispInfoData*)&tg[2];
	dmi = (struct DimsInfoData*)&tg[9];
	nmi = (struct NameInfoData*)&tg[20];
	dispnode = (struct DispInfoNode*)&tg[25];
	InitDisplayInfo(dsi, modespec);
	InitDimensionInfo(dmi, modespec);
	InitNameInfo(nmi, modespec);
	
	/* Setting mode ID in start tags. */
	
	tg[0].ti_Data |= modespec->ModeID;
	tg[7].ti_Data |= modespec->ModeID;
	tg[18].ti_Data |= modespec->ModeID;
	
	/* Linking taglist to the tree. */
		
	dispnode->Key = SEAPIGGY_MONITOR_ID | modespec->ModeID;
	dispnode->Tag.ti_Tag = TAG_MORE;
	dispnode->Tag.ti_Data = (ULONG)tg;

	/* Commodore design fail, payload data inside data structure skeleton */
			
	dispnode->Overscan.MinX = SDivMod32(-320 * 11, modespec->HResolution);
	dispnode->Overscan.MinY = SDivMod32(-28 * 11, modespec->VResolution);
	dispnode->Overscan.MaxX = modespec->Width + SDivMod32(320 * 11, modespec->HResolution) - 1;
	dispnode->Overscan.MaxY = modespec->Height + SDivMod32(28 * 11, modespec->VResolution) - 1;
		
	/* linking taglist */

	tg[6].ti_Data = (ULONG)&tg[7];
	tg[17].ti_Data = (ULONG)&tg[18];
	
	/* link complete subtree to the main one */
	
	AddAsLastChild(monitor_node, dispnode);
}


BOOL AddDisplayModes(struct MonitorSpec *msp)
{
	BOOL success = FALSE;
	struct DispInfoNode *root_node, *monitor_node;
	struct GfxBase *gfx = (struct GfxBase*)GfxBase;
	struct MntrInfoData *mni;
	struct ModeSpec *modespec;
	struct TagItem *tg;
	BYTE mode, modecount = 5;
	LONG memsize;
	
	memsize = (19 + modecount * 32) * sizeof(struct TagItem);
	
	if (tg = AllocMem(memsize, MEMF_ANY))
	{
		CopyMem(MonitorTagList, tg, 19 * sizeof(struct TagItem));
		monitor_node = (struct DispInfoNode*)&tg[12];
		mni = (struct MntrInfoData*)&tg[2];
		InitMonitorInfo(mni, msp);
		monitor_node->Key = SEAPIGGY_MONITOR_ID >> 16;
		monitor_node->Tag.ti_Tag = TAG_MORE;
		monitor_node->Tag.ti_Data = (ULONG)tg;
		success = TRUE;
		
		for (mode = 0; mode < modecount; mode++)
		{
			AddDisplayMode(monitor_node, &Modes[mode], &tg[19 + mode * 32]);
		}
		 
		Forbid();                                     /* OMG */
		root_node = gfx->DisplayInfoDataBase;
		AddAsLastChild (root_node, monitor_node);
		Permit();
	}

	return success;
}


BOOL AddMonitorSpec(struct MonitorSpec *msp)
{
	BOOL result = FALSE;
	struct SignalSemaphore *sem;
	struct GfxBase *gfx = (struct GfxBase*)GfxBase;
	
	ObtainSemaphore(gfx->MonitorListSemaphore);
	AddHead(&gfx->MonitorList, (struct Node*)msp);
	ReleaseSemaphore(gfx->MonitorListSemaphore);
	result = AddDisplayModes(msp);
	return result;
}


BOOL CreateMonitorSpec(STRPTR name)
{
	BOOL result = FALSE;
	struct MonitorSpec *msp;
	
	/*---------------------------------------------------------------*/
	/* MonitorSpec structure is never freed, especially as GfxFree() */
	/* is broken in Kickstart 3.0 and throws $0200000D guru when one */
	/* tries to free MONITOR_SPEC_TYPE.                              */
	/*---------------------------------------------------------------*/
	
	if (msp = (struct MonitorSpec*)GfxNew(MONITOR_SPEC_TYPE))
	{
		msp->ms_Node.xln_Name = name;
		msp->ratioh = 16;
		msp->ratiov = 16;		
		msp->total_colorclocks = 53;
		msp->total_rows = 1122; 

		/* assumes full HD monitor for now */
		
		msp->ms_LegalView.MinX = 0;
		msp->ms_LegalView.MinY = 0;
		msp->ms_LegalView.MaxX = 160;
		msp->ms_LegalView.MaxY = 14;

		msp->ms_Special = NULL;
		result = AddMonitorSpec(msp);
	}
	
	return result;
}


BOOL UpdateDisplayInfoDataBase(void)
{
	BOOL result = FALSE;
	STRPTR name;
	
	if (name = StrClone(SEAPIGGY_MONITOR_NAME))
	{
		result = CreateMonitorSpec(name);
		if (!result) FreeVec(name);
	}
	
	return result;
}
