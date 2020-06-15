; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; eventsDefines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; event types
%define kEvtKeyDown								1
%define kEvtKeyUp								2
%define kEvtMouseDown							4
%define kEvtMouseMove							8
%define kEvtMouseUp								16
%define kEvtSystem								32


%define kEvtFlagAlt								1
%define kEvtFlagAltLeft							2
%define kEvtFlagAltRight						4
%define kEvtFlagCtrl							8
%define kEvtFlagCtrlLeft						16
%define kEvtFlagCtrlRight						32
%define kEvtFlagLockCaps						64
%define kEvtFlagLockNum							128
%define kEvtFlagLockScroll						256
%define kEvtFlagShift							512
%define kEvtFlagShiftLeft						1024
%define kEvtFlagShiftRight						2048





; event struct
struc tEvent
	.what										resd 1
	.from										resd 1
	.message									resd 1
	.when										resd 1
	.whereX										resd 1
	.whereY										resd 1
	.evtFlags									resd 1
	.reserved									resd 1
endstruc





; declare functions as global
global something