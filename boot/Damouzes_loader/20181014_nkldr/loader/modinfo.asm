%ifndef	__MODINFO_ASM__
%define	__MODINFO_ASM__

align 16
device_hdr	ISTRUC	device_hdr_struc
	AT device_hdr_struc.nextptr,		dd	0xffffffff
	AT device_hdr_struc.flags,		dw	DEVFLAG_CHAR|DEVFLAG_PRELOAD|DEVFLAG_EXTHDR
	AT device_hdr_struc.strat_method,	dw	strategy
	AT device_hdr_struc.int_method,		dw	interrupt
	AT device_hdr_struc.shortname,		db	'NKLOADER'
	AT device_hdr_struc.signature,		dd	DEVICE_SIGNATURE
	AT device_hdr_struc.strat_method32,	dd	0
	AT device_hdr_struc.int_method32,	dd	0
	AT device_hdr_struc.infoptr,		dd	device_info
	AT device_hdr_struc.xflags,		dd	0
	AT device_hdr_struc.longname,		db	'NKLOADER', 0
IEND

;
; Device info structure
;
device_info	ISTRUC	device_info_struc
	AT device_info_struc.descptr,		dd	description_str
	AT device_info_struc.authptr,		dd	author_str
	AT device_info_struc.licenseptr,	dd	license_str
	AT device_info_struc.ver_major,		db	2
	AT device_info_struc.ver_minor,		db	0
	AT device_info_struc.ver_release,	dw	10
IEND

description_str:	db	'NightDOS Kernel loader', 0
author_str:		db	'Desert Mouse', 0
license_str:		db	'GPL 3.0+', 0

strategy:
	retf

interrupt:
	retf

%endif ; __MODINFO_ASM__

;
; EOF
;

