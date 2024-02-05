/* SMBIOS Stuff

*/

#include <stdio.h>
#include <string.h>
#include "smbios.h"

#ifndef __WATCOMC__
#include "stdint.h"
#else
#include <stdint.h>
#endif

/* uint8_t smbios_checksum(char far * addr, uint8_t len) {

  uint8_t csum;
  int i;

  for (csum =0, i = 0; i < len; i++) {
    csum += SMBIOS_GET8(addr, i);
  }

  return (csum);
}                */

char far * findSMBIOS () {
  char far * a;
  uint8_t checksum;
  char *anchor;


  uint8_t i, j, length, proceed, match;


  anchor = SMBIOS_SIG;

  a = (char far *)MK_FP(0xF000,0x0);
  proceed =1;
  match =1;

  while (proceed == 1) {
    for  (i=0; i<4; i++) {
      if(a[i] != anchor[i]) {
	match = 0;
	break;
      } else {
	match = 1;
      }
    }
    if (match == 1) {

      length = SMBIOS_GET8(a, 5);
      for (j = 0; j < length; j++) {
	 checksum += SMBIOS_GET8(a, j);
       }
       if (checksum == 0) {
         proceed = 0;
       }
    } else {
      a += SMBIOS_STP;
    }
  }
   if (match == 1) {
     return (a);
   } else {
     return (NULL);
   }
}

char far * findSMBIOS2() {
   char far * a;
   char far * addr;

   addr = (char far *)MK_FP(0xF000,0x0);

   for (a = addr; a < addr + 0x100000; a += SMBIOS_STP)
     printf("Address: %lX\n", a);
     if(strncmp((const char *)a, SMBIOS_SIG, 4) == 0 &&
       strncmp((const char *)a + 0x10, SMBIOS_DMI_SIG, 5) == 0) {
         return (a);
        }
   return (NULL);
}

uint16_t FindStructure ( char * TableAddress, uint16_t StructureCount, uint8_t Type) {
  uint16_t i, handle;
  uint8_t lasttype;

  i = 0;
  handle = 0xFFFF;
  while (i < StructureCount && handle == 0xFFFF) {
    i++;
    lasttype = ((HEADER *)TableAddress)->Type;
    if ( lasttype == Type) {
      handle = ((HEADER *)TableAddress)->Handle;
    } else {
      TableAddress += ((HEADER *)TableAddress)->Length;
      while ( *((int *)TableAddress) != 0) {
        TableAddress++;
      }
      TableAddress += 2;
    }
  }
  return handle;
} // END FindStructure