; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
; ATA Controller.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 32-bit function listing:
; C01Init						Performs any necessary setup of the driver
; C01ATAPISectorReadPIO
; C01ATASectorReadLBA28			Reads sectors from disk using LBA28
; C01ATASectorWriteLBA28		Writes sectors to disk using LBA28
; C01DetectChannelDevices		Checks both of the device spots on the ATA channel specified and saves their data to the drives list
; C01DriveIdentify				Returns identifying information about the device specified
; C01InterruptHandlerPrimary	Interrupt handler for ATA interrupts
; C01InterruptHandlerSecondary	Interrupt handler for ATA interrupts
; C01WaitForReady				Waits for bit 7 of the passed port value to go clear, then returns
; InternalDriveFoundPrint		Prints data about the drive discovered by C01DriveIdentify()



bits 32



; defines
%define kATAChannelPrimary						0x00
%define kATAChannelSecondary					0x01

%define kATACommandReadPIO						0x20
%define kATACommandReadPIOExt					0x24
%define kATACommandReadDMAExt					0x25
%define kATACommandWritePIO						0x30
%define kATACommandWritePIOExt					0x34
%define kATACommandWriteDMAExt					0x35
%define	kATACommandRead_Verify					0x40
%define	kATACommandDoDiagnostics				0x90
%define kATACommandPacket						0xA0
%define kATACommandIdentifyPacket				0xA1
%define kATACommandReadDMA						0xC8
%define kATACommandWriteDMA						0xCA
%define	kATACommandStandbyImmediate				0xE0
%define	kATACommandIdleImmediate				0xE1
%define	kATACommandStandby						0xE2
%define	kATACommandIdle							0xE3
%define	kATACommandCheckPowerMode				0xE5
%define	kATACommandSetSleepMode					0xE6
%define kATACommandCacheFlush					0xE7
%define kATACommandCacheFlushExt				0xEA
%define kATACommandIdentify						0xEC

%define kATADirectionRead						0x00
%define kATADirectionWrite						0x01

%define kATAErrorNoAddressMark					0x01
%define kATAErrorTrackZeroNotFound				0x02
%define kATAErrorCommandAborted					0x04
%define kATAErrorMediaChangeRequest				0x08
%define kATAErrorIDMarkNotFound					0x10
%define kATAErrorMediaChanged					0x20
%define kATAErrorUncorrectableData				0x40
%define kATAErrorBadBlock						0x80

%define kATARegisterData						0x00	; read/write
%define kATARegisterError						0x01	; read only
%define kATARegisterFeatures					0x01	; write only
%define kATARegisterSecCount0					0x02	; read/write
%define kATARegisterLBA0						0x03	; read/write
%define kATARegisterLBA1						0x04	; read/write
%define kATARegisterLBA2						0x05	; read/write
%define kATARegisterLBA3						0x03	; read/write?
%define kATARegisterLBA4						0x04	; read/write?
%define kATARegisterLBA5						0x05	; read/write?
%define kATARegisterHDDevSel					0x06	; read/write
%define kATARegisterCommand						0x07	; write only
%define kATARegisterStatus						0x07	; read only
%define kATARegisterSecCount1					0x08	; read/write?
%define kATARegisterControl						0x0C	; write only
%define kATARegisterAltStatus					0x0C	; read only
%define kATARegisterDeviceAddress				0x0D	; ?

%define	kATAResultOK							0x00
%define	kATAResultNoDrive						0x01
%define	kATAResultError							0x02
%define	kATAResultTimeout						0x03

%define kATAStatusError							0x01
%define kATAStatusIndex							0x02
%define kATAStatusCorrectedData					0x04
%define kATAStatusDataRequestReady				0x08
%define kATAStatusDriveSeekComplete				0x10
%define kATAStatusDriveWriteFault				0x20
%define kATAStatusDriveReady					0x40
%define kATAStatusBusy							0x80



Class01DriverHeader:
.signature$										db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05
.driverFlags									dd 00100000000000000000000000000000b

; PCI-based fields specific to this type of driver
.classMatch										dd 0x00000001
.subclassMatch									dd 0x00000001
.progIfMatch									dd 0x0000FFFF
.ReadFunctionPointer							dd 0x00000000
.WriteFunctionPointer							dd 0x00000000



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
	;mov dword [Class01DriverHeader.driverFlags], 0x00000001

	; set up our function pointers
	mov dword [Class01DriverHeader.ReadFunctionPointer], C01ATASectorReadLBA28PIO
	mov dword [Class01DriverHeader.WriteFunctionPointer], C01ATASectorWriteLBA28PIO

	; commandeer the apropriate interrupt handler addresses
	push 0x8e
	push C01InterruptHandlerPrimary
	push 0x08
	push 0x2E
	call InterruptHandlerSet

	push 0x8e
	push C01InterruptHandlerSecondary
	push 0x08
	push 0x2F
	call InterruptHandlerSet

	; get the I/O ports for the drives from the PCI space and adjust them if needed
	; get BAR1 for this device to find the primary channel control port
	push dword 0x00000005
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCIReadDWord
	pop eax

	; if the value returned was zero, it should actually be 0x03F6
	cmp ax, 0
	jne .SkipAdjust2
	mov ax, 0x03F6
	.SkipAdjust2:
	push eax

	; get BAR0 for this device to find the primary channel IO port
	push dword 0x00000004
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCIReadDWord
	pop eax

	; if the value returned was zero, it should actually be 0x01F0
	cmp ax, 0
	jne .SkipAdjust1
	mov ax, 0x01F0
	.SkipAdjust1:
	push eax

	call C01DetectChannelDevices

	; get BAR3 for this device to find the secondary channel control port
	push dword 0x00000007
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCIReadDWord
	pop eax

	; if the value returned was zero, it should actually be 0x0376
	cmp ax, 0
	jne .SkipAdjust4
	mov ax, 0x0376
	.SkipAdjust4:
	push eax

	; get BAR2 for this device to find the secondary channel IO port
	push dword 0x00000006
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCIReadDWord
	pop eax

	; if the value returned was zero, it should actually be 0x0170
	cmp ax, 0
	jne .SkipAdjust3
	mov ax, 0x0170
	.SkipAdjust3:
	push eax

	call C01DetectChannelDevices

	; detect partitions


	; exit with return status
	mov eax, 0x00000000
	mov dword [ebp + 20], eax

	mov esp, ebp
	pop ebp
ret 12
.driverIntro$									db 'General Class 01 Storage Driver, 2018 by mercury0x0d', 0x00



C01ATAPISectorReadPIO:
	; Reads sectors from an ATAPI device
	;
	;  input:
	;	I/O base port
	;	device number (0 or 1)
	;   LBA address of starting sector
	;	number of sectors to write
	;	memory buffer address to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ebx, [ebp + 8]
	mov eax, [ebp + 12]
	mov edi, [ebp + 24]

	; make sure eax is in range
	cmp eax, 2
	jb .InRange

		; if we get here, it wasn't in range!
		mov ebp, 0xDEAD0204
		jmp $

	.InRange:
	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl eax, 4
	add eax, 0xE0

	; choose the drive in LBA mode
	mov dx, bx
	add dx, kATARegisterHDDevSel
	out dx, al

	; wait for the drive to be ready
	mov dx, bx
	add dx, kATARegisterStatus
	push edx
	call C01WaitForReady

	; set PIO mode
	mov dx, bx
	add dx, kATARegisterFeatures
	mov al, 0
	out dx, al

	; send maximum number of bytes we want back
	; seems to not matter, since the device will send back the number of sectors specified anyway
	mov dx, bx
	add dx, kATARegisterLBA1
	mov al, 0x00;lower byte of the value "512"
	out dx, al

	mov dx, bx
	add dx, kATARegisterLBA2
	mov al, 0x02;upper byte of the value "512"
	out dx, al

	; send the packet command
	mov dx, bx
	add dx, kATARegisterCommand
	mov al, kATACommandPacket
	out dx, al

	; wait for the drive to be ready
	mov dx, bx
	add dx, kATARegisterStatus
	push edx
	call C01WaitForReady

	; set the interrupt handler to something useful
	push edi
	push ebx
	push eax
	push 0x8e
	push .ATAPISectorRead
	push 0x08
	push 0x2F
	call InterruptHandlerSet
	pop eax
	pop ebx
	pop edi

	; send the packet command
	mov dx, bx
	add dx, kATARegisterData
	mov ax, 0x00A8
	out dx, ax

	; send the LBA value
	mov dx, bx
	add dx, kATARegisterData
	mov eax, [ebp + 16]
	shr eax, 16
	xchg ah, al
	out dx, ax

	mov dx, bx
	add dx, kATARegisterData
	mov eax, [ebp + 16]
	xchg ah, al
	out dx, ax

	; send the sector count
	mov dx, bx
	add dx, kATARegisterData
	mov eax, [ebp + 20]
	shr eax, 16
	xchg ah, al
	out dx, ax

	mov dx, bx
	add dx, kATARegisterData
	mov eax, [ebp + 20]
	xchg ah, al
	out dx, ax

	; the last segment isn't used by this driver... for now
	mov dx, bx
	add dx, kATARegisterData
	mov ax, 0x0000
	out dx, ax

	; wait for the drive to fire the interrupt
	; later this will be expanded to allow the driver code to pass control back to the caller and
	; handle this request on its own in the background via interrupt while other things happen
	hlt

	; restore the default handler
	push 0x8e
	push C01InterruptHandlerSecondary
	push 0x08
	push 0x2F
	call InterruptHandlerSet

	mov esp, ebp
	pop ebp
ret 20

.ATAPISectorRead:
	; used internally as an interrupt handler by the driver
	pusha
	pushf

	; read 2KiB of returned data
	; this will need modified later to check the sector size and act accordingly instead of assuming 2 KiB sectors
	mov dx, bx
	add dx, kATARegisterData
	mov ecx, 1024
	.ReadLoop:
		in ax, dx
		mov [edi], ax
		add edi, 2
	loop .ReadLoop

	; acknowledge the interrupt at the PIC
	call PICIntComplete
	
	; acknowledge the interrupt at the ATA device by reading the status register
	mov dx, bx
	add dx, kATARegisterStatus
	in al, dx

	popf
	popa
iretd



C01ATASectorReadLBA28PIO:
	; Reads sectors from disk using LBA28 in PIO mode
	;
	;  input:
	;	I/O base port
	;	device number (0 or 1)
	;   LBA address of starting sector
	;	number of sectors to write
	;	memory buffer address to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; mask off starting sector to give us 28 bits
	and dword [ebp + 16], 0x0FFFFFFF

	; make sure the device number is in range
	mov ecx, dword [ebp + 12]
	cmp ecx, 2
	jb .InRange

		; if we get here, it wasn't in range!
		mov ebp, 0xDEAD0202
		jmp $

	.InRange:
	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl ecx, 4
	add ecx, 0xE0

	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]

	; select device and bits 24:27 of the LBA address
	add edx, kATARegisterHDDevSel

	; move bits 24:27 of the LBA address into al
	shr eax, 24

	; perform a logical or to properly set the selected device
	or al, cl
	out dx, al

	; set sector count
	mov edx, dword [ebp + 8]
	add edx, kATARegisterSecCount0
	mov ecx, dword [ebp + 20]
	mov al, cl
	out dx, al

	; set bits 0:7 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA0
	out dx, al

	; set bit 8:15 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA1
	shr eax, 8
	out dx, al

	; set bits 16:23 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA2
	shr eax, 16
	out dx, al

	; and finally, execute the command!
	mov edx, dword [ebp + 8]
	add edx, kATARegisterCommand
	mov al, kATACommandReadPIO
	out dx, al

	; wait for the device to respond
	push edx
	call C01WaitForReady

	; set up a loop to read the sectors
	; add code here later to determine sector size from the drive data and modify this loop accordingly
	mov ecx, dword [ebp + 20]
	shl ecx, 8
	mov edx, dword [ebp + 8]
	mov edi, dword [ebp + 24]
	rep insw

	mov esp, ebp
	pop ebp
ret 20



C01ATASectorWriteLBA28PIO:
	; Writes sectors to disk using LBA28 in PIO mode
	;
	;  input:
	;	I/O base port
	;	device number (0 or 1)
	;   LBA address of starting sector
	;	number of sectors to write
	;	memory buffer address to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; mask off starting sector to give us 28 bits
	and dword [ebp + 16], 0x0FFFFFFF

	; make sure the device number is in range
	mov ecx, dword [ebp + 12]
	cmp ecx, 2
	jb .InRange

	; if we get here, it wasn't in range!
	mov ebp, 0xDEAD0203
	jmp $

	.InRange:
	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl ecx, 4
	add ecx, 0xE0

	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	; select device and bits 24:27 of the LBA address

	add edx, kATARegisterHDDevSel

	; move bits 24:27 of the LBA address into al
	shr eax, 24

	; perform a logical or to properly set the selected device
	or al, cl
	out dx, al

	; set sector count
	mov edx, dword [ebp + 8]
	add edx, kATARegisterSecCount0
	mov ecx, dword [ebp + 20]
	mov al, cl
	out dx, al

	; set bits 0:7 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA0
	out dx, al

	; set bit 8:15 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA1
	shr eax, 8
	out dx, al

	; set bits 16:23 of the LBA address
	mov eax, dword [ebp + 16]
	mov edx, dword [ebp + 8]
	add edx, kATARegisterLBA2
	shr eax, 16
	out dx, al

	; and finally, execute the command!
	mov edx, dword [ebp + 8]
	add edx, kATARegisterCommand
	mov al, kATACommandWritePIO
	out dx, al

	; wait for the device to respond
	push edx
	call C01WaitForReady

	; set up a loop to read 256 words (a.k.a. one 512-byte sector)
	; add code here later to determine sector size from the drive data and modify this loop accordingly
	mov ecx, dword [ebp + 20]
	shl ecx, 8
	mov edx, dword [ebp + 8]
	mov esi, dword [ebp + 24]
	rep outsw

	; clear out the cache
	mov edx, dword [ebp + 8]
	add edx, kATARegisterCommand
	mov al, kATACommandCacheFlush
	out dx, al

	; wait for the device to be ready
	push edx
	call C01WaitForReady

	mov esp, ebp
	pop ebp
ret 20



C01DetectChannelDevices:
	; Checks both of the device spots on the ATA channel specified and saves their data to the drives list
	;
	;  input:
	;   I/O base port
	;   control base port
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp
	sub esp, 4									; dataBlock (pointer to 512 byte buffer used by identify function)

	; allocate a sector's worth of RAM
	; add code here to determine the sector size first, then allocate
	push 512
	call MemAllocate
	pop dword [ebp - 4]

	; now we probe all the drive slots to see what's there
	; check primary channel drive 0
	push 0
	xor ecx, ecx
	mov cx, word [ebp + 8]
	push ecx
	push dword [ebp - 4]
	call C01DriveIdentify
	pop eax

	; see if the drive existed
	cmp eax, 0xFF
	je .SkipDevice0

		; add the device data to the drives list
		; preserve the drive type (eax) for later
		push eax

		; get first free slot
		push dword [tSystem.listDrives]
		call LMListFindFirstFreeSlot
		pop eax

		; get the address of that slot into esi
		push eax
		push dword [tSystem.listDrives]
		call LMItemGetAddress
		pop esi

		; save base port and device number to table
		xor ecx, ecx
		mov cx, word [ebp + 8]
		mov dword [tDriveInfo.ATABasePort], ecx
		mov dword [tDriveInfo.ATADeviceNumber], 0

		; save device type to table
		pop eax
		mov dword [tDriveInfo.deviceFlags], eax

		; fill in read and write addresses
		cmp eax, 1
		jne .Device0NotPATA
			; if we get here, the drive type is PATA, so we set the appropriate values
			mov dword [tDriveInfo.readSector], C01ATASectorReadLBA28PIO
			mov dword [tDriveInfo.writeSector], C01ATASectorWriteLBA28PIO

		.Device0NotPATA:
		cmp eax, 3
		jne .Device0NotATAPI
			; if we get here, the drive type is ATAPI, so we set the appropriate values
			mov dword [tDriveInfo.readSector], C01ATAPISectorReadPIO
		.Device0NotATAPI:

		; allocate 1 MiB cache for this drive and save the address
		push 1048576
		call MemAllocate
		pop dword [tDriveInfo.cacheAddress]

		; save esi
		push esi

		; fill in model
		push 40
		mov edi, esi
		add edi, 24
		push edi
		mov edi, dword [ebp - 4]
		add edi, 54
		push edi
		call MemCopy

		; restore esi
		pop esi

		; fill in serial
		push 20
		mov edi, esi
		add edi, 88
		push edi
		mov edi, dword [ebp - 4]
		add edi, 20
		push edi
		call MemCopy

		; print what we've found
		push eax
		push 0
		xor ecx, ecx
		mov cx, word [ebp + 8]
		push ecx
		push dword [ebp - 4]
		call InternalDriveFoundPrint

	.SkipDevice0:
	; check primary channel drive 1
	push 1
	xor ecx, ecx
	mov cx, word [ebp + 8]
	push ecx
	push dword [ebp - 4]
	call C01DriveIdentify
	pop eax

	; see if the drive existed
	cmp eax, 0xFF
	je .SkipDevice1

		; add the device data to the drives list
		; preserve the drive type (eax) for later
		push eax

		; get first free slot
		push dword [tSystem.listDrives]
		call LMListFindFirstFreeSlot
		pop eax

		; get the address of that slot into esi
		push eax
		push dword [tSystem.listDrives]
		call LMItemGetAddress
		pop esi

		; save base port and device number to table
		xor ecx, ecx
		mov cx, word [ebp + 8]
		mov dword [tDriveInfo.ATABasePort], ecx
		mov dword [tDriveInfo.ATADeviceNumber], 0

		; save device type to table
		pop eax
		mov dword [tDriveInfo.deviceFlags], eax

		; fill in read and write addresses
		mov eax, 3
		cmp eax, 1
		jnz .Device1NotPATA
			; if we get here, the drive type is PATA, so we set the appropriate values
			mov dword [tDriveInfo.readSector], C01ATASectorReadLBA28PIO
			mov dword [tDriveInfo.writeSector], C01ATASectorWriteLBA28PIO

		.Device1NotPATA:
		cmp eax, 3
		jnz .Device1NotATAPI
			; if we get here, the drive type is ATAPI, so we set the appropriate values
			mov dword [tDriveInfo.readSector], C01ATAPISectorReadPIO
		.Device1NotATAPI:

		; allocate 1 MiB cache for this drive and save the address
		push 1048576
		call MemAllocate
		pop dword [tDriveInfo.cacheAddress]

		; fill in model
		; tDriveInfo.model

		; fill in serial
		; tDriveInfo.serial


		; print what we've found
		push eax
		push 1
		xor ecx, ecx
		mov cx, word [ebp + 8]
		push ecx
		push dword [ebp - 4]
		call InternalDriveFoundPrint

	.SkipDevice1:
	; release memory
	;push dword [.dataBlock]
	;call MemDispose

	mov esp, ebp
	pop ebp
ret 8



C01DriveIdentify:
	; Returns identifying information about the device specified
	;
	;  input:
	;   buffer address for results of Identify command
	;   ATA channel I/O base port
	;	device number (0 or 1)
	;
	;  output:
	;   device code
	;		0x00 - Other
	;		0x01 - PATA device
	;		0x02 - SATA device
	;		0x03 - ATAPI device
	;		0xFF - No device found

	push ebp
	mov ebp, esp

	mov edi, [ebp + 8]
	mov ebx, [ebp + 12]
	mov eax, [ebp + 16]

		; make sure eax is in range
		cmp eax, 2
		jb .InRange

	; if we get here, it wasn't in range!
	mov ebp, 0xDEAD0201
	jmp $


	.InRange:
	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl eax, 4
	add eax, 0xE0

	; choose the drive in LBA mode
	mov dx, bx
	add dx, kATARegisterHDDevSel
	out dx, al

	; clear the sector count and LBA registers to put them at a known good state
	xor al, al
	mov dx, bx
	add dx, kATARegisterSecCount0
	out dx, al

	mov dx, bx
	add dx, kATARegisterLBA0
	out dx, al

	mov dx, bx
	add dx, kATARegisterLBA1
	out dx, al

	mov dx, bx
	add dx, kATARegisterLBA2
	out dx, al

	; send the drive identify command
	mov dx, bx
	add dx, kATARegisterCommand
	mov al, kATACommandIdentify
	out dx, al

	; check the response from the port
	mov dx, bx
	add dx, kATARegisterStatus
	in al, dx

	; if al = 0xFF, there's no controller here
	xor cl, cl
	cmp al, 0xFF
	jne .CheckDoneFF
	inc cl

	; if al = 0x00, there's a controller, but no drive on it here
	.CheckDoneFF:
	cmp al, 0x00
	jne .CheckDone00
	inc cl

	.CheckDone00:
	cmp cl, 0
	je .ChecksDone

	; if we get here, the drive doesn't exist
	mov ecx, 0x000000FF
	jmp .Exit

	.ChecksDone:
	; save importants for later
	push edi
	push ebx

	; wait until the drive is ready
	xor edx, edx
	mov dx, bx
	add dx, kATARegisterStatus
	push edx
	call C01WaitForReady

	; restore the importants
	pop ebx
	pop edi

	; see what drive type was returned
	mov dx, bx
	add dx, kATARegisterSecCount0
	in al, dx
	shl eax, 8

	mov dx, bx
	add dx, kATARegisterLBA0
	in al, dx
	shl eax, 8

	mov dx, bx
	add dx, kATARegisterLBA1
	in al, dx
	shl eax, 8

	mov dx, bx
	add dx, kATARegisterLBA2
	in al, dx

	; set up our drive type return code
	xor ecx, ecx
	mov edx, 1
	cmp eax, ecx
	cmove ecx, edx
	je .DriveTypeDone

	mov ecx, 0x0101C33C
	mov edx, 2
	cmp eax, ecx
	cmove ecx, edx
	je .DriveTypeDone

	mov ecx, 0x010114EB
	mov edx, 3
	cmp eax, ecx
	cmove ecx, edx
	je .DriveTypeDone

	; if we get here, the drive didn't match any known type codes
	mov ecx, 0

	.DriveTypeDone:
	; check to see what type of drive we're working with
	; if it's an atapi device, we use the Identify Packet Device command (0xA1)
	cmp ecx, 3
	jne .SkipATAPIIdentify

		; send the Identify Packed Device command
		mov dx, bx
		add dx, kATARegisterCommand
		mov al, kATACommandIdentifyPacket
		out dx, al

		; wait until the drive is ready
		xor edx, edx
		mov dx, bx
		add dx, kATARegisterStatus
		push edx
		call C01WaitForReady


	.SkipATAPIIdentify:
	; save the type of drive we determined already
	push ecx

	; read returned data from the Identify command
	mov dx, bx
	add dx, kATARegisterData
	mov ecx, 256
	push edi
	.ReadLoop:
		in ax, dx
		mov [edi], ax
		add edi, 2
	loop .ReadLoop
	pop edi
	push edi

	; for some dumb reason, the ATA standard has byte-swapped strings, so we fix that here
	; start with the 20 byte serial number beginning at base + 20
	add edi, 20
	push dword 10
	push edi
	call MemSwapWordBytes

	pop edi
	push edi

	; next up is the 8 byte firmware revision number beginning at base + 46
	add edi, 46
	push dword 4
	push edi
	call MemSwapWordBytes

	pop edi

	; finally we process the 40 byte model number beginning at base + 54
	add edi, 54
	push dword 20
	push edi
	call MemSwapWordBytes

	; restore drive type
	pop ecx

	.Exit:
	; put our return value in place
	mov dword [ebp + 16], ecx

	mov esp, ebp
	pop ebp
ret 8



C01InterruptHandlerPrimary:
	; Interrupt handler for ATA interrupts
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	pusha
	pushf

	; acknowledge the interrupt to the PIC
	call PICIntComplete

	popf
	popa

	mov esp, ebp
	pop ebp
iretd


C01InterruptHandlerSecondary:
	; Interrupt handler for ATA interrupts
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	pusha
	pushf

	; acknowledge the interrupt to the PIC
	call PICIntComplete

	popf
	popa

	mov esp, ebp
	pop ebp
iretd



C01WaitForReady:
	; Waits for bit 7 of the passed port value to go clear, then returns
	; Note: I should add a timeout value to this code eventually to avoid getting stuck in an infinite loop if
	; something weird happens with the drive
	;
	;  input:
	;   port number
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov edx, [ebp + 8]

	.PortTestLoop:
		in al, dx
		and al, 0x80
		cmp al, 0
		je .PortTestLoopDone
	jmp .PortTestLoop

	.PortTestLoopDone:

	mov esp, ebp
	pop ebp
ret 4



InternalDriveFoundPrint:
	; Prints data about the drive discovered by C01DriveIdentify()
	; Note: this function writes into the device info block, effectively destroying its accuracy
	;
	;  input:
	;   buffer address containing results of Identify command
	;   ATA channel I/O base port
	;	device number (0 or 1)
	;	device type
	;		0x00 - Other
	;		0x01 - PATA device
	;		0x02 - SATA device
	;		0x03 - ATAPI device
	;		0xFF - No device found
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ebx, [ebp + 12]
	mov edx, [ebp + 16]
	mov ecx, [ebp + 20]

	; now we write a null into the data block to make sure the serial number string is usable
	mov al, 0x00
	mov edi, esi
	add edi, 40
	mov [edi], al

	; do the same for the model number string
	mov edi, esi
	add edi, 94
	mov [edi], al

	; save everything
	pusha

	; clear our print string
	push dword 0
	push dword 256
	push kPrintText$
	call MemFill

	; restore everything
	popa

	; build and print the drive discovered string
	; push device number
	push edx

	; push the port number
	push ebx

	; save everything, trim and push the serial string address, restore everything
	mov edi, esi
	add edi, 20
	push edi
	pusha
	push 32
	push edi
	call StringTrimRight
	popa

	; save everything, trim and push the model string, restore everything
	mov edi, esi
	add edi, 54
	push edi
	pusha
	push 32
	push edi
	call StringTrimRight
	popa

	; build the string
	push kPrintText$

	; select which formatting string to use based on the type of drive this is
	cmp ecx, 3
	jne .SkipATAPIString
	push .foundATAPIFormat$
	jmp .ResumeStringBuild
	.SkipATAPIString:
	push .foundATAFormat$
	.ResumeStringBuild:
	call StringBuild

	; print the string
	push kPrintText$
	call PrintIfConfigBits32

	mov esp, ebp
	pop ebp
.Exit:
ret 16
.foundATAFormat$								db 'Found ATA device ^s (^s) at port 0x^p4^h:^p1^d', 0x00
.foundATAPIFormat$								db 'Found ATAPI device ^s (^s) at port 0x^p4^h:^p1^d', 0x00
