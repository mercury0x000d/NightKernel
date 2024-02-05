/* SMBIOS support file */

#ifndef _SMBIOS_H
#define _SMBIOS_H               1

/* 

        C99 stdint header include

        WATCOM and newer C compilers have stdint. Older compilers
        like Turbo C++ do not
*/

#ifdef __WATCOMC__
#include <stdint.h>
#else
#include "stdint.h"
#endif

 struct SMBios {
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
  };

  struct SMBIOSHeader {
    BYTE Type;
    BYTE Length;
    WORD Handle;
  };

 char far * findSMBIOS ();

#endif
