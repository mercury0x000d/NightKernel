/*

	DOS PM

*/

/* Operating System Constants */

#define DOSPM_MAJVN           0x0001       /* Major Version number */
#define DOSPM_MINVN           0x0000       /* Minor Version number */
#define DOSPM_PATCHLVL        0x0000       /* Patch level          */

#define EXTERN             extern       /* to be used in other .h files */
#define PRIVATE            static       /* limits scope of variables    */
#define PUBLIC
#define FORWARD
#define NUL_PTR         (char*) 0       /* a generally useful express */

/* Boolean values */
#define FALSE                   0
#define TRUE              !FALSE       /* Make sure TRUE is defined correctly */

#define HZ                     60       /* clock freq */
#define BLOCK SIZE           1024       /* bytes in disk block */
#define N_TASK_XFR              8       /* number of tasks in xfer table */
#define N_PROC                 16       /* number of slots in proc table */
#define N_SEG                   3       /* number of segments per process */
#define T                       0       /* text (code) segment */
#define D                       1       /* data segment */
#define S                       2       /* stack segment */

/* define our basic types */
typedef void VOID;
typedef long LONG;
typedef char CHAR;
typedef short SHORT;
typedef unsigned char BYTE;     
typedef unsigned short WORD;
typedef unsigned long DWORD;

/* define our basic pointer types */
typedef VOID* PVOID;
typedef SHORT* PSHORT;
typedef LONG* PLONG;
typedef CHAR* PCHAR;
typedef CHAR* LPCH;
typedef CHAR* PCH;
typedef VOID* LPVOID;

/* now for the derived types */
typedef VOID* HANDLE;

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
