; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
; dos.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

DosSignatureWord           	dw  0x5A4D
PESignatureWord            	dd  0x50450000

; Machine types for PE Windows 9x/NT EXE COFF file header

MACHINE_UNKNOWN			dw 0x0 	
MACHINE_AM33			dw 0x1D3	; Matsushita AM33
MACHINE_AMD64			dw 0x8664	; x64
MACHINE_ARM			    dw 0x1C0	; little endian ARM
MACHINE_ARM64			dw 0xAA64	; little endian ARM64
MACHINE_ARMNT			dw 0x1C4	; ARM Thumb-2 little endian
MACHINE_EBC			    dw 0xEBC	; EFI byte code
MACHINE_I386			dw 0x14C	; Intel 386 or later processors
MACHINE_IA64			dw 0x200	; Intel Itanium
MACHINE_M32R			dw 0x9041	; Mitsubishi M32R little endian
MACHINE_MIPS16			dw 0x266	; MIPS16
MACHINE_MIPSFPU			dw 0x366	; MIPS with FPU
MACHINE_MIPSFPU16		dw 0x466	; MIPS16 with FPU
MACHINE_POWERPC			dw 0x1f0	; PowerPC little endian 
MACHINE_POWERPCFP		dw 0x1f1	; PowerPC with FPU
MACHINE_R4000			dw 0x166	; MIPS little endian
MACHINE_RISCV32         dw 0x5032   ; RISC-V 32-bit address space
MACHINE_RISCV64         dw 0x5064   ; RISC-V 64-bit address space
MACHINE_RISCV128        dw 0x5128   ; RISC-V 128-bit address space
MACHINE_SH3             dw 0x1A2    ; Hitachi SH3
MACHINE_SH3DSP          dw 0x1A3    ; Hitachi Sh3 DSP
MACHINE_SH4             dw 0x1a6    ; Hitachi SH4
MACHINE_SH5             dw 0x1A8    ; Hitachi SH5
MACHINE_THUMB           dw 0x1C2    ; Thumb
MACHINE_WCEMIPSV2       dw 0x169    ; MIPS little-endian WCE v2

; Optional Header Magic Numbers

MAGIC_PE32              db 0x10B    ; Standard executable file
MAGIC_ROM               db 0x107    ; ROM image
MAGIC_PE32PLUS          db 0x20B    ; PE32+ Executable

; Standard DOS EXE headear
struc DOSHEADER
    signatureWord:  resw 1      ; Signature Word value should be 5A4DH
    lastPageSize:   resw 1      ; Last page size
    filePages:      resw 1      ; Pages (multiple of 512)
    relocItems:     resw 1	    ; number of pointers in relocation table
    hdrParagraphs:  resw 1	    ; size of header in paragraphs
    minAlloc:       resw 1	    ; minimum allocation
    maxAlloc:       resw 1	    ; maximum allocation
    initSS:         resw 1	    ; initial SS value
    initSP:         resw 1	    ; initial SP value
    checksum:       resw 1	    ; complemented checksum
    initIP:         resw 1	    ; initial IP value
    initCS:         resw 1	    ; initial CS value
    relocTableOfs:  resw 1	    ; byte offset to relocation table
    overlayNo:      resw 1	    ; overlay number
endstruc

; PE Image file header

struc NTFILEHEADER
    TargetMachine:          resw 1  ; Target Machine
    NumberOfSections:       resw 1  ; Size of section table
    TimeDateStamp:          resd 1  ; time file was created
    PtrToSymbolTable:       resd 1  ; Offset to the COFF symbol table
    NumberOfSymbols:        resd 1  ; Number of Entries in Symbol Table
    SizeOfOptionalHeader:   resw 1  ; Size of the optional header
    ImageCharacteristics:   resw 1  ; Attributes of the file  
endstruc

; Optional Header Standard Fields

struc OPTIONALHEADER
    OHMagic:                resw 1  ; State of the image file
    OHMajorLinkerVersion:   resb 1  ; Linker major version
    OHMinorLinkerVersion:   resb 1  ; Minor linker version
    OHSizeOfCode:           resd 1  ; Size of the code (text) section or the
                                    ; sum of all the code sections if there
                                    ; multiples
    OHSizeOfInitData:       resd 1  ; Size of the initialized data section
    OHSizeOfUninitData:     resd 1  ; Size of the uninitialized data (BSS)
    OHEntryPoint:           resd 1  ; Address of the entry point relative to the image base
    OHBaseOfCode            resd 1  ; Image base
endstruc

