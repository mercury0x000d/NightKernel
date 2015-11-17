; NightDOS 
;
;  msdosint.inc
;
;  MS-DOS structures
;
;  10/17/2015			adg		Created
;---------------------------------------------------

; Interrupt Definitions for MS/PC-DOS

INTTABLE	EQU	20h

IntTermProcess 			EQU	INTTABLE				;	Terminate Process
IntDOSCalls				EQU	IntTermProcess + 1		;	DOS Calls
IntTerminateAddress		EQU IntDOSCalls + 1			; 	Termination Address
IntCtrlCHandler			EQU	IntTerminateAddress + 1	; 	Ctrl+C Handler
IntCritErrorHandler		EQU	IntCtrlCHandler + 1		; 	Critical Error Handler
IntAbsDiskRead			EQU	IntCritErrorHandler + 1	;	Absolute Disk Read
IntAbsDiskWrite			EQU	IntAbsDiskRead + 1		; 	Absolute Disk Write
IntKeep					EQU	IntAbsDiskWrite + 1		; 	Terminate and Stay Resident
IntIdleHandler			EQU IntKeep + 1 			;	MS-DOS Idle Handler
IntFastConsole			EQU	IntIdleHandler + 1 		;	Fast console routines
IntNetworkCritical		EQU IntFastConsole + 1 		;	Network/Critical Section
IntReloadTransient		EQU	IntTermProcess + 0Eh	; 	Reload transient (used by COMMAND.COM)
IntMultiPlex			EQU IntReloadTransient + 1	;	Multiplex interrupt