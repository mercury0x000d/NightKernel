; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
; elf.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

; Architecture Constants

ELF_NONSPEC         equ 0        ; No specific architecture
ELF_SPARC           equ 2        ; Sparc
ELF_X86             equ 3        ; x86
ELF_MIPS            equ 8        ; MIPS
ELF_POWERPC         equ 0x14     ; PowerPC
ELF_ARM             equ 0x28     ; ARM
ELF_SUPERH          equ 0x2A     ; SuperH
ELF_IA64            equ 0x32     ; IA-64
ELF_X8664           equ 0x3E     ; x86-64
ELF_AARCH64         equ 0xB7     ; AArch64

ET_NONE             equ 0        ; No file type
ET_REL              equ 1        ; Relocatable file
ET_EXEC             equ 2        ; Executable file
ET_DYN              equ 3        ; Shared object file
ET_CORE             equ 4        ; Core file
ET_LOPROC           equ 0xff00   ; Processor specific
ET_HIPROC           equ 0xffff   ; Processor specific

EM_NONE             equ 0        ; No machine
EM_M32              equ 1        ; AT&T WE 31200
EM_SPARC            equ 2        ; SPARC
EM_386              equ 3        ; Intel 386
EM_68K              equ 4        ; Motorola 68000
EM_88K              equ 5        ; Motorola 88000
EM_860              equ 7        ; Intel 80860
EM_MIPS             equ 8        ; MIPS R53000

EV_NONE             equ 0        ; Invalid version
EV_CURRENT          equ 1        ; Current version

EI_MAG0             equ 0        ; File identification
EI_MAG1             equ 1        ; File identification
EI_MAG2             equ 2        ; File identification
EI_MAG3             equ 3        ; File identification
EI_CLASS            equ 4        ; File class
EI_DATA             equ 5        ; Data encoding
EI_VERSION          equ 6        ; File version
EI_PAD              equ 7        ; Start of padding bytes
EI_NIDENT           equ 16       ; size of e_ident[]

ELFMAGIC            db 0x7F,'E','L','F' ; ELF Magic number
ELFMAG0             equ 0x7F
ELFMAG1             equ 'E'
ELFMAG2             equ 'L'
ELFMAG3             equ 'F'
ELFCLASSNONE        equ 0           ; invalid
ELFCLASS32          equ 1           ; 32-bit objects
ELFCLASS64          equ 2           ; 64-bit objects
ELFDATANONE         equ 0           ; Invalid data encoding
ELFDATA2LSB         equ 1           
ELFDATA2MSB         equ 2

SHN_UNDEF           equ 0           ; undefined
SHN_LORESERVE       equ 0xFF00      ; Lower bound of the range of reserved indexes
SHN_LOPROC          equ 0xFF00  
SHN_HIPROC          equ 0xFF1F
SHN_ABS             equ 0xFFF1
SHN_COMMON          equ 0xFFF2
SHN_HIRESERVE       equ 0xFFFF

; Section Header Types
SHT_NULL            equ 0
SHT_PROGBITS        equ 1
SHT_SYMTAB          equ 2
SHT_STRTAB          equ 3
SHT_RELA            equ 4
SHT_HASH            equ 5
SHT_DYNAMIC         equ 6
SHT_NOTE            equ 7
SHT_NOBITS          equ 8
SHT_RELA            equ 9
SHT_SHLIB           equ 10
SHT_DYNSYM          equ 11
SHT_LOPROC          equ 0x70000000
SHT_HIPROC          equ 0x7fffffff
SHT_LOUSER          equ 0x80000000
SHT_HIUSER          equ 0x8fffffff

struc ELF32
    elfName:        resb 16     ; Identification
    elfType:        resw 1      ; Object file type
    elfMachine:     resw 1      ; Machine Type
    elfVersion:     resw 1      ; Object file version
    elfEntry:       resd 1      ; Virtual address to where the system transfers control
    elfPhOff:       resd 1      ; Program Header table file offset
    elfShoff:       resd 1      ; Section Header table file offset
    elfFlags:       resw 1      ; Flags
    elfSize:        resw 1      ; Header size (in bytes)
    elfPhentSize:   resw 1      ; Size of one entry in program header table
    elfPhNum:       resw 1      ; Number of entries in the program header table
    elfShentSize:   resw 1      ; Section header size (in bytes)
    elfShnum:       resw 1      ; Number of entries in the section header table
    elfShstrNdx:    resw 1      ; Section header table index
endstruc

struc ELF32_SECHEADER
    sh_name:        resw 1      ; Name of the section (index into the section header string table)
    sh_type:        resw 1      
    sh_flags:       resw 1
    sh_addr:        resd 1
    sh_offset:      resd 1
    sh_size:        resw 1
    sh_link:        resw 1
    sh_info:        resw 1
    sh_addralign:   resw 1
    sh_entsize:     resw 1
endstruc