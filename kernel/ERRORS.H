/*
	DOS PM
	Version 1.0




	FILENAME: ERRORS.H

	DESCRIPTION:  This file provides all the error constants
		      used by DOS PM.

		      Some constants were obtained by looking into
		      various OS design books, and peering into the
		      internals of various PCs

*/


#define ERROR_INVALID_FUNCTION          0x001   /* invalid function */
#define ERROR_FILE_NOT_FOUND            0x002   /* file not found   */
#define ERROR_PATH_NOT_FOUND            0x003   /* path not found   */
#define ERROR_TOO_MANY_FILES_OPEN       0x004   /* too many open files */
#define ERROR_ACCESS_DENIED             0x005   /* access denied */
#define ERROR_INVALID_HANDLE            0x006   /* invalid device handle */
#define ERROR_ARENA_TRASHED             0x007   /* memory arena trashed */
#define ERROR_NO_MEM_AVAIL              0x008   /* insufficient memory */
#define ERROR_INVALID_BLOCK             0x009   /* invalid block */
#define ERROR_BAD_ENVIRONMENT           0x00A   /* bad environment block */
#define ERROR_BAD_FORMAT                0x00B   /* wrong format */
#define ERROR_INVALID_ACCESS            0x00C   /* invalid access */
#define ERROR_INVALID_DATA              0x00D   /* invalid data */
#define ERROR_INVALID_DRIVE             0x00E   /* invalid drive */
#define ERROR_CURRENT_DIR               0x00F   /* current directory */
#define ERROR_NOT_SAME_DEVICE           0x010
#define ERROR_NO_MORE_FILES             0x011
#define ERROR_WRITE_PROTECT             0x012
#define ERROR_BAD_UNIT                  0x013
