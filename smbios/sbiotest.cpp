#include <stdio.h>
#include <conio.h>
#include "smbios.h"
#include "bcdtool.h"
#if __WATCOMC__ < 1200
#include "stdint.h"
#else
#include <stdint.h>
#endif

int bcd_decimal(uint8_t hex) {
  int dec = ((hex & 0xF0) >> 4) * 10 + (hex & 0x0F);
  return dec;
}

void main() {
  clrscr();
  printf("SMBIOS Test Code\n");
  LPSMBIOS s = 0;
  s = (LPSMBIOS) findSMBIOS();
  if (s != NULL) {
    printf("SMBIOS Version detected at: %lX\n",s);
    printf("SMBIOS Checksum: %x\n",s->eps_checksum);
    printf("SMBIOS Length: %x\n",s->entrypointlength);
    printf("SMBIOS version (offset 6 and 7) %d.%d\n",s->majorversion,s->minorversion);
    int major, minor;
    if (s->revision != 0) {
       major = s->revision >> 4;
       minor = s->revision & 0x0f;
    }
    printf("SMBIOS revision: %d.%d\n\n",major,minor);
    uint16_t bioshandle = 0;

    bioshandle = FindStructure ((char *) &s->tableaddress, s->smbiosstructcnt, 0);
  } else {
    printf("Unable to locate SMBIOS\n");
  }
  getch();
}