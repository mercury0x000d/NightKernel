; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; rtc.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.


%include "include/globals.inc"


; 32-bit function listing:
; RTCAdjustBCD					Adjusts the time values in the tSystem struct from BCD to decimal
; RTCInit						Initializes the RTC
; RTCInterruptHandler			Handles RTC interrupts

global RTCAdjustBCD, RTCInit, RTCInterruptHandler

extern PrintIfConfigBits32, BCDToDecimal


bits 32





section .text
RTCAdjustBCD:
	; Adjusts the time values in the tSystem struct from BCD to decimal
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	mov eax, 0x00000000


	mov al, byte [tSystem.year]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.year], al


	mov al, byte [tSystem.month]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.month], al

	
	mov al, byte [tSystem.day]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.day], al

	
	mov al, byte [tSystem.hours]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.hours], al

	
	mov al, byte [tSystem.minutes]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.minutes], al

	
	mov al, byte [tSystem.seconds]
	push eax
	call BCDToDecimal
	pop eax
	mov byte [tSystem.seconds], al


	mov esp, ebp
	pop ebp
ret





section .text
RTCInit:
	; Initializes the RTC
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; The trouble with the RTC is that it may have its data formatted in a couple different ways.
	; We get Status Register B here and save it for later so we can handle the formatting
	; appropriately at that time without having to wait on the RTC to cough up the data.
	; We don't have to disable normal interrupts here (they should be already disabled upon entry) however
	; we do need to prevent NMIs, so here we turn off NMIs and select Status Regsiter B, all at once.
	mov al, 0x8B
	out 0x70, al
	in al, 0x71


	; Next, we can go ahead and activate the Update Enable interrupt so that the RTC will notify us every time
	; it completes an update of the time registers. This should occur once per second and when it happens, our
	; interrupt handler will copy the time data out of the RTC and into the tSystem structure so that applications
	; may access the current time instantly without the added clumsiness of working around the RTC updates.
	or al, 00010000b
	mov byte [tSystem.RTCStatusRegisterB], al


	; see which hour mode is in use
	test al, 00000010b
	jnz .Using24
		; if we get here, 12 hour mode is being used; let's tell the user if appropriate
		push .notification12Hour$
		jmp .DisplayTimeMode
	.Using24:


	; if we get here, 24 hour mode is being used; again, tell the user if appropriate
	push .notification24Hour$


	.DisplayTimeMode:
	call PrintIfConfigBits32


	; see if we're using binary format
	test byte [tSystem.RTCStatusRegisterB], 00000100b
	jnz .BinaryMode
		; if we get here, BCD mode is being used; tell the user if appropriate
		push .notificationBCDMode$
		jmp .DisplayNumberFormat
	.BinaryMode:

	push .notificationBinaryMode$
		; if we get here, binary mode is being used; tell the user if appropriate

	.DisplayNumberFormat:
	call PrintIfConfigBits32


	; select the index again since the read we did a moment ago will likely have reset it
	mov al, 0x8B
	out 0x70, al

	; write the new value (original + our change) to the SRB
	mov al, byte [tSystem.RTCStatusRegisterB]
	out 0x71, al


	mov esp, ebp
	pop ebp
ret

section .data
.notification12Hour$							db 'RTC is using 12 hour time', 0x00
.notification24Hour$							db 'RTC is using 24 hour time', 0x00
.notificationBCDMode$							db 'RTC format is BCD', 0x00
.notificationBinaryMode$						db 'RTC format is Binary', 0x00





section .text
RTCInterruptHandler:
	; Handles RTC interrupts
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; save everything before we go mucking about!
	pusha


	; now grab the time values from the RTC:

	; get the year
	mov al, 0x09
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.year], al
	
	; get the month
	mov al, 0x08
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.month], al
	
	; get the day
	mov al, 0x07
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.day], al
	
	; get the hour
	mov al, 0x04
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.hours], al
	
	; get the minutes
	mov al, 0x02
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.minutes], al
	
	; get the seconds
	mov al, 0x00
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.seconds], al


	; see which hour mode is in use
	mov al, byte [tSystem.RTCStatusRegisterB]
	test al, 00000010b
	jnz .Using24
		; if we get here, 12 hour mode is being used so we adjust the values accordingly

		; first, we see if bit 7 is set, which is used to signify PM
		mov al, byte [tSystem.hours]
		test al, 10000000b
		jz .NotPM
			; if we get here, the PM bit was set
			and al, 01111111b

			; now adjust to 24 hour since that's all the kernel uses internally
			; see if we're using binary format
			test byte [tSystem.RTCStatusRegisterB], 00000100b
			jnz .BinaryHourAdjust

				; if we get here, BCD mode is being used, so we do the comparison in BCD
				cmp al, 0x12
				je .ModificationsComplete

				; if we get here, we need to adjust to 24 hour time using BCD
				add al, 0x12
				jmp .ModificationsComplete

			.BinaryHourAdjust:
			; if we get here, binary mode is being used, so we do the comparison in binary
			cmp al, 12
			je .ModificationsComplete

			; if we get here, we need to adjust to 24 hour time using binary
			add al, 12
			jmp .ModificationsComplete

		.NotPM:
		; see if the hour is 12 or 0x12 and zero it
		cmp al, 12
		je .AdjustAM

		cmp al, 0x12
		je .AdjustAM

		jmp .ModificationsComplete

		.AdjustAM:
		mov al, 0

		.ModificationsComplete:

		; and finally, write the modified value back to the tSystem struct
		mov byte [tSystem.hours], al
	.Using24:
	; if we get here, 24 hour mode is being used, so no adjustment is needed



	; see if we're using binary format and set the appropriate handler address
	test byte [tSystem.RTCStatusRegisterB], 00000100b
	jnz .UsingBinary
		; if we get here, BCD mode is being used so we adjust the values accordingly
		call RTCAdjustBCD
	.UsingBinary:
	; if we get here, Binary mode is being used, so no adjustment is needed



	; Read Status Register C to tell the RTC we're good for another interrupt.
	; We don't need to actually parse the result of this to see which of the three possible RTC interrupt
	; types it was that just fired since we know we only have one of them enabled anyway.
	mov al, 0x0C
	out 0x70, al
	in al, 0x71


	mov esp, ebp
	pop ebp
ret