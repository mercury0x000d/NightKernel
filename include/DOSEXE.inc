; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
; DOSEXE.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

DosSignatureWord           	equ  0x5A4D
AltDosSignatureWord	        equ  0x4D5A
PESignatureWord            	equ  0x00004550

; EXECSTATE Types
ESEXE                   	equ 0x0001                                                        ; Program is an EXE file, if this value isn't given then its a .COM file
ESOVERLAY               	equ 0x0002                                                        ; Program is an overlay
                                                                                          ; Machine types for PE Windows 9x/NT EXE COFF file header

MACHINE_UNKNOWN	            equ 0x0
MACHINE_AM33		        equ 0x1D3                                                            ; Matsushita AM33
MACHINE_AMD64		        equ 0x8664                                                          ; x64
MACHINE_ARM			        equ 0x1C0                                                            ; little endian ARM
MACHINE_ARM64		        equ 0xAA64                                                          ; little endian ARM64
MACHINE_ARMNT		        equ 0x1C4                                                           ; ARM Thumb-2 little endian
MACHINE_EBC			        equ 0xEBC                                                            ; EFI byte code
MACHINE_I386			    equ 0x14C                                                               ; Intel 386 or later processors
MACHINE_IA64			    equ 0x200                                                               ; Intel Itanium
MACHINE_M32R		        equ 0x9041                                                           ; Mitsubishi M32R little endian
MACHINE_MIPS16		        equ 0x266                                                          ; MIPS16
MACHINE_MIPSFPU		        equ 0x366                                                         ; MIPS with FPU
MACHINE_MIPSFPU16	        equ 0x466                                                        ; MIPS16 with FPU
MACHINE_POWERPC		        equ 0x1f0                                                         ; PowerPC little endian
MACHINE_POWERPCFP	        equ 0x1f1                                                        ; PowerPC with FPU
MACHINE_R4000		        equ 0x166                                                           ; MIPS little endian
MACHINE_RISCV32         	equ 0x5032                                                        ; RISC-V 32-bit aequress space
MACHINE_RISCV64         	equ 0x5064                                                        ; RISC-V 64-bit aequress space
MACHINE_RISCV128        	equ 0x5128                                                        ; RISC-V 128-bit aequress space
MACHINE_SH3             	equ 0x1A2                                                         ; Hitachi SH3
MACHINE_SH3DSP          	equ 0x1A3                                                         ; Hitachi Sh3 DSP
MACHINE_SH4             	equ 0x1A6                                                         ; Hitachi SH4
MACHINE_SH5             	equ 0x1A8                                                         ; Hitachi SH5
MACHINE_THUMB           	equ 0x1C2                                                         ; Thumb
MACHINE_WCEMIPSV2           equ 0x169                                                      ; MIPS little-endian WCE v2

                                                                                          ; PE Characteristics

PENORELOCATIONS        	    equ 0x0001                                                     ; There are no relocations in the file
PEEXECUTABLE            	equ 0x0002                                                        ; File is an executable image (not an OBJ or LIB)
PEDLL                   	equ 0x2000                                                        ; File is a dynamic link library, not a program

                                                                                          ; Optional Header Magic Numbers

MAGIC_PE32              	equ 0x10B                                                         ; Standard executable file
MAGIC_ROM               	equ 0x107                                                         ; ROM image
MAGIC_PE32PLUS          	equ 0x20B                                                         ; PE32+ Executable

                                                                                          ; Standard DOS EXE headear
struc DOSHEADER
    signatureWord:  		resw 1                                                              ; Signature Word value should be 5A4DH
    lastPageSize:   		resw 1                                                              ; Last page size
    filePages:      		resw 1                                                              ; Pages (multiple of 512)
    relocItems:   	  	    resw 1                                                          ; number of pointers in relocation table
    hdrParagraphs:  		resw 1                     ; size of header in paragraphs
    minAlloc:       		resw 1                     ; minimum allocation
    maxAlloc:       		resw 1                     ; maximum allocation
    initSS:         		resw 1                     ; initial SS value
    initSP:         		resw 1                     ; initial SP value
    checksum:       		resw 1                     ; complemented checksum
    initIP:         		resw 1                     ; initial IP value
    initCS:        			resw 1                     ; initial CS value
    relocTableOfs:  		resw 1                     ; byte offset to relocation table
    overlayNo:      		resw 1                     ; overlay number
endstruc

; PE Image file header

struc NTFILEHEADER
    TargetMachine:          resw 1                 ; Target Machine
    NumberOfSections:      	resw 1                 ; Size of section table
    TimeDateStamp:     		resd 1                 ; time file was created
    PtrToSymbolTable:   	resd 1                 ; Offset to the COFF symbol table
    NumberOfSymbols:      	resd 1                 ; Number of Entries in Symbol Table
    SizeOfOptionalHeader: 	resw 1                 ; Size of the optional header
    ImageCharacteristics:   resw 1                 ; Attributes of the file
endstruc

; Optional Header Standard Fields

struc OPTIONALHEADER
    OHMagic:               			resw 1         ; State of the image file
    OHMajorLinkerVersion:   		resb 1         ; Linker major version
    OHMinorLinkerVersion:   		resb 1         ; Minor linker version
    OHSizeOfCode:          			resd 1         ; Size of the code (text) section or the
                                                   ; sum of all the code sections if there
                                                   ; multiples
    OHSizeOfInitData:      			resd 1         ; Size of the initialized data section
    OHSizeOfUninitData:     		resd 1         ; Size of the uninitialized data (BSS)
    OHEntryPoint:          			resd 1         ; Aequress of the entry point relative to the image base
    OHBaseOfCode:          			resd 1         ; Image base
endstruc

struc IMAGEDATADICTIONARY
    VirtualAequress:       			resd 1        ; RVA starting aequress in the file
    RVASize:               			resd 1        ; Size in bytes
endstruc

struc DOSEXECSTATE
    esReserved:            			resw 1       ; reserved
    esFlags:               			resw 1       ; type flags
    esProgName:            			resd 1       ; points to ASCIIZ string of program name
    esPSP:                 			resw 1       ; PSP segment of the new program
    esStartAequr:           		resd 1       ; Starting CS:IP of the new program
    esProgSize:            			resd 1       ; program size, including PSP
endstruc