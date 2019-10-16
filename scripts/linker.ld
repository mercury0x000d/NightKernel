OUTPUT_FORMAT("binary")
ENTRY(main)
phys = 0x0600;

SECTIONS
{
	.text phys : AT (phys) SUBALIGN(1)
	{
		code = .;
		*(.text)
		*(.rodata)
	}

	.data : AT (phys + (data - code)) SUBALIGN(1)
	{
		data = .;
		*(.data)
	}

	.bss : AT (phys + (bss - code)) SUBALIGN(1)
	{
		bss = .;
		*(.bss)
	}

	end = .;
}
