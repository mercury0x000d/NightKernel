; NightDOS
;
;  msdosfs.inc
;
;  MS-DOS File System related structures
;
;  10/17/2015			adg		Created
;---------------------------------------------------

; section .data

; Boot Sector

STRUC BOOTSECTOR
	.bsJump				resb 3				; E9 XX XX or EB XX 90
	.bsOEMName			resb 8				; OEM Name and version
											; Start of BIOS parameter Block
	.bsBytesPerSec		resw 1				; bytes per sector
	.bsSecPerCluster	resb 1				; sectors per cluster
	.bsResSectors		resw 1				; Reserved sectors
	.bsFATs				resb 1				; number of file allocation tables
	.bsRootDirEnts		resw 1				; number of root directory entries
	.bsSectors			resw 1				; total number of sectors
	.bsMedia			resb 1				; media descriptor
	.bsFATsecs			resw 1				; number of sectors per FAT
	.bsSecPerTrack		resw 1				; sectors per track
	.bsHeads			resw 1				; number of heads
	.bsHiddenSecs		resd 1				; number of hidden sectors
	.bsHugeSectors		resd 1				; number of sectors if bsSectors = 0
											; End of BIOS parameter block
	.bsDriveNumber		resb 1				; drive number (80h)
	.bsReserved1		resb 1				; reserved
	.bsBootSignature	resb 1				; extended Boot signature (29h)
	.bsVolumeID			resd 1				; volume ID number
	.bsVolumeLabel		resb 11				; volume label
	.bsFileSysType		resb 8				; file system type
ENDSTRUC

; Device Parameters for disk drives

STRUC DEVICEPARAMS
	.dpSpecFunc			resb 1			; Special functions
	.dpDevType			resb 1			; device type
	.dpDevAttr			resw 1			; device attributes
	.dpCylinders		resw 1			; number of cylinders
	.dpMediaType		resb 1			; media type
										; Start of BIOS parameter Block
	.bsBytesPerSec		resw 1			; bytes per sector
	.bsSecPerCluster	resb 1			; sectors per cluster
	.bsResSectors		resw 1			; Reserved sectors
	.bsFATs				resb 1			; number of file allocation tables
	.bsRootDirEnts		resw 1			; number of root directory entries
	.bsSectors			resw 1			; total number of sectors
	.bsMedia			resb 1			; media descriptor
	.bsFATsecs			resw 1			; number of sectors per FAT
	.bsSecPerTrack		resw 1			; sectors per track
	.bsHeads			resw 1			; number of heads
	.bsHiddenSecs		resd 1			; number of hidden sectors
	.bsHugeSectors		resd 1			; number of sectors if bsSectors = 0
										; End of BIOS parameter block
ENDSTRUC

; MS-DOS Directory Entry Structure

STRUC DIRENTRY
	.deName			resb 8				; name
	.deExtension	resb 3				; extension
	.deAttributes 	resb 1				; attributes
	.deReserved		resb 10 			; reserved
	.deTime			resw 1				; time
	.deDate			resw 1				; date
	.deStartCluster	resw 1				; starting cluster
	.deFileSize		resd 1				; file size
ENDSTRUC

STRUC DISKIO
	.diStartSector	resd 1		; sector number to start
	.diSectors		resw 1		; number of sectors
	.diBuffer		resd 1		; address of buffer
ENDSTRUC

STRUC DPB
	.dpbDrive			resb 1		; drive number (0=A, 1=B, etc.)
	.dpbUnit			resb 1		; unit number for driver
	.dpbSectorSize		resw 1		; sector size in bytes
	.dpbClusterMask		resb 1		; sectors per cluster - 1
	.dpbClusterShift 	resb 1		; sectors per cluster as a power of 2
	.dpbFirstFAT		resw 1		; first sector containing FAT
	.dpbFATCount		resb 1		; number of FATs
	.dpbRootEntries		resw 1		; number of root-directory entries
	.dpbFirstSector		resw 1		; first sector of first cluster
	.dpbMaxCluster		resw 1		; number of clusters on drive + 1
	.dpbFATSize			resw 1		; number of sectors occupied by FAT
	.dpbDirSector		resw 1		; first sector containing directory
	.dpbDriverAddr		resd 1		; address of device driver
	.dpbMedia			resb 1		; media descriptor
	.dpbFirstAccess		resb 1		; indicates access to the drive
	.dpbNextDPB			resd 1		; address of the next drive parameter block
	.dpbNextFree		resw 1		; last allocated cluster
	.dpbFreeCnt			resw 1		; number of free clusters
ENDSTRUC

STRUC EXTENDEDFCB
	.extSignature		resb 1 		; extended FCB signature (must be 0FFh)
	.extReserved1		resb 5		; reserved bytes
	.extAttribute		resb 1		; attribute byte
									; file control block begins
	.extDriveID			resb 1		; drive number (0 = default, 1 = A, etc)
	.extFileName		resb 8		; filename
	.extExtension		resb 3		; extension
	.extCurBlockNo		resw 1		; current block number
	.extRecSize			resw 1		; record size
	.extFileSize		resb 4		; size of file in bytes
	.extFileDate		resw 1		; date file last modified
	.extFileTime		resw 1		; time file last modified
	.extReserved2		resb 8		; reserved bytes
	.extCurRecNo		resb 1		; current record number
	.extRandomRecNo		resb 4		; random record number
ENDSTRUC

STRUC EXTHEADER
	.ehSignature		resb 1		; extended signature (must be 0FFh)
	.ehReserved			resb 5		; reserved
	.ehSearchAttr		resb 1		; attribute byte
ENDSTRUC

STRUC FCB
	.fcbDriveID			resb 1		; drive number (0 = default, 1 = A, etc)
	.fcbFileName		resb 8		; filename
	.fcbExtension		resb 3		; extension
	.fcbCurBlockNo		resw 1		; current block number
	.fcbRecSize			resw 1		; record size
	.fcbFileSize		resb 4		; size of file in bytes
	.fcbFileDate		resw 1		; date file last modified
	.fcbFileTime		resw 1		; time file last modified
	.fcbReserved		resb 8		; reserved bytes
	.fcbCurRecNo		resb 1		; current record number
	.fcbRandomRecNo		resb 4		; random record number
ENDSTRUC

STRUC FILEINFO
	.fiReserved			resb 21		; Reserved
	.fiAttribute		resb 1		; attributes of file found
	.fiFileTime			resw 1		; time of last write
	.fiFileDate			resw 1 		; date of last write
	.fiSize				resd 1		; file size
	.fiFileName			resb 13		; filename and extension
ENDSTRUC

STRUC FVBLOCK
	.fvSpecFunc			resb 1		; special functions
	.fvHead				resw 1		; head to format/verify
	.fvCylinder			resw 1		; cylinder to format/verify
	.fvTracks			resw 1 		; number of tracks to format/verify
ENDSTRUC

STRUC MID
	.midInfoLevel		resb 1		; information level (must be zero)
	.midSerialNum		resd 1		; serial number
	.midVolLabel		resb 11		; ASCII volume label
	.midFileSysType		resb 8		; file system type
ENDSTRUC

STRUC PARTENTRY
	.peBootable			resb 1		; 80h = bootable, 00h = non-bootable
	.peBeginHead		resb 1		; beginning head
	.peBeginSector		resb 1 		; beginning sector
	.peBeginCylinder	resb 1 		; beginning cylinder
	.peFileSystem		resb 1 		; name of file system
	.peEndHead			resb 1		; ending head
	.peEndSector		resb 1		; ending sector
	.peEndCylinder		resb 1		; ending cylinder
	.peStartSector		resd 1		; starting sector (relative to beginning of disk)
	.peSectors			resd 1 		; number of sectors in partition
ENDSTRUC

; Device parameters for several common formats in MASM format (won't work in NASM)

; SS160	DEVICEPARAMS	<0,1,2,40,0,512,1,1,2, 64, 320,0FEh,1, 8,1,0,0>
; SS180	DEVICEPARAMS	<0,1,2,40,0,512,1,1,2, 64, 360,0FCh,2, 9,1,0,0>
; DD320	DEVICEPARAMS	<0,1,2,40,0,512,2,1,2,112, 640,0FFh,1, 8,2,0,0>
; DD360	DEVICEPARAMS	<0,1,2,40,0,512,2,1,2,112, 720,0FDh,1, 9,2,0,0>
; SH320	DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,112, 640,0FAh,1, 8,1,0,0>
; DH360	DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,112, 720,0FCh,2, 9,1,0,0>
; DH640	DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,112,1280,0FBh,2, 8,2,0,0>
; DH720 DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,112,1440,0F9h,3, 9,2,0,0>
; DH144	DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,224,2880,0F0h,9,18,2,0,0>
; DH120	DEVICEPARAMS	<0,1,2,80,0,512,2,1,2,224,2400,0F0h,7,15,2,0,0>

; File attributes

ATTR_READONLY		db	01h		; read only file
ATTR_HIDDEN			db 	02h		; hidden file
ATTR_SYSTEM			db	04h		; system file
ATTR_VOLUME			db 	08h		; volume label
ATTR_DIRECTORY		db	10h		; directory
ATTR_ARCHIVE		db	20h		; file is new or has been modified

; File sharing modes

OPEN_SHARE_COMPATIBILITY		db	0000h	; Allows programs full access to the file
OPEN_SHARE_DENYREADWRITE		db	0010h	; Prevents other programs from opening the file
OPEN_SHARE_DENYWRITE			db	0020h	; Permits reading the file only (no write access)
OPEN_SHARE_DENYREAD				db	0030h	; Permits writing to the file only (no read access)
OPEN_SHARE_DENYNONE				db	0040h	; File can be opened for read/write, but not compatibility access
