#include <stdio.h>
#include <conio.h>
#include "smbios.h"
#include "stdint.h"


 /*  typedef struct {
    char anchor[4];
    BYTE eps_checksum;
    BYTE entrypointlength;
    BYTE majorversion;
    BYTE minorversion;
    WORD maxstructsize;
    BYTE entrypointrevision;
    char formattedarea[5];
    char intermediateanchor[5];
    BYTE intermediatechecksum;
    WORD tablelength;
    FP tableaddress;
    WORD smbiosstructcnt;
    BYTE revision;
  } SMBIOS, far * LPSMBIOS;

  typedef struct {
    BYTE Type;
    BYTE Length;
    WORD Handle;
  } HEADER; */



void main() {

  char far * smbios = 0;
  SMBios far * s = 0;
  smbios = findSMBIOS();
  s = (SMBios *)findSMBIOS();
  printf("Structure address: %lx\n",smbios);
  printf("Address: %lx\n",s);
  /* printf("SMBIOS version %d.%d\n ",s.majorversion,s.minorversion);*/
  getch();
}