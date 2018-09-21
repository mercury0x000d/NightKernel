;
; This file contains %defines for each relevant entry in the bootsector.
;
; The loader expects the bootsector to be at 0x0000:0x7c00, which is where
; the BIOS or the MBR would have loaded it.
;
%ifndef	_BOOTSEC_INC_
%define	_BOOTSEC_INC_

%define	BS_SEG				0x0000
%define	BS_START			0x0000
%define	oem_name			(BS_START + 0x0003)
%define bytes_per_sector		(BS_START + 0x000b)
%define	sectors_per_cluster		(BS_START + 0x000d)
%define	reserved_sectors		(BS_START + 0x000e)
%define	fat_copies			(BS_START + 0x0010)
%define	root_directory_entries		(BS_START + 0x0011)
%define	total_filesytem_sectors		(BS_START + 0x0013)
%define	media_descriptor		(BS_START + 0x0015)
%define	sectors_per_fat			(BS_START + 0x0016)
%define	sectors_per_track		(BS_START + 0x0018)
%define	head_count			(BS_START + 0x001a)
%define	hidden_sectors			(BS_START + 0x001c)
%define	total_filesystem_sectors2	(BS_START + 0x0020)
%define	logical_drive_num		(BS_START + 0x0024)
%define	reserved			(BS_START + 0x0025)
%define	extended_signature		(BS_START + 0x0026)
%define	partition_serial_num		(BS_START + 0x0027)
%define	volume_label			(BS_START + 0x002b)
%define	fs_type				(BS_START + 0x0036)

%endif	; _BOOTSEC_INC_

;
; EOF
;

