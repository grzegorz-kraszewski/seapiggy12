FORCE_COMMON_ALLOCATION

SECTIONS
{
    . = 0x8000;

    .text :
    {
	boot.o(.text)
	*(.text)
	*(.text.*)
	*(.stub)
	*(.gnu.linkonce.t.*)
    }
    
    .rodata ALIGN(32):
    {
	*(.rodata)
	*(.rodata.*)
	*(.gnu.linkonce.r.*)
    }
    
    .rodata1 : { *(.rodata1) }
    
    .data ALIGN(32):
    {
	*(.data)
	*(.data.*)
	*(.gnu.linkonce.d.*)
    }
    
    .data1 : { *(.data1) }
    
    __bss_start__ = .;
    
    .bss ALIGN(32):
    {
	*(.bss)
	*(.bss.*)
	*(.gnu.linkonce.b.*)
	*(COMMON)
    }
    
    __bss_end__ = .;
}
