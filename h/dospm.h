/*

	DOSPM.H -       DOS PM functions, types and definitions
			
			Version 1.0

*/

/* Operating System Constants */

#ifndef  __DOSPM_H                      	/* to prevent multiple includes */
#define  __DOSPM_H

#ifdef __cplusplus
extern "C" {                                /* Assume C declarations for C++ */
#endif

/* If DOSPMVER is not defined, assume version 1.0       */
#ifndef DOSPMVER
#define DOSPMVER          0x0100
#endif

/* Old style version declaration, this section may be removed   */
#define DOSPM_MAJVN           0x0001       /* Major Version number */
#define DOSPM_MINVN           0x0000       /* Minor Version number */
#define DOSPM_PATCHLVL        0x0000       /* Patch level          */

/* Common definitions and typedefs */
#define VOID                    void
#define FAR                     _far
#define NEAR                    _near
#define PASCAL                  _pascal
#define CDECL                   _cdecl

/*********************************************************************************
* 
*  I borrowed this section from windows.h for the WINAPI, this doesn’t 
*  necessarily need to apply to DOS PM, but it can.
*
**********************************************************************************/

#define WINAPI                  _far _pascal
#define CALLBACK                _far _pascal

/********************************************************************************
*
*   End of the borrow
*
*********************************************************************************/
		
#define EXTERN                  extern       /* to be used in other .h files */
#define PRIVATE                 static       /* limits scope of variables    */
#define PUBLIC
#define FORWARD
/* 
   removed as this is defined in _NULL.H
#define NUL_PTR                 (char*) 0       /* a generally useful express */

/* Boolean values */
#define FALSE                   0
#define TRUE                    !FALSE       /* Make sure TRUE is defined correctly */

#define HZ                      60       /* clock freq */
#define BLOCK SIZE              1024       /* bytes in disk block */
#define N_TASK_XFR              8       /* number of tasks in xfer table */
#define N_PROC                  16       /* number of slots in proc table */
#define N_SEG                   3       /* number of segments per process */
#define T                       0       /* text (code) segment */
#define D                       1       /* data segment */
#define S                       2       /* stack segment */

/* define our basic types */
/* typedef void VOID; removed since I used a define above */
typedef int                     BOOL;

#ifdef STRICT
typedef signed long             LONG;
#else
#define LONG long
#endif

typedef char                    CHAR;
typedef short                   SHORT;
typedef unsigned char           BYTE;
typedef unsigned short          WORD;
typedef unsigned long           DWORD;
typedef unsigned int            UINT;

typedef signed char             int8_t;
typedef unsigned char           uint8_t;
typedef short                   int16_t;
typedef unsigned short          uint16_t;
typedef int                     int32_t;
typedef unsigned                uint32_t;
typedef long long               int64_t;
typedef unsigned long long      uint64_t;

/* define our basic pointer types */
typedef VOID* PVOID;
typedef SHORT* PSHORT;
typedef LONG* PLONG;
typedef CHAR* PCHAR;
typedef CHAR* LPCH;
typedef CHAR* PCH;
/* typedef VOID* LPVOID; */

typedef char NEAR*      PSTR;
typedef char NEAR*      NPSTR;
typedef char FAR*       LPSTR;
typedef const char FAR* LPCSTR;
typedef BYTE NEAR*      PBYTE;
typedef BYTE FAR*       LPBYTE;
typedef int NEAR*       PINT;
typedef int FAR*        LPINT;
typedef WORD NEAR*      PWORD;
typedef WORD FAR*       LPWORD;
typedef long NEAR*      PLONG;
typedef long FAR*       LPLONG;
typedef DWORD NEAR*     PDWORD;
typedef DWORD FAR*      LPDWORD;
typedef void FAR*       LPVOID;


/* now for the derived types */
typedef VOID* HANDLE;

/* Macros - borrowed from windows.h   */
#define LOBYTE(w)               ((BYTE)(w))
#define HIBYTE(w)               ((BYTE)((UINT)(w) >> 8))

#define LOWORD(l)               ((WORD)(l))
#define HIWORD(l)               ((WORD)((DWORD)(l) >> 16))
#define MAKELONG(low, high)     ((LONG)(((WORD)(low)) | (((DWORD)((WORD)(high))) << 16)))
#define MAKELP(sel, off)       ((void FAR*)MAKELONG((off), (sel)))
#define SELECTOROF(lp)          HIWORD(lp)
#define OFFSETOF(lp)            LOWORD(lp)
#define FIELDOFFSET(type, field) ((int)(&((type NEAR*)1)->field)-1)

#if !defined(NOMINMAX) && !defined(__cplusplus)
#ifndef max
#define max(a, b)               (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
#define min                     (((a) < (b)) ? (a) : (b))
#endif
#endif /* NOMINMAX */



#ifdef __cplusplus
}                                               /* End of extern "C" { */
#endif                                          /* __cplusplus */
#ifdef __cplusplus
const MINCHAR=-128;
const MAXCHAR=127;
const MINSHORT=-32768;
const MAXSHORT=32767;
const MINLONG=-2147483648;
const MAXLONG=2147483647;
const MAXBYTE=255;
const MAXWORD=65535;
const MAXDWORD=4294967296;

#else /* __cplusplus */
#define MINCHAR (-128)
#define MAXCHAR 127
#define MINSHORT (-32768)
#define MAXSHORT 32767
#define MINLONG (-2147483648)
#define MAXLONG 2147483647
#define MAXBYTE 255
#define MAXWORD 65535
#define MAXDWORD 42949567296
#endif /* __cplusplus */

#endif