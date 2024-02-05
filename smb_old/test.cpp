#include <string.h>
#include <stdio.h>
#include <conio.h>
#include "smbios.h"

#pragma pack(1)


char far * findSMBIOS()
 {

   char far *a;
   char far *SMBIOS_BEGIN;


   char *anchor;
   unsigned char checksum;
   int i, j, proceed, match, length;

   anchor = "_SM_";

   /* a = ((char far *)((unsigned long)0xF000<< 16 | 0x0000));*/
   a = MK_FP(0xF000,0x0000);
   proceed = 1;
   match = 1;
   while ( proceed == 1) {
     for (i = 0; i < 4; i++) {
       if (a[i] != anchor[i]) {
         match = 0;
         break;
       } else {
         match = 1;
       }
     }
     if (match == 1) {
       proceed = 0;
       length = a[5];
       for (j = 0; j < length; j++) {
         checksum += a[j];
       }
     } else {
       a += 4;
     }
   }
   return a;
}

void main() {
   char far * a;

   a = findSMBIOS();
   printf("SMBIOS Detected at Address: %lx\n", a);
   printf("SMBIOS length: %x\n",a[5]);
   printf("SMBIOS Version: %d.%d",a[6],a[7]);
   getch();
}