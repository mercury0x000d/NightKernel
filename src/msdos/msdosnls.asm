; NightDOS 
;
;  msdosnls.inc
;
;  MS-DOS structures for internationalization
;
;  10/17/2015			adg		Created
;---------------------------------------------------

; Extended Country Information

STRUCT CODEPAGE
	.cpLength				resw	1 		; structure size excluding this field (always 2)
	.cpID					resw	1		; code page identifier
ENDSTRUC

STRUCT COUNTRYINFO
	.ciDateFormat			resw	1 		; date format
	.ciCurrency				resb	5		; currency symbol (ASCIIZ)
	.ciThousands			resb	2		; thousands separator (ASCIIZ)
	.ciDecimal				resb	2 		; decimal separator (ASCIIZ)
	.ciDateSep				resb	2 		; date separator (ASCIIZ)
	.ciTimeSep				resb	2 		; time separator (ASCIIZ)
	.ciBitField				resb	1 		; currency format
	.ciCurrencyPlaces		resb	1 		; places after decimal point
	.ciTimeFormat			resb	1		; 12- or 24- hour format
	.ciCaseMap				resd	1		; address of case mapping routine
	.ciDataSep				resb	2 		; data-list separator
	.ciReserved				resb	10 		; reserved
ENDSTRUC

STRUCT CPENTRYHEADER
	.cpeLength				resw	1 		; size of this structure in bytes
	.cpeNext				resd	1		; offset to next CPENTRYHEADER
	.cpeDevType				resw	1 		; device type
	.cpeDevSubType			resb	8		; device name and font-file name
	.cpeCodePageID			resw	1		; code-page identifier
	.cpeReserved			resb	6		; reserved
	.cpeOffset				resd	1		; offset to font-data
ENDSTRUC

STRUCT EXTCOUNTRYINFO
	.eciLength				resw 	1		; size of the structure in bytes
	.eciCountryCode			resw	1		; country code
	.eciCodePageID			resw	1 		; code page identifier
	.eciDateFormat			resw	1 		; date format
	.eciCurrency			resb	5		; currency symbol (ASCIIZ)
	.eciThousands			resb	2		; thousands separator (ASCIIZ)
	.eciDecimal				resb	2 		; decimal separator (ASCIIZ)
	.eciDateSep				resb	2 		; date separator (ASCIIZ)
	.eciTimeSep				resb	2 		; time separator (ASCIIZ)
	.eciBitField			resb	1 		; currency format
	.eciCurrencyPlaces		resb	1 		; places after decimal point
	.eciTimeFormat			resb	1		; 12- or 24- hour format
	.eciCaseMap				resd	1		; address of case mapping routine
	.eciDataSep				resb	2 		; data-list separator
	.eciReserved			resb	10 		; reserved
ENDSTRUC
