%ifndef	__CFG_PARSER__
%define	__CFG_PARTSR__

;
; Parse the configuration file
;
; In:		ES:BX -> configuration file buffer
; Return:	Nothing
;
; This function parses the configuration file and sets
; up the list of modules
;
; For now the configuration file consists of modules to load
; in the form:
; module = <modulename>
; 
; Subdirectories are not supported (yet)
;
parse_configuration:
	ret


tok_module:		db	MODULE_TOKEN, 0
tok_cmdline:		db	CMDLINE_TOKEN, 0

tok_table:		dw	tok_module
			dw	tok_cmdline
			dw	0
kcfg_filename:
			db	KCFG_FILENAME, 0

cfgdata_off:		dw	0x0000
cfgdata_seg:		dw	0x0000

%endif ; __CFG_PARSER__

;
; EOF
;

