OUTPUT_FORMAT("binary")
ENTRY(kernel)
phys = 0x0600;

SECTIONS
{
  .text phys : AT(phys) {
     code = .;
     *(.text)
     *(.rodata)
     . = ALIGN(4);
   }
   .data : AT(phys + (data - code))
   {
      data = .;
      *(.data)
      . = ALIGN(4);
   }
   .bss : AT(phys + (bss - code))
   {
     bss = .;
     *(.bss)
     . = ALIGN(4);
   }
   end = .;
}
