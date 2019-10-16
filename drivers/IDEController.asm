; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; IDE Controller.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; IDEATAPISectorReadPIO							Reads sectors from an ATAPI device
; IDEATASectorReadLBA28PIO						Reads sectors from an ATA disk using LBA28 in PIO mode
; IDEATASectorWriteLBA28PIO						Writes sectors to an ATA disk using LBA28 in PIO mode
; IDEDetectChannelDevice						Checks both of the device spots on the ATA channel specified and saves their data to the drives list
; IDEDeviceInfoLoad								Loads data for the device at the ATA Channel specified and saves its data to the drives list
; IDEDriveIdentify								Returns identifying information about the device specified
; IDEInit										Performs any necessary setup of the driver
; IDEInterruptHandlerPrimary					Interrupt handler for ATA interrupts
; IDEInterruptHandlerSecondary					Interrupt handler for ATA interrupts
; IDEServiceHandler								The service routine called by external applications
; IDEWaitForReady								Waits for bit 7 of the passed port value to go clear, then returns





%include "include/IDEController.def"

%include "include/errors.inc"
%include "include/globals.inc"
%include "include/interrupts.inc"
%include "include/lists.inc"
%include "include/memory.inc"
%include "include/PCI.inc"
%include "include/PIC.inc"
%include "include/screen.inc"





bits 32





section .text
IDEATAPISectorReadPIO:
	; Reads sectors from an ATAPI device
	;
	;  input:
	;	I/O base port
	;	Device number (0 or 1)
	;	LBA address of starting sector
	;	Number of sectors to write
	;	Memory buffer address to which data will be written
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define IOPort								dword [ebp + 8]
	%define deviceNumber						dword [ebp + 12]
	%define LBAAddress							dword [ebp + 16]
	%define sectorCount							dword [ebp + 20]
	%define bufferPtr							dword [ebp + 24]


	mov ebx, IOPort
	mov eax, deviceNumber
	mov edi, bufferPtr

	; make sure eax is in range
	cmp eax, 2
	jb .InRange
		; if we get here, it wasn't in range!
		mov edx, kErrValueTooHigh
		jmp .Exit
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
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

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
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

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
	mov eax, LBAAddress
	shr eax, 16
	xchg ah, al
	out dx, ax

	mov dx, bx
	add dx, kATARegisterData
	mov eax, LBAAddress
	xchg ah, al
	out dx, ax

	; send the sector count
	mov dx, bx
	add dx, kATARegisterData
	mov eax, sectorCount
	shr eax, 16
	xchg ah, al
	out dx, ax

	mov dx, bx
	add dx, kATARegisterData
	mov eax, sectorCount
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
	push IDEInterruptHandlerSecondary
	push 0x08
	push 0x2F
	call InterruptHandlerSet

	; if we get here, all is well!
	mov edx, kErrNone


	.Exit:
	%undef IOPort
	%undef deviceNumber
	%undef LBAAddress
	%undef sectorCount
	%undef bufferPtr
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





section .text
IDEATASectorReadLBA28PIO:
	; Reads sectors from an ATA disk using LBA28 in PIO mode
	;
	;  input:
	;	I/O base port
	;	Device number (0 or 1)
	;	LBA address of starting sector
	;	Number of sectors to write
	;	Memory buffer address to which data will be written
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define IOPort								dword [ebp + 8]
	%define deviceNumber						dword [ebp + 12]
	%define LBAAddress							dword [ebp + 16]
	%define sectorCount							dword [ebp + 20]
	%define bufferPtr							dword [ebp + 24]


	; mask off starting sector to give us 28 bits
	and dword LBAAddress, 0x0FFFFFFF

	; make sure the device number is in range
	mov ecx, deviceNumber
	cmp ecx, 2
	jb .InRange
		; if we get here, it wasn't in range!
		mov edx, kErrValueTooHigh
		jmp .Exit
	.InRange:

	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl ecx, 4
	add ecx, 0xE0

	mov eax, LBAAddress
	mov edx, IOPort

	; select device and bits 24:27 of the LBA address
	add edx, kATARegisterHDDevSel

	; move bits 24:27 of the LBA address into al
	shr eax, 24

	; perform a logical or to properly set the selected device
	or al, cl
	out dx, al

	; set sector count
	mov edx, IOPort
	add edx, kATARegisterSecCount0
	mov ecx, sectorCount
	mov al, cl
	out dx, al

	; set bits 0:7 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA0
	out dx, al

	; set bit 8:15 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA1
	shr eax, 8
	out dx, al

	; set bits 16:23 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA2
	shr eax, 16
	out dx, al

	; and finally, execute the command!
	mov edx, IOPort
	add edx, kATARegisterCommand
	mov al, kATACommandReadPIO
	out dx, al

	; wait for the device to respond
	push edx
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

	; set up a loop to read the sectors
	; add code here later to determine sector size from the drive data and modify this loop accordingly
	mov ecx, sectorCount
	.ReadSectors:
		mov sectorCount, ecx

		mov ecx, 256
		mov edx, IOPort
		mov edi, bufferPtr
		rep insw

		; get ready for the next sector read
		add bufferPtr, 512

		; wait for the device to respond
		mov edx, IOPort
		add edx, kATARegisterCommand
		push edx
		call IDEWaitForReady

		; exit if error
		cmp edx, kErrNone
		jne .Exit

		mov ecx, sectorCount
	loop .ReadSectors

	; if we get here, all is well!
	mov edx, kErrNone


	.Exit:
	%undef IOPort
	%undef deviceNumber
	%undef LBAAddress
	%undef sectorCount
	%undef bufferPtr
	mov esp, ebp
	pop ebp
ret 20





section .text
IDEATASectorWriteLBA28PIO:
	; Writes sectors to an ATA disk using LBA28 in PIO mode
	;
	;  input:
	;	I/O base port
	;	Device number (0 or 1)
	;	LBA address of starting sector
	;	Number of sectors to write
	;	Memory buffer address from which data will be read
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define IOPort								dword [ebp + 8]
	%define deviceNumber						dword [ebp + 12]
	%define LBAAddress							dword [ebp + 16]
	%define sectorCount							dword [ebp + 20]
	%define bufferPtr							dword [ebp + 24]


	; mask off starting sector to give us 28 bits
	and LBAAddress, 0x0FFFFFFF

	; make sure the device number is in range
	mov ecx, deviceNumber
	cmp ecx, 2
	jb .InRange
		; if we get here, it wasn't in range!
		mov edx, kErrValueTooHigh
		jmp .Exit
	.InRange:

	; adjust eax to E0 if it's currently 0 or F0 if it's currently 1
	shl ecx, 4
	add ecx, 0xE0

	mov eax, LBAAddress
	mov edx, IOPort
	; select device and bits 24:27 of the LBA address

	add edx, kATARegisterHDDevSel

	; move bits 24:27 of the LBA address into al
	shr eax, 24

	; perform a logical or to properly set the selected device
	or al, cl
	out dx, al

	; set sector count
	mov edx, IOPort
	add edx, kATARegisterSecCount0
	mov ecx, sectorCount
	mov al, cl
	out dx, al

	; set bits 0:7 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA0
	out dx, al

	; set bit 8:15 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA1
	shr eax, 8
	out dx, al

	; set bits 16:23 of the LBA address
	mov eax, LBAAddress
	mov edx, IOPort
	add edx, kATARegisterLBA2
	shr eax, 16
	out dx, al

	; and finally, execute the command!
	mov edx, IOPort
	add edx, kATARegisterCommand
	mov al, kATACommandWritePIO
	out dx, al

	; wait for the device to respond
	push edx
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

	; set up a loop to write the sectors
	; add code here later to determine sector size from the drive data and modify this loop accordingly
	mov ecx, sectorCount
	.WriteSectors:
		mov sectorCount, ecx

		mov ecx, 256
		mov edx, IOPort
		mov esi, bufferPtr
		rep outsw

		; get ready for the next sector read
		add bufferPtr, 512

		; wait for the device to respond
		mov edx, IOPort
		add edx, kATARegisterCommand
		push edx
		call IDEWaitForReady

		; exit if error
		cmp edx, kErrNone
		jne .Exit

		mov ecx, sectorCount
	loop .WriteSectors

	; clear out the cache
	mov edx, IOPort
	add edx, kATARegisterCommand
	mov al, kATACommandCacheFlush
	out dx, al

	; wait for the device to respond
	mov edx, IOPort
	add edx, kATARegisterCommand
	push edx
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

	; if we get here, all is well!
	mov edx, kErrNone


	.Exit:
	%undef IOPort
	%undef deviceNumber
	%undef LBAAddress
	%undef sectorCount
	%undef bufferPtr
	mov esp, ebp
	pop ebp
ret 20





section .text
IDEDetectChannelDevice:
	; Checks both of the device spots on the ATA channel specified and saves their data to the drives list
	;
	;  input:
	;	PCI Class
	;	PCI Subclass
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	I/O base port
	;	Control base port
	;	Device number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIClass							dword [ebp + 8]
	%define PCISubclass							dword [ebp + 12]
	%define PCIBus								dword [ebp + 16]
	%define PCIDevice							dword [ebp + 20]
	%define PCIFunction							dword [ebp + 24]
	%define IOPort								dword [ebp + 28]
	%define controlPort							dword [ebp + 32]
	%define deviceNum							dword [ebp + 36]

	; allocate local variables
	sub esp, 8
	%define dataBlock							dword [ebp - 4]		; pointer to 512 byte buffer used by identify function
	%define driveListSlotAddress				dword [ebp - 8]


	; allocate a sector's worth of RAM
	; add code here to determine the sector size first, then allocate
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov dataBlock, eax


	; now probe the device and see what's there
	push deviceNum
	mov ecx, IOPort
	and ecx, 0x0000FFFF
	push ecx
	push dataBlock
	call IDEDriveIdentify

	; see if the drive existed
	cmp eax, 0x00
	je .NoDevice

	cmp eax, 0xFF
	je .NoDevice

		; add the device data to the drives list
		; preserve the drive type (eax) for later
		push eax


		; get first free slot
		push dword [tSystem.listDrives]
		call LMSlotFindFirstFree


		; get the address of that slot into esi
		push eax
		push dword [tSystem.listDrives]
		call LMElementAddressGet
		mov driveListSlotAddress, esi


		; save ports and device number to table
		mov ecx, IOPort
		and ecx, 0x0000FFFF
		mov dword [esi + tDriveInfo.ATABasePort], ecx

		mov ecx, controlPort
		and ecx, 0x0000FFFF
		mov dword [esi + tDriveInfo.ATAControlPort], ecx

		mov ecx, deviceNum
		mov dword [esi + tDriveInfo.ATADeviceNumber], ecx


		; save device type to table
		pop eax
		mov dword [esi + tDriveInfo.deviceFlags], eax


		; allocate 1 MiB cache for this drive and save the address
		push dword 1048576
		push dword 1
		call MemAllocate

		; see if there was an error, if not save the pointer
		cmp edx, kErrNone
		jne .Exit
		mov esi, driveListSlotAddress
		mov dword [esi + tDriveInfo.cacheAddress], eax


		; fill in PCI info
		mov eax, PCIClass
		mov dword [esi + tDriveInfo.PCIClass], eax

		mov eax, PCISubclass
		mov dword [esi + tDriveInfo.PCISubclass], eax

		mov eax, PCIBus
		mov dword [esi + tDriveInfo.PCIBus], eax

		mov eax, PCIDevice
		mov dword [esi + tDriveInfo.PCIDevice], eax

		mov eax, PCIFunction
		mov dword [esi + tDriveInfo.PCIFunction], eax


		; fill in model
		push 40
		mov esi, driveListSlotAddress
		add esi, tDriveInfo.model
		push esi
		mov edi, dataBlock
		add edi, 54
		push edi
		call MemCopy


		; fill in serial
		push 20
		mov esi, driveListSlotAddress
		add esi, tDriveInfo.serial
		push esi
		mov edi, dataBlock
		add edi, 20
		push edi
		call MemCopy

	.NoDevice:

	; release memory
	push dataBlock
	call MemDispose

	; no errors here!
	mov edx, kErrNone


	.Exit:
	%undef PCIClass
	%undef PCISubclass
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef IOPort
	%undef controlPort
	%undef deviceNum
	%undef dataBlock
	%undef driveListSlotAddress
	mov esp, ebp
	pop ebp
ret 32





section .text
IDEDriveIdentify:
	; Returns identifying information about the device specified
	;
	;  input:
	;	Buffer address for results of Identify command
	;	ATA channel I/O base port
	;	Device number (0 or 1)
	;
	;  output:
	;	EAX - Device code
	;			0x00 - Other
	;			0x01 - PATA device
	;			0x02 - SATA device
	;			0x03 - ATAPI device
	;			0xFF - No device found

	push ebp
	mov ebp, esp

	; define input parameters
	%define bufferPtr							dword [ebp + 8]
	%define IOPort								dword [ebp + 12]
	%define deviceNumber						dword [ebp + 16]


	mov edi, bufferPtr
	mov ebx, IOPort
	mov eax, deviceNumber

	; make sure eax is in range
	cmp eax, 2
	jb .InRange
		; if we get here, it wasn't in range!
		mov eax, kErrValueTooHigh
		jmp .Exit
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

	xor cl, cl

	; if al = 0xFF, there's no controller here
	cmp al, 0xFF
	jne .CheckDoneFF
		inc cl
	.CheckDoneFF:

	; if al = 0x00, there's a controller, but no drive on it here
	cmp al, 0x00
	jne .CheckDone00
		inc cl
	.CheckDone00:

	cmp cl, 0
	je .ChecksDone
		; if we get here, the drive doesn't exist
		mov eax, 0x000000FF
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
	call IDEWaitForReady

	; exit if error
	cmp edx, kErrNone
	jne .Exit

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
		call IDEWaitForReady

		; exit if error
		cmp edx, kErrNone
		jne .Exit

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
	pop eax


	.Exit:
	%undef bufferPtr
	%undef IOPort
	%undef deviceNumber
	mov esp, ebp
	pop ebp
ret 12





section .text
IDEInit:
	; Performs any necessary setup of the driver
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define commandCode							dword [ebp + 20]

	; allocate local variables
	sub esp, 16
	%define PCIClass							dword [ebp - 4]
	%define PCISubclass							dword [ebp - 8]
	%define IOBasePort							dword [ebp - 12]
	%define ControlBasePort						dword [ebp - 16]


	; announce ourselves!
	push .driverIntro$
	call PrintIfConfigBits32


	; commandeer the apropriate interrupt handler addresses
	push 0x8e
	push IDEInterruptHandlerPrimary
	push 0x08
	push 0x2E
	call InterruptHandlerSet

	push 0x8e
	push IDEInterruptHandlerSecondary
	push 0x08
	push 0x2F
	call InterruptHandlerSet


	; get the class
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIInfoClassGet
	mov PCIClass, eax

	; now get the subclass
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIInfoSubclassGet
	mov PCISubclass, eax


	; get the I/O ports for the drives from the PCI space and adjust them if needed
	; get BAR1 for this device to find the primary channel control port
	push dword 0x00000005
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	; if the value returned was zero, it should actually be 0x03F6
	cmp ax, 0
	jne .SkipAdjust2
	mov ax, 0x03F6
	.SkipAdjust2:
	mov ControlBasePort, eax


	; get BAR0 for this device to find the primary channel IO port
	push dword 0x00000004
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	; if the value returned was zero, it should actually be 0x01F0
	cmp ax, 0
	jne .SkipAdjust1
	mov ax, 0x01F0
	.SkipAdjust1:
	mov IOBasePort, eax

	push dword 0
	push ControlBasePort
	push IOBasePort
	push PCIFunction
	push PCIDevice
	push PCIBus
	push PCISubclass
	push PCIClass
	call IDEDetectChannelDevice

	; exit if error
	cmp edx, kErrNone
	jne .Exit


	push dword 1
	push ControlBasePort
	push IOBasePort
	push PCIFunction
	push PCIDevice
	push PCIBus
	push PCISubclass
	push PCIClass
	call IDEDetectChannelDevice

	; exit if error
	cmp edx, kErrNone
	jne .Exit


	; get BAR3 for this device to find the secondary channel control port
	push dword 0x00000007
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	; if the value returned was zero, it should actually be 0x0376
	cmp ax, 0
	jne .SkipAdjust4
	mov ax, 0x0376
	.SkipAdjust4:
	mov ControlBasePort, eax


	; get BAR2 for this device to find the secondary channel IO port
	push dword 0x00000006
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	; if the value returned was zero, it should actually be 0x0170
	cmp ax, 0
	jne .SkipAdjust3
	mov ax, 0x0170
	.SkipAdjust3:
	mov IOBasePort, eax

	push dword 0
	push ControlBasePort
	push IOBasePort
	push PCIFunction
	push PCIDevice
	push PCIBus
	push PCISubclass
	push PCIClass
	call IDEDetectChannelDevice

	; exit if error
	cmp edx, kErrNone
	jne .Exit


	push dword 1
	push ControlBasePort
	push IOBasePort
	push PCIFunction
	push PCIDevice
	push PCIBus
	push PCISubclass
	push PCIClass
	call IDEDetectChannelDevice

	; exit if error
	cmp edx, kErrNone
	jne .Exit


	; exit with return status
	mov edx, kErrNone

	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef commandCode
	%undef PCIClass
	%undef PCISubclass
	%undef IOBasePort
	%undef ControlBasePort
	mov esp, ebp
	pop ebp
ret 12

section .data
.driverIntro$									db 'IDE Controller Driver, 2018 - 2019 by Mercury0x0D', 0x00





section .text
IDEInterruptHandlerPrimary:
	; Interrupt handler for ATA interrupts
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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





section .text
IDEInterruptHandlerSecondary:
	; Interrupt handler for ATA interrupts
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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





section .text
IDEServiceHandler:
	; The service routine called by external applications
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	Command code
	;	Parameter 1
	;	Parameter 2
	;	Parameter 3
	;	Parameter 4
	;	Parameter 5
	;
	;  output:
	;	Varies by function

	push ebp
	mov ebp, esp

	; define input parameters common to all commands
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define commandCode							dword [ebp + 20]
	%define parameter1							dword [ebp + 24]
	%define parameter2							dword [ebp + 28]
	%define parameter3							dword [ebp + 32]
	%define parameter4							dword [ebp + 36]


	; work that command!
	mov eax, commandCode

	cmp eax, kDriverInit
	jne .NotDriverInit
		; this command takes no parameters
		push PCIFunction
		push PCIDevice
		push PCIBus
		call IDEInit

		; save any error code to ebx
		mov ebx, eax

		; no special response for this command
		mov eax, 0

		jmp .Exit
	.NotDriverInit:


	cmp eax, kDriverRead
	jne .NotDriverRead
		; defines for input parameters for this command
		%define driveNumber							parameter1
		%define startSector							parameter2
		%define sectorCount							parameter3
		%define bufferPtr							parameter4


		push parameter1
		push dword [tSystem.listDrives]
		call LMElementAddressGet

		cmp edx, kErrNone
		je .NoReadError
			; if we get here, there was a problem
			mov eax, edx
			jmp .Exit
		.NoReadError:

		push parameter4
		push parameter3
		push parameter2
		push dword [esi + tDriveInfo.ATADeviceNumber]
		push dword [esi + tDriveInfo.ATABasePort]
		call IDEATASectorReadLBA28PIO

		; save any error code to ebx
		mov ebx, eax

		; no special response for this command
		mov eax, 0

		jmp .Exit
	.NotDriverRead:


	cmp eax, kDriverWrite
	jne .NotDriverWrite
		; defines for input parameters for this command
		%define driveNumber							parameter1
		%define startSector							parameter2
		%define sectorCount							parameter3
		%define bufferPtr							parameter4


		push driveNumber
		push dword [tSystem.listDrives]
		call LMElementAddressGet

		cmp edx, kErrNone
		je .WriteNoError
			; if we get here, there was a problem
			mov eax, edx
			jmp .Exit
		.WriteNoError:

		push bufferPtr
		push sectorCount
		push startSector
		push dword [esi + tDriveInfo.ATADeviceNumber]
		push dword [esi + tDriveInfo.ATABasePort]
		call IDEATASectorWriteLBA28PIO

		; save any error code to ebx
		mov ebx, eax

		; no special response for this command
		mov eax, 0

		jmp .Exit
	.NotDriverWrite:


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef commandCode
	%undef parameter1
	%undef parameter2
	%undef parameter3
	%undef parameter4
	%undef driveNumber
	%undef startSector
	%undef sectorCount
	%undef bufferPtr
	; EAX will be set by whatever function was called and therefore does not need explicitly set here
	mov esp, ebp
	pop ebp
ret 36





section .text
IDEWaitForReady:
	; Waits for bit 7 of the passed port value to go clear, then returns
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define IOPort								dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define timeout								dword [ebp - 4]


	; set up a half-second timeout
	mov eax, dword [tSystem.ticksSinceBoot]
	add eax, 128
	mov timeout, eax

	; set the I/O port
	mov edx, IOPort

	.PortTestLoop:
		in al, dx
		and al, 0x80
		cmp al, 0
		je .Success

		; see if we've timed out
		mov eax, dword [tSystem.ticksSinceBoot]
		cmp eax, timeout	
		ja .Timeout
	jmp .PortTestLoop

	.Timeout:
	mov edx, kErrTimeout
	jmp .Exit

	.Success:
	mov edx, kErrNone


	.Exit:
	%undef IOPort
	%undef timeout
	mov esp, ebp
	pop ebp
ret 4





; %00000000dffd4ff0: 6c 69 73 74 90 00 00 00-00 01 00 00 10 90 00 00  list............
; %00000000dffd5000: 56 42 4f 58 20 48 41 52-44 44 49 53 4b 20 20 20  VBOX HARDDISK   
; %00000000dffd5010: 20 20 20 20 20 20 20 20-20 20 20 20 20 20 20 20                  
; %00000000dffd5020: 20 20 20 20 20 20 20 20-00 00 00 00 00 00 00 00          ........
; %00000000dffd5030: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5040: 56 42 65 32 34 34 63 64-37 65 2d 64 31 36 35 62  VBe244cd7e-d165b
; VBoxDbg> d
; %00000000dffd5050: 63 33 63 20 00 00 00 00-00 00 00 00 00 00 00 00  c3c ............
; %00000000dffd5060: 01 00 00 00 01 00 00 00-00 00 00 00 01 00 00 00  ................
; %00000000dffd5070: 01 00 00 00 48 c8 e8 df-01 00 00 00 f0 01 00 00  ....H...........
; %00000000dffd5080: f6 03 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5090: 56 42 4f 58 20 43 44 2d-52 4f 4d 20 20 20 20 20  VBOX CD-ROM     
; %00000000dffd50a0: 20 20 20 20 20 20 20 20-20 20 20 20 20 20 20 20                  
; VBoxDbg> d
; %00000000dffd50b0: 20 20 20 20 20 20 20 20-00 00 00 00 00 00 00 00          ........
; %00000000dffd50c0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd50d0: 56 42 32 2d 30 31 37 30-30 33 37 36 20 20 20 20  VB2-01700376    
; %00000000dffd50e0: 20 20 20 20 00 00 00 00-00 00 00 00 00 00 00 00      ............
; %00000000dffd50f0: 01 00 00 00 01 00 00 00-00 00 00 00 01 00 00 00  ................
; %00000000dffd5100: 01 00 00 00 48 c6 d8 df-03 00 00 00 70 01 00 00  ....H.......p...
; VBoxDbg> d
; %00000000dffd5110: 76 03 00 00 00 00 00 00-00 00 00 00 00 00 00 00  v...............
; %00000000dffd5120: 56 42 4f 58 20 43 44 2d-52 4f 4d 20 20 20 20 20  VBOX CD-ROM     
; %00000000dffd5130: 20 20 20 20 20 20 20 20-20 20 20 20 20 20 20 20                  
; %00000000dffd5140: 20 20 20 20 20 20 20 20-00 00 00 00 00 00 00 00          ........
; %00000000dffd5150: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5160: 56 42 33 2d 30 31 37 30-30 33 37 36 20 20 20 20  VB3-01700376    
; VBoxDbg> d
; %00000000dffd5170: 20 20 20 20 00 00 00 00-00 00 00 00 00 00 00 00      ............
; %00000000dffd5180: 01 00 00 00 01 00 00 00-00 00 00 00 01 00 00 00  ................
; %00000000dffd5190: 01 00 00 00 48 c6 c8 df-03 00 00 00 70 01 00 00  ....H.......p...
; %00000000dffd51a0: 76 03 00 00 01 00 00 00-00 00 00 00 00 00 00 00  v...............
; %00000000dffd51b0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd51c0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; VBoxDbg> d
; %00000000dffd51d0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd51e0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd51f0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5200: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5210: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5220: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; VBoxDbg> d
; %00000000dffd5230: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5240: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5250: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5260: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5270: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................
; %00000000dffd5280: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00  ................



