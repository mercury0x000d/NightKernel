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

; privileged instructions
; CLTS				Clear Task Switch Flag in Control Register CR0
; HLT				Halt Processor
; INVD				Invalidate Cache without writeback
; INVLPG			Invalidate TLB Entry
; LGDT				Loads an address of a GDT into GDTR
; LLDT				Loads an address of a LDT into LDTR
; LMSW				Load a new Machine Status WORD
; LTR				Loads a Task Register into TR
; MOV				Control Register	Copy data and store in Control Registers
; MOV 				Debug Register	Copy data and store in debug registers
; RDMSR				Read Model Specific Registers (MSR)
; RDPMC				Read Performance Monitoring Counter
; RDTSC				Read time Stamp Counter
; WBINVD			Invalidate Cache with writeback
; WRMSR				Write Model Specific Registers (MSR)





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
	push 64
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
TaskKill:
	; Kills the specified task
	;
	;  input:
	;	Task number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get info on the current task
	push dword [ebp + 8]
	push dword [tSystem.listTasks]
	call LMElementAddressGet
	pop esi
	pop ebx


	; zero out this task's memory slot
	push 0x00000000
	push dword 64
	push esi
	call MemFill


	; and finally, we clear out the currently running task info
	mov dword [tSystem.currentTask], 0
	mov dword [tSystem.currentTaskSlotAddress], 0

	mov esp, ebp
	pop ebp
ret 4





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


	; get first free slot in the task list
	push dword 0
	push dword [tSystem.listTasks]
	call LMSlotFindFirstFree
	pop eax
	pop ebx
	mov taskListSlot, eax


	; get the starting address of that specific slot into esi
	push eax
	push dword [tSystem.listTasks]
	call LMElementAddressGet
	pop esi
	pop eax
	mov taskListSlotAddress, esi


	; set entry point (starting EIP)
	mov eax, dword [ebp + 8]
	mov [tTaskInfo.entryPoint], eax


	; set up paging for this task's memory space


	; allocate some memory for this task's kernel stack
	; Intel *strongly* recommends aligning a 32-bit stack on a 32-bit boundary, so we allocate aligned to 4 bytes
	push dword 4
	push taskKernelStackSize
	push taskListSlot
	call MemAllocateAligned
	pop eax
	mov esi, taskListSlotAddress
	mov [tTaskInfo.kernelStackAddress], eax

	; adjust this stack address to point to the other end of the stack, as the CPU will expect
	add eax, taskKernelStackSize
	mov [tTaskInfo.esp0], eax


	; allocate some memory for this task's stack
	; the task number is this task's slot number
	push dword 4
	push taskStackSize
	push taskListSlot
	call MemAllocateAligned
	pop eax
	mov esi, taskListSlotAddress
	mov [tTaskInfo.stackAddress], eax


	; adjust the stack address to point to the other end of the stack, as we did with the other stack a moment ago
	; except this time, we don't save it just yet since we will be writing to that stack now
	add eax, taskStackSize


	; build this task's stack
	; save our current stack pointer first
	mov edx, esp

	; set the new stack address
	mov esp, eax

	; push the eflags register this task will use
	push dword 0x00200216

	; push the cs register this task will use
	push dword 0x08

	; push the eip register this task will use
	push dword [ebp + 8]

	; push null for all 8 registers (eax, ebx, ecx, edx, esi, edi, esp, ebp)
	; it's safe to push 0 here for esp since it will be set correctly from what's in the task structure anyway
	push 0x00000000
	push 0x00000000
	push 0x00000000
	push 0x00000000
	push 0x00000000
	push 0x00000000
	push 0x00000000
	push 0x00000000


	; now save the current esp for this task
	mov [tTaskInfo.esp], esp


	; restore our original stack
	mov esp, edx


	; return the task number
	mov eax, taskListSlot
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret
.taskingsetup			db 0x00





section .text
TaskSwitch:
	; Performs a context switch to the next task
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; see if tasking is disabled, skip context switching if so
	cmp byte [tSystem.taskingEnable], 0
	je .TaskingDisabled


	; if currentTask is 0, that means the first task switch hasn't yet happened or the task that was running got killed
	; in either case, we do not need to save task info
	cmp dword [tSystem.currentTask], 0
	je .SkipSaveState

		; save the registers of this task to its stack
		pusha
		mov esi, dword [tSystem.currentTaskSlotAddress]
		mov [tTaskInfo.esp], esp

	.SkipSaveState:


	; This will be slower than it could potentially be if we didn't use list manager calls here, but you know the old
	; adage; first make it run, THEN make it run fast. We can always optimize this later.

	; Set up a loop to determine the next task to which we should switch. We simply step through every task's ESP
	; value until we get one that's non-zero, then use it.
	mov ebx, dword [tSystem.currentTask]
	.findNextTaskLoop:
		; add one to the task number, then mask to make sure we stay under 255
		inc ebx
		and ebx, 0x000000FF


		; We use a couple tricks here below for speed. First, we're calling an internal List Manager function directly instead
		; of going through the slower public interface. This bypasses the parameter checking that's normally performed, but
		; that's okay since we are managing the input internally, so we know it will be correct. Second, we use the EBX
		; register to track the current task number we're testing. Why EBX? Because LM_Internal_ElementAddressGet() doesn't
		; modify it, so we don't need to save it here, saving us a handful of CPU cycles.

		; get that task number's starting address
		push ebx
		push dword [tSystem.listTasks]
		call LM_Internal_ElementAddressGet
		pop esi


		; get the ESP register of this task into ecx
		mov ecx, [tTaskInfo.esp]

		; see if we have something that's not zero
		cmp ecx, 0
	je .findNextTaskLoop


	; by the time we get here, we know what task to execute next
	mov dword [tSystem.currentTaskSlotAddress], esi
	mov dword [tSystem.currentTask], ebx
	mov esp, ecx
	popa

	.TaskingDisabled:
iret
