; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; errors defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; error codes
%define kErrNone								0x0000

; general function/hardware errors
%define kErrInvalidParameter					0xF000
%define kErrValueTooLow							0xF001
%define kErrValueTooHigh						0xF002
%define kErrTimeout								0xF003

; filesystem errors
%define kErrDriveLetterInvalid					0xFB00
%define kErrPathInvalid							0xFB01
%define kErrPathInvalidCharacter				0xFB02
%define kErrItemNotFound						0xFB03
%define kErrClusterChainEndUnexpected			0xFB04
%define kErrRootDirectoryFull					0xFB05
%define kErrItemAlreadyExists					0xFB06
%define kErrClusterChainBad						0xFB07
%define kErrDirectoryNotEmpty					0xFB08
%define kErrNotADirectory						0xFB09

; partition errors
%define kErrInvalidPartitionNumber				0xFC00
%define kErrPartitionFull						0xFC01

; driver handler errors
%define kErrHandlerNotPresent					0xFD00
