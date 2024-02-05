/* 
	Partial implementation of STDINT.H ISO C99 Stuff
	and other requirements for SMBIOS

*/

#ifndef _STDINT_H
#define _STDINT_H               1
#pragma pack(1)

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long ULONG;
typedef void far *FP;
typedef FP far *FPP;

#ifndef MK_FP
#define MK_FP(seg,ofs)  ((void far *)((unsigned long)(seg) << 16 | (ofs)))
#endif
#endif
