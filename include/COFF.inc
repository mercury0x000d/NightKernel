; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; COFF.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.
;
; This information was compiled from https://wiki.osdev.org/COFF and translated as best as possible to assembly
; COFF Magic Number
I386MAGIC                       equ 0x014C
I386AIXMAGIC                    equ 0x0175

; COFF Characteristics

IMAGE_FILE_RELOCS_STRIPPED      equ 0x0001
IMAGE_FILE_EXECUTABLE_IMAGE     equ 0x0002    ; Image only
IMAGE_FILE_LINE_NUMS_STRIPPED   equ 0x0004
IMAGE_FILE_LOCAL_SYMS_STRIPPED  equ 0x0008   
IMAGE_FILE_AGGRESSIVE_WS_TRIM   equ 0x0010
IMAGE_FILE_LARGE_ADDRESS_AWARE  equ 0x0020

; COFF File Header Flags
F_RELFLG                        equ 0x0001    ; Relocation information stripped from the file
F_EXEC                          equ 0x0002    ; The file is relocatable (no unresolved external references)
F_LNNO                          equ 0x0004    ; Line numbers stripped
F_LSYMS                         equ 0x0008    ; Local symbols stripped from the file

; Section Flags
STYP_TEXT                       equ 0x0020    ; The section contains executable code
STYP_DATA                       equ 0x0040    ; The section contains initialized data
STYP_BSS                        equ 0x0080    ; Space needs to be allocated for this even though there is no data here
                                             ; in the COFF file

; Section Number Values
N_DEBUG                         equ 2         ; Debugging symbol
N_ABS                           equ 1         ; An absolute symbol
N_UNDEF                         equ 0         ; An undefined external symbol
struc COFFHEADER
    CoffMagicNumber:            resw 1      ; Magic Number
    CoffNumSectionHeaders:      resw 1      ; Number of Section headers
    CoffTimeDateStamp:          resd 1      ; TimeDate Stamp when the file was created
    CoffSymbolTablePointer:     resd 1      ; Starting address of symbol table
    CoffSymbolTableEntries:     resd 1      ; Number of entries in the symbol table
    CoffOptionalHeaderSize:     resw 1      ; Number of bytes in optional header
    CoffFlags:                  resw 1      ; Flags
    CoffTargetID:               resw 1      ; Target ID
endstruc

struc SECTIONHEADER
    SectionName:                resb 8      ; Section Name
    PhysAddr:                   resd 1      ; Physical Address
    VirtAddr:                   resd 1      ; Virtual Address
    SectionSize:                resd 1      ; Section Size (in bytes)
    SectionPtr:                 resd 1      ; File offset to Section data
    RelocPtr:                   resd 1      ; File offset to the Relocation Table for this section
    LineNoPtr:                  resd 1      ; File offset to Line Number table
    NReloc:                     resw 1      ; Number of relocation table entries
    NLineNo:                    resw 1      ; Number of line number table entries
    Flags:                      resd 1      ; Flags for this section
endstruc

struc SYMBOLTABLE
    SymName:                    resb 8      ; Symbol name
    SymValue:                   resd 1      ; Value of symbol
    SectNumb:                   resw 1      ; Section Number
    SymType:                    resw 1      ; Symbol Type
    StorageClass:               resb 1      ; Storage class
    AuxCount:                   resb 1      ; Auxiliary count
endstruc