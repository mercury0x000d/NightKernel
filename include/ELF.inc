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





; ELF data typing conventions (here for reference)
%define Elf32_Half								resw
%define Elf32_Off								resd
%define Elf32_Addr								resd
%define Elf32_Word								resd
%define	Elf32_SWord								resd

struc ELF32
	.EI_Mag0									resb 1					; signature byte 7F
	.EI_Mag1									resb 1					; signature byte 45
	.EI_Mag2									resb 1					; signature byte 4C
	.EI_Mag3									resb 1					; signature byte 46
	.EI_Class									resb 1					; 32/64 bit application
	.EI_Data									resb 1
	.EI_Version									resb 1					; ELF header version
	.EI_OSABI									resb 1
	.EI_ABIVersion								resb 1
	.EI_Pad										resb 7
	.E_Type										resw 1					; Object file type
	.E_Machine									resw 1					; Machine Type
	.E_Version									resd 1					; Object file version
	.E_Entry									resd 1					; Virtual address to where the system transfers control
	.E_PHOff									resd 1					; Program Header table offset
	.E_SHOff									resd 1					; Section Header table offset
	.E_Flags									resd 1					; Flags
	.E_Size										resw 1					; Header size (in bytes)
	.E_PHEntSize								resw 1					; Size of one entry in Program Header Table
	.E_PHNum									resw 1					; Number of entries in the Program Header Table
	.E_SHEntSize								resw 1					; Section Header size (in bytes)
	.E_SHNum									resw 1					; Number of entries in the Section Header Table
	.E_SHStrNdx									resw 1					; Index into the Section Header Table pointing to the Section Name String Table
endstruc

struc ProgramHeader
	.entryPoint									resd 1
	.programHeaderTablePtr						resd 1
	.sectionHeaderTablePtr						resd 1
	.imageFlags									resd 1
	.headerSize									resw 1
	.programHeaderTableEntrySize				resw 1
	.programHeaderTableEntryCount				resw 1
	.sectionHeaderTableEntrySize				resw 1
	.sectionHeaderTableEntryCount				resw 1
	.sectionHeaderTableNameIndex				resw 1
endstruc

struc SectionHeader
	.entryPoint									resd 1
	.programHeaderTablePtr						resd 1
	.sectionHeaderTablePtr						resd 1
	.imageFlags									resd 1
	.headerSize									resw 1
	.programHeaderTableEntrySize				resw 1
	.programHeaderTableEntryCount				resw 1
	.sectionHeaderTableEntrySize				resw 1
	.sectionHeaderTableEntryCount				resw 1
	.sectionHeaderTableNameIndex				resw 1
endstruc

; Architecture Constants
%define ELFNonSpec								0x00					; No specific architecture
%define ELFSPARC								0x02
%define ELFx86									0x03
%define ELFMIPS									0x08
%define ELFPowerPC								0x14
%define ELFARM									0x28
%define ELFSuperH								0x2A
%define ELFIA64									0x32
%define ELFX8664								0x3E
%define ELFAARCH64								0xB7

%define ET_None									0x0000					; No file type
%define ET_Rel									0x0001					; Relocatable file
%define ET_Exec									0x0002					; Executable file
%define ET_Dyn									0x0003					; Shared object file
%define ET_Core									0x0004					; Core file
%define ET_LoProc								0xFF00					; Processor specific
%define ET_HiProc								0xFFFF					; Processor specific

%define EM_None									0x00					; No machine
%define EM_M32									0x01					; AT&T WE 31200
%define EM_SPARC								0x02					; SPARC
%define EM_386									0x03					; Intel 386
%define EM_68K									0x04					; Motorola 68000
%define EM_88K									0x05					; Motorola 88000
%define EM_860									0x07					; Intel 80860
%define EM_MIPS									0x08					; MIPS R53000

%define EV_None									0x00					; Invalid version
%define EV_Current								0x01					; Current version

%define EI_Mag0									0						; File identification
%define EI_Mag1									1						; File identification
%define EI_Mag2									2						; File identification
%define EI_Mag3									3						; File identification
%define EI_Class								4						; File class
%define EI_Data									5						; Data encoding
%define EI_Version								6						; File version
%define EI_Pad									7						; Start of padding bytes
%define EI_NIdent								16						; size of e_ident[]

%define ELFMagic								db 0x7F, 'E', 'L', 'F'	; ELF Magic number
%define ELFMag0									equ 0x7F
%define ELFMag1									equ 'E'
%define ELFMag2									equ 'L'
%define ELFMag3									equ 'F'
%define ELFClassnone							equ 0					; invalid
%define ELFClass32								equ 1					; 32-bit objects
%define ELFClass64								equ 2					; 64-bit objects
%define ELFDatanone								equ 0					; Invalid data encoding
%define ELFData2LSB								equ 1
%define ELFData2MSB								equ 2

%define SHN_Undef								equ 0x0000				; undefined
%define SHN_LoReserve							equ 0xFF00				; Lower bound of the range of reserved indexes
%define SHN_LoProc								equ 0xFF00
%define SHN_HiProc								equ 0xFF1F
%define SHN_Abs									equ 0xFFF1
%define SHN_Common								equ 0xFFF2
%define SHN_HiReserve							equ 0xFFFF

; Section Header Types
%define SHT_Null								equ 0
%define SHT_Progbits							equ 1
%define SHT_SymTab								equ 2
%define SHT_StrTab								equ 3
%define SHT_Rela								equ 4
%define SHT_Hash								equ 5
%define SHT_Dynamic								equ 6
%define SHT_Note								equ 7
%define SHT_NoBits								equ 8
%define SHT_Rela								equ 9
%define SHT_ShLib								equ 10
%define SHT_DynSym								equ 11
%define SHT_LoProc								equ 0x70000000
%define SHT_HiProc								equ 0x7FFFFFFF
%define SHT_LoUser								equ 0x80000000
%define SHT_HiUser								equ 0x8FFFFFFF

struc ELF32_SecHeader
	.sh_name									resw 1					; Name of the section (index into the section header string table)
	.sh_type									resw 1
	.sh_flags									resw 1
	.sh_addr									resd 1
	.sh_offset									resd 1
	.sh_size									resw 1
	.sh_link									resw 1
	.sh_info									resw 1
	.sh_addralign								resw 1
	.sh_entsize									resw 1
endstruc