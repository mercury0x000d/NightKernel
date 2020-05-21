; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; lists defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; List Manager errors
%define kErrListInvalid							0xF900
%define kErrElementSizeInvalid					0xF901
%define kErrBitfieldInvalid						0xF902





; tBitfieldInfo struct, used to manage bitfields
struc tBitfieldInfo
	.signature									resd 1
	.setCount									resd 1
	.elementCount								resd 1
	.listSize									resd 1
endstruc

; tListInfo struct, used to manage lists
struc tListInfo
	.signature									resd 1
	.elementSize								resd 1
	.elementCount								resd 1
	.listSize									resd 1
endstruc





; declare functions as global
global LMBitfieldInit
global LMBitfieldScanClear
global LMBitfieldScanSet
global LMBitfieldSpaceCalc
global LMBitfieldValidate
global LMBitfieldValidateElement
global LMBitClear
global LMBitClearRange
global LMBitFlip
global LMBitFlipRange
global LMBitGet
global LMBitSet
global LMBitSetRange
global LMCountBitsSet
global LMElementAddressGet
global LMElementCountGet
global LMElementCountSet
global LMElementDelete
global LMElementDuplicate
global LMElementSizeGet
global LMElementValidate
global LMItemAddAtSlot
global LMListCompact
global LMListInit
global LMListSearch
global LMListSpaceCalc
global LMListValidate
global LMSlotFindFirstFree
global LMSlotFreeTest
