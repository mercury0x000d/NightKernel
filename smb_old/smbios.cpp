/* SMBIOS Stuff

*/

#include <stdio.h>
#include "smbios.h"
#include "stdint.h"


char far * findSMBIOS () {
  char far * a;
  unsigned char checksum;
  char *anchor;


  int i, j, length, proceed, match;


  anchor = "_SM_";

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
