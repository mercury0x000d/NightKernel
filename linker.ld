ENTRY(main)			/* name of entry label */

SECTIONS {

	. = 0x600;		/* start at 0x600 */			
	
	.text ALIGN (0x1000) :	/* align at 4K */
	{
	    *(.text)		/* all text (code) sections from all files */
	}

	.rodata ALIGN (0x1000) :/* align at 4K */
	{
	    *(.rodata*)		/* all read-only sections from all files */
	}

	.data ALIGN (0x1000) :  /* align at 4K */
	{
	    *(.data)		/* all data sections from all files */
	}

	.bss ALIGN (0x1000) :	/* align at 4K */
	{
	    *(COMMON)
	    *(.bss)		
        }
}
