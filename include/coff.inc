; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
; coff.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

; COFF Magic Number
I386MAGIC                       dw 0x014C
I386AIXMAGIC                    dw 0x0175

; COFF Characteristics

IMAGE_FILE_RELOCS_STRIPPED      dw 0x0001
IMAGE_FILE_EXECUTABLE_IMAGE     dw 0x0002    ; Image only
IMAGE_FILE_LINE_NUMS_STRIPPED   dw 0x0004
IMAGE_FILE_LOCAL_SYMS_STRIPPED  dw 0x0008   
IMAGE_FILE_AGGRESSIVE_WS_TRIM   dw 0x0010
IMAGE_FILE_LARGE_ADDRESS_AWARE  dw 0x0020

; COFF File Header Flags
F_RELFLG                        dw 0x0001    ; Relocation information stripped from the file
F_EXEC                          dw 0x0002    ; The file is relocatable (no unresolved external references)
F_LNNO                          dw 0x0004    ; Line numbers stripped
F_LSYMS                         dw 0x0008    ; Local symbols stripped from the file

struc COFFHEADER
    CoffMagicNumber:           resw 1      ; Magic Number
    CoffNumSectionHeaders:      resw 1      ; Number of Section headers
    CoffTimeDateStamp:          resd 1      ; TimeDate Stamp when the file was created
    CoffSymbolTablePointer:     resd 1      ; Starting address of symbol table
    CoffSymbolTableEntries:     resd 1      ; Number of entries in the symbol table
    CoffOptionalHeaderSize:     resw 1      ; Number of bytes in optional header
    CoffFlags:                  resw 1      ; Flags
    CoffTargetID:               resw 1      ; Target ID
endstruc