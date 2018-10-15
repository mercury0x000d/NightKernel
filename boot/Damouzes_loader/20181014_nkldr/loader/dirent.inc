;
; This file containes %deifines for each relevant entry in a directory
; entry.
;
%ifndef	__DIRENT_INC__
%define	__DIRENT_INC__

%define	d_name				(0x0000)
%define d_ext				(0x0008)
%define	d_attr				(0x000b)
%define	d_usrattr			(0x000c)
%define	d_ctimems			(0x000d)
%define	d_ctime				(0x000e)
%define	d_cdate				(0x0010)
%define	d_adate				(0x0012)
%define	d_startclusterhi		(0x0014)
%define	d_mtime				(0x0016)
%define	d_mdate				(0x0018)
%define	d_startcluster			(0x001a)
%define	d_size				(0x001c)

%endif ; __DIRENT_INC__

;
; EOF
;

