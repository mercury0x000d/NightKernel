#include <stdio.h>
#include <conio.h>
#include <string.h>
#include "smbios.h"

FP findSMBIOS2() {
   const char far * a;
   char far * addr;

   addr = (char far *)MK_FP(0xF000,0x0);

   for (a = addr; a < addr + SMBIOS_LN; a += SMBIOS_STP)
     if( _fstrncmp(a, SMBIOS_SIG, 4) == 0 &&
       _fstrncmp(a + 0x10, SMBIOS_DMI_SIG, 5) == 0) {
        printf("\nAddress: %lx\n", a);
         return ((void far *)a); }
   printf("\nUnable to detect SMBIOS\n");
   return (NULL);


}

FP findSMBIOS () {
  char far *a;
  char *anchor;

  int i, proceed, match;

  anchor = "_SM_";

  a = (char far *)MK_FP(0xF000,0x0);
  proceed =1;
  match =1;

  while (proceed == 1) {
    for (i=0; i<4; i++) {
      if(a[i] != anchor[i]) {
	match = 0;
	break;
      } else {
	match = 1;
      }
    }
    if (match == 1) {
      proceed = 0;
    } else {
      a += 4;
    }

  }
  #ifdef DEBUG
  printf("FindSMBIOS Address: %lx\n",a);
  #endif
  return a;
}

FP findSMBIOSUEFI () {
  char far *a;
  char *anchor;

  int i, proceed, match;

  anchor = "_SM3_";

  a = (char far *)MK_FP(0xF000,0x0);
  proceed =1;
  match =1;

  while (proceed == 1) {
    for (i=0; i<4; i++) {
      if(a[i] != anchor[i]) {
	match = 0;
	break;
      } else {
	match = 1;
      }
    }
    if (match == 1) {
      proceed = 0;
    } else {
      a += 4;
    }

  }
  #ifdef DEBUG
  printf("FindSMBIOS Address: %lx\n",a);
  #endif
  return a;
}

uint16_t FindStructure (char * ta, uint16_t StructureCount, uint8_t Type) {

  uint16_t i, handle;
  uint8_t lasttype;
  //unsigned char * ta;

  #ifdef DEBUG
  //printf("\nTable Address on entry: %08lx\n", TableAddress);
  #endif
  //ta = (unsigned char *)TableAddress;
  printf("\nTable Address on updated: %08lx\n", ta);
  i = 0;
  handle = 0xFFFF;

   while (i < StructureCount && handle == 0xFFFF) {
     i++;
     printf("\nHeader Length: %x",((HEADER *)ta)->Length);
     printf("\nHeader Type: %x Requested type: %x\n", ((HEADER *)ta)->Type, Type);
     lasttype = ((HEADER *)ta)->Type;
     if (lasttype == Type) {
       printf("\nFound selected type.\n");

       handle = ((HEADER *)ta)->Handle;
     } /* found first structure of the requested type */
     else {
       ta += ((HEADER *)ta)->Length;
       while ( *((int *)ta) != 0) {
	 ta++;
       }
       ta += 2;
     }
   }
   #ifdef DEBUG
   printf("Handle value: %08x\n", handle);
   #endif
   return handle;
}

