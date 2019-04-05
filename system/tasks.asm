; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; tasks.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 32-bit function listing:
; TaskDetermineNext				Calculates the next task which should be run
; TaskInit						Initializes the Task Manager and its required data structure
; TaskNew						Sets up a new task for running
; TaskSwitch					Switches to the task specified





; tTaskInfo struct, used to... *GASP* manage tasks
%define tTaskInfo.cr3							(esi + 00)
%define tTaskInfo.entryPoint					(esi + 04)
%define tTaskInfo.esp							(esi + 08)
%define tTaskInfo.esp0							(esi + 12)
%define tTaskInfo.stackAddress					(esi + 16)
%define tTaskInfo.kernelStackAddress			(esi + 20)
%define tTaskInfo.CPULoad						(esi + 24)
%define tTaskInfo.priority						(esi + 28)
%define tTaskInfo.name							(esi + 32)		; name field is 16 bytes (for now, may need to expand)





; function globals
%define taskStackSize							dword 1024		; a 1 KiB stack is almost guaranteed to be too small in the future
%define taskKernelStackSize						dword 1024




; Special thanks to Brendan over at the OSDev forums for his posts (https://forum.osdev.org/viewtopic.php?f=1&t=10883)
; which beautifully explain the intricacies of software task switching!

;; https://www.quora.com/What-is-a-processes-kernel-stack-What-exactly-is-its-use-besides-keeping-the-thread_info
;tss_entry:
;	.back_link:						dd 0				; only used in hardware multitasking
;	.esp0:							dd 0				; Kernel stack pointer used on ring transitions
;	.ss0:							dd 0				; Kernel stack segment used on ring transitions
;	.esp1:							dd 0
;	.ss1:							dd 0
;	.esp2:							dd 0
;	.ss2:							dd 0
;	.cr3:							dd 0
;	.eip:							dd 0
;	.eflags:						dd 0
;	.eax:							dd 0
;	.ecx:							dd 0
;	.edx:							dd 0
;	.ebx:							dd 0
;	.esp:							dd 0
;	.ebp:							dd 0
;	.esi:							dd 0
;	.edi:							dd 0
;	.es:							dd 0
;	.cs:							dd 0
;	.ss:							dd 0
;	.ds:							dd 0
;	.fs:							dd 0
;	.gs:							dd 0
;	.ldt:							dd 0
;	.trap:							dw 0
;	.iomap_base:					dw TSS_SIZE			; IOPB offset
;	.cetssp:						dd 0				; Need this if CET is enabled
;
;	; Insert any kernel defined task instance data here
;
;	; If using VME (Virtual Mode extensions) there need to be an additional 32 bytes
;	; available immediately preceding iomap. If using VME uncomment next 2 lines
;	.vmeintmap:											; If VME enabled uncomment this line and the next
;	TIMES 32						db 0				;     32*8 bits = 256 bits (one bit for each interrupt)
;
;	.iomap:
;	TIMES TSS_IO_BITMAP_SIZE		db 0x0
;														; IO bitmap (IOPB) size 8192 (8*8192=65536) representing
;														; all ports. An IO bitmap size of 0 would fault all IO
;														; port access if IOPL < CPL (CPL=3 with v8086)
;	%if TSS_IO_BITMAP_SIZE > 0
;	.iomap_pad: db 0xff									; Padding byte that has to be filled with 0xff
;														; To deal with issues on some CPUs when using an IOPB
;	%endif
;	TSS_SIZE EQU $-tss_entry





bits 32





section .text
TaskDetermineNext:
	; Calculates the next task which should be run
	;
	;  input:
	;	Dummy value
	;
	;  output:
	;	Task which should be run next

	push ebp
	mov ebp, esp


	; do stuff here



	mov esp, ebp
	pop ebp
ret





section .text
TaskInit:
	; Initializes the Task Manager routines
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; the task list will be 256 entries of 64 bytes each (the size of a single tTaskInfo element)
	; 256 * 64 + 16 = 16400
	; allocate memory for the list
	push 16400
	push dword 1
	call MemAllocate
	pop edi
	mov [tSystem.listTasks], edi

	; set up the list header
	push 32
	push 256
	push edi
	call LMListInit

	; Use up slot 0 so that it won't get assigned to tasks.
	; Why do we do this? It all goes back to the fact that a task number of zero tells the Memory Manager that
	; the memory block is empty.
	push 0
	push dword [tSystem.listTasks]
	call LMElementAddressGet
	pop esi
	pop eax
	mov [esi], dword 0xFFFFFFFF


	mov esp, ebp
	pop ebp
ret





section .text
TaskNew:
	; Sets up a new task for running
	;
	;  input:
	;	Entry point of new task
	;
	;  output:
	;	Task number

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 8
	%define taskListSlot						dword [ebp - 4]
	%define taskListSlotAddress					dword [ebp - 8]



	; %define tTaskInfo.cr3							(esi + 00)
	; %define tTaskInfo.entryPoint					(esi + 04)
	; %define tTaskInfo.esp							(esi + 08)
	; %define tTaskInfo.esp0						(esi + 12)
	; %define tTaskInfo.stackAddress				(esi + 16)
	; %define tTaskInfo.kernelStackAddress			(esi + 20)
	; %define tTaskInfo.CPULoad						(esi + 24)
	; %define tTaskInfo.priority					(esi + 28)
	; %define tTaskInfo.name						(esi + 32)		; name field is 16 bytes (for now, may need to expand)

	; PUSHA order: EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI



	; get first free slot in the task list
	push dword [tSystem.listTasks]
	call LMSlotFindFirstFree
	pop eax
	mov taskListSlot, eax


	; get the starting address of that specific slot into esi
	push eax
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	pop esi
	pop eax
	mov taskListSlotAddress, esi


	; allocate some memory for this task's stack
	push taskStackSize
	push taskListSlot
	call MemAllocate
	pop eax
	mov esi, taskListSlotAddress
	mov [tTaskInfo.stackAddress], eax


	; adjust the memory address to point to the stack pointer
	add eax, taskStackSize
	mov [tTaskInfo.esp], eax


	; allocate some memory for this task's kernel stack
	push taskKernelStackSize
	push taskListSlot
	call MemAllocate
	pop eax
	mov esi, taskListSlotAddress
	mov [tTaskInfo.kernelStackAddress], eax

	; adjust the memory address to point to the stack pointer
	add eax, taskKernelStackSize
	mov [tTaskInfo.esp0], eax


	; set up paging for this task's memory space


	; set entry point (starting EIP)
	mov eax, dword [ebp + 8]
	mov [tTaskInfo.entryPoint], eax


	; return the task number
	mov eax, taskListSlot
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret





section .text
TaskSwitch:
	; Switches to the task specified
	;
	;  input:
	;	Task to which to switch
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; get task
	mov edi, [ebp + 8]


	; do stuff here



	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret
