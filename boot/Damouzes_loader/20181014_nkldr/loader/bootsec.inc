;
; This file contains %defines for each relevant entry in the bootsector.
;
; The loader expects the bootsector to be at 0x0000:0x7c00, which is where
; the BIOS or the MBR would have loaded it.
;
%ifndef	_BOOTSEC_INC_
%define	_BOOTSEC_INC_

%define	oem_name			(0x0003)
%define bytes_per_sector		(0x000b)
%define	sectors_per_cluster		(0x000d)
%define	reserved_sectors		(0x000e)
%define	fat_copies			(0x0010)
%define	root_directory_entries		(0x0011)
%define	total_filesytem_sectors		(0x0013)
%define	media_descriptor		(0x0015)
%define	sectors_per_fat			(0x0016)
%define	sectors_per_track		(0x0018)
%define	head_count			(0x001a)
%define	hidden_sectors			(0x001c)
%define	total_filesystem_sectors2	(0x0020)
%define	logical_drive_num		(0x0024)
%define	reserved			(0x0025)
%define	v4_bpb_signature		(0x0026)
%define	partition_serial_num		(0x0027)
%define	volume_label			(0x002b)
%define	v4_bpb_fstype			(0x0036)
%define	v7_bpb_signature		(0x0042)
%define v7_bpb_fstype			(0x0052)

%define	BPB_OFF				(0x0003)

STRUC v4_bpbp_struc
	.oem_name:			resb	8
	.sectors_per_cluster:		resb	1
	.reserved_sectors:		resw	1
	.fat_copies:			resb	1
	.root_directory_entries:	resw	1
	.total_filesystem_sectors:	resw	1
	.media_descriptor:		resb	1
	.sectors_per_fat:		resw	1
	.sectors_per_track:		resw	1
	.head_count:			resw	1
	.hidden_sectors:		resd	1
	.total_filesystem_sectors2:	resd	1
	.logical_drive_num:		resb	1
	.reserved:			resb	1
	.v4_bpb_signature:		resb	1
	.partition_serial_num:		resd	1
	.volume_label:			resb	11
	.v4_bpb_fstype:			resb	8
	.size:
ENDSTRUC

STRUC v7_bpbp_struc_28
	.oem_name:			resb	8
	.sectors_per_cluster:		resb	1
	.reserved_sectors:		resw	1
	.fat_copies:			resb	1
	.root_directory_entries:	resw	1
	.total_filesystem_sectors:	resw	1
	.media_descriptor:		resb	1
	.sectors_per_fat:		resw	1
	.sectors_per_track:		resw	1
	.head_count:			resw	1
	.hidden_sectors:		resd	1
	.total_filesystem_sectors2:	resd	1
	.sectors_per_fat2:		resd	1
	.mirroring_flags:		resw	1
	.version:			resw	1
	.root_directory_cluster:	resd	1
	.fs_info_sector:		resw	1
	.backup_sector:			resw	1
	.boot_filename:			resb	12
	.logical_drive_num:		resb	1
	.fs_flags:			resb	1
	.extended_boot_signature:	resb	1
	.partition_serial_num:		resb	1
	.size:
ENDSTRUC

STRUC v7_bpbp_struc_29
	.oem_name:			resb	8
	.sectors_per_cluster:		resb	1
	.reserved_sectors:		resw	1
	.fat_copies:			resb	1
	.root_directory_entries:	resw	1
	.total_filesystem_sectors:	resw	1
	.media_descriptor:		resb	1
	.sectors_per_fat:		resw	1
	.sectors_per_track:		resw	1
	.head_count:			resw	1
	.hidden_sectors:		resd	1
	.total_filesystem_sectors2:	resd	1
	.sectors_per_fat2:		resd	1
	.mirroring_flags:		resw	1
	.version:			resw	1
	.root_directory_cluster:	resd	1
	.fs_info_sector:		resw	1
	.backup_sector:			resw	1
	.boot_filename:			resb	12
	.logical_drive_num:		resb	1
	.fs_flags:			resb	1
	.extended_boot_signature:	resb	1
	.partition_serial_num:		resb	1
	.volume_label:			resb	11
	.v7_bpb_fstype:			resb	8
	.size:
ENDSTRUC

%define	DPT_SIZE	0x0b


%endif	; _BOOTSEC_INC_

;
; EOF
;

