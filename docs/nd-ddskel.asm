; Device Driver Skeleton - native driver for Night Kernel
; <copyright message>
; <driver name> is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 16-bit function listing:



; 32-bit function listing:



bits 32



; defines go here



; the generic name is "DriverHeader" but you will need to change this to something completely unique to your specific driver
; to avoid conflicts
DriverHeader:

; this is the magic string for which the kernel will search to discover us
.signature$										db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05

; these values 
.classMatch										dd 0x00000001
.subclassMatch									dd 0x00000001
.progIfMatch									dd 0x0000FFFF

; a set of flags to identify what kind of driver this is
; currently, the following bit definitions are supported:
; 00											supports character device interface
; 01											supports block device interface
; 31											legacy driver
.driverFlags									dd 00000000000000000000000000000000b

; pointers to the read and write functions to be called from outside the driver
.ReadCodePointer								dd 0x00000000
.WriteCodePointer								dd 0x00000000

; additional driver functions

.ProbeDevice									dd 0x00000000 ; Called to query the existence of a device and driver compatibility
.Remove											dd 0x00000000 ; Called when device is removed
.Online											dd 0x00000000 ; Called to put the device online (after offlining it)
.Offline										dd 0x00000000 ; Called to put the device offline for removal (may fail)
.Suspend										dd 0x00000000 ; Called when a device wants to go to sleep mode
.Resume											dd 0x00000000 ; Called to bring the device out of sleep mode


; due to the nature of the Night driver detection model, the driver init code must directly follow the header
C01Init:
	; Performs any necessary setup of the driver
	;
	;  input:
	;   PCI Bus
	;   PCI Device
	;   PCI Function
	;   config info
	;
	;  output:
	;   driver response

	push ebp
	mov ebp, esp

	; announce ourselves!
	push .driverIntro$
	call PrintIfConfigBits32

	; see what the config info says and configure ourselves accordingly
	; this particular driver has no configurable options, so it's safe to ignore this data
	mov edx, [ebp + 20]

	; next we write the driverFlags based on how we're configured
	; again, since this isn't a configurable driver, we don't have to do anything
	; too special here, just set bit one to signify it's a block driver
	mov dword [Class01DriverHeader.driverFlags], 00000000000000000000000000000010b

	; set up our function pointers
	mov dword [Class01DriverHeader.ReadCodePointer], <read handler address>
	mov dword [Class01DriverHeader.WriteCodePointer], <write handler address>

	; commandeer any necessary interrupt handlers here
	push 0x8e
	push C01InterruptHandlerPrimary
	push 0x08
	push <interrupt number>
	call InterruptHandlerSet


	; do other driver-y stuff here


	; exit with return status
	mov eax, 0x00000000
	mov dword [ebp + 20], eax

	mov esp, ebp
	pop ebp
ret 12
.driverIntro$									db 'your driver name goes here', 0x00
