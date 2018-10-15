%ifndef	__DEVICE_INC__
%define	__DEVICE_INC__

%define	DEVICE_SIGNATURE	0x4f5f6465

%define	DEVFLAG_CHAR		0x8000				; Set if char device, not if block device
%define	DEVFLAG_IOCTL		0x4000				; Set if IOCTL supported
%define	DEVFLAG_OUTPUTBUSY	0x2000				; Set if output-until-busy is supported (char device)
%define DEVFLAG_NONIBM		(DEVFLAG_OUTPUTBUSY)		; Set if non-IBM (char device)
%define	DEVFLAG_32BIT		0x1000				; Set if 32-bit (an extended device header is assumed)
%define DEVFLAG_REMOVABLE	0x0800				; Set if removable device
%define	DEVFLAG_EXTHDR		0x0080				; Set if extended header is present
%define	DEVFLAG_PRELOAD		0x0040				; Set if device must be initialized before all others*
%define	DEVFLAG_ISSTDERR	0x0020				; Set if stderr
%define	DEVFLAG_ISCON		0x0010				; Set if console device
%define	DEVFLAG_ISCLOCK		0x0008				; Set if clock device
%define	DEVFLAG_ISNUL		0x0004				; Set if nul device
%define	DEVFLAG_ISSTDOUT	0x0002				; Set if stdout
%define	DEVFLAG_ISSTDIN		0x0001				; Set if stdin

; Request numbers reflect those in DOS 2.0 or above
%define	DVREQ_INIT		0
%define	DVREQ_MEDIA_CHECK	1
%define	DVREQ_BUILD_BPB		2
%define	DVREQ_IOCTL_IN		3
%define	DVREQ_INPUT		4
%define	DVREQ_INOUT_NOWAIT	5
%define	DVREQ_INPUT_STATUS	6
%define	DVREQ_INPUT_FLUSH	7
%define	DVREQ_OUTPUT		8
%define	DVREQ_OUTPUT_VERIFY	9
%define	DVREQ_OUTPUT_STATUS	10
%define	DVREQ_OUTPUT_FLUSH	11
%define	DVREQ_IOCTL_OUT		12

;
; Definition of the device header structure.
;
; The loader loads each device driver into its own 16-bit segment. It is up to
; an actual 32-bit kernel to build the 32-bit device chain, as well as fix up
; the method & info record pointers if necessary. Each of these pointers are
; either 16 or 32 bit pointers, depending on bit DEVFLAG_16BIT in the device flags
;
; The loader builds the 16-bit device chain throug the .nextptr16 pointers in each
; device header.
;
; If a device driver has both the DEVFLAG_16BIT and the DEVFLAG_PRELOAD, the loader
; will attempt to call the initialization routine through the interrupt method. If a device
; driver does not require initialization by the loader, the initialization should fail
; silently, allowing the 16-bit portion of the kernel to re-attempt it.
;
; Regardless of whether the device driver is 16-bit or 32-bit, the various pointers
; not explicitly suffixed with 16 or 32, should be treated as offsets into the segment
; of the device driver.
;
; The device header structure is 64 bytes long and is preferably at the
; start of the segment, but does not need to be. 
;
STRUC device_hdr_struc
	; MS-DOS compatible device header starts here
	.nextptr:		resd	1	;	Pointer to next device (either 16 or 32-bit pointer)
	.flags:			resw	1	;	Device flags
	.strat_method:		resw	1	;	Pointer to strategy method (16-bit offset from segment start)
	.int_method:		resw	1	;	Pointer to interrupt method (16-bit offset from segment start)
	.shortname:		resb	8	;	Short device name if char device, otherwise byte 0 contains # units
	.size_dos:
						; 	followed by 7 nul bytes.

	; Extended device header starts here
	.signature:		resd	1	;	Signature word (0x4d5f6465)
	.strat_method32:	resd	1	;	32-bit strategy method (32-bit offset from segment start)
	.int_method32:		resd	1	;	32-bit interrupt method (32-bit offset from segment start)
	.infoptr:		resd	1	;	Pointer to info record (either 16 or 32-bit pointer)
	.xflags:		resd	1	;	Extended device flags
	.longname:		resb	28	;	Long device name
	.size_ext:
ENDSTRUC

STRUC	device_info_struc
	.descptr:	resd	1	;	Pointer to description string
	.authptr:	resd	1	;	Pointer to author string
	.licenseptr:	resd	1	;	Pointer to license string
	.ver_major:	resb	1	;	Major version
	.ver_minor:	resb	1	;	Minor version
	.ver_release:	resw	1	;	Release
	.size:
ENDSTRUC

STRUC	device_init_request_struc
	.lor:		resd	1	;	Length of record in bytes
	.unit:		resb	1	;	Unit code
	.cmd:		resb	1	;	Command code
	.status:	resw	1	;	Status code
	.dosqlink:	resd	1	;	DOS queue link
	.devqlink:	resd	1	;	Device queue link
	.numunits:	resb	1	;	Number of units (set by driver)
	.brkptr:	resd	1	;	Break address (set by driver)
	.size:				;	Size of request structure
ENDSTRUC

%endif ; __DEVICE_INC__

;
; EOF
;

