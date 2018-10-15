%ifndef	__CFG_DATA_INC__
%define	__CFG_DATA_INC__

STRUC	cfg_data_struc
	.signature:	resd	1	;	Config data signature
	.flags1:	resw	1	;	Loader flags word 1
	.flags2:	resw	1	;	Loader flags word 2
	.modlist_head:	resd	1	;	Pointer to start of module chain
	.cmd_line:	resd	1	;	Pointer to kernel command line
	.len:		resw	1	;	Length of this structure in bytes
	.ramsize:	resw	1	;	Size of conventional memory in kB
	.boot_drive:	resb	1	;	Boot drive number
	.probe_byte:	resb	1	;	Filessystem probe byte
	.size:
ENDSTRUC

%define	CFGDATA_SIGNATURE	0x24474643

%define	MODULE_TOKEN		'device'
%define	CMDLINE_TOKEN		'cmdline'

%define	KCFG_FILENAME		'NKLDR   INI'

%endif ; __CFG_DATA_INC__

;
; EOF
;
