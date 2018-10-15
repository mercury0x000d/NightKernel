%ifndef	__CONFIG_INC__
%define __CONFIG_INC__
;
; NKLOADER assemble-time configuration file
; 

;;
;; Uncomment this if you want debugging information
;; NOTE: the loader program becomes much larger and
;;       screen output becomes much more verbose!
;;
%define	__DEBUG__

;; 
;; Uncomment this if you want external configuration
;; file support (in NKLDR.INI), and pass it onto
;; the kernel via the stack
;;
;%define	__HAVE_CFG_PARSER__

;;
;; Uncomment this if you want module information
;; embedded in the loader file. 
%define	__HAVE_MODULE_INFO__

%endif ; __CONFIG_INC__

;
; EOF
;

