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

DosSignatureWord           dw  0x5A4D
PESignatureWord            dd  0x50450000

struc DOSEXE
    signatureWord:  resw 1      ; Signature Word value should be 5A4DH
    lastPageSize:   resw 1      ; Last page size
    filePages:      resw 1      ; Pages (multiple of 512)
    relocItems:     resw 1
    hdrParagraphs:  resw 1
    minAlloc:       resw 1
    maxAlloc:       resw 1
    initSS:         resw 1
    initSP:         resw 1
    checksum:       resw 1
    initIP:         resw 1
    initCS:         resw 1
    relocTableOfs:  resw 1
    overlayNo:      resw 1
endstruc