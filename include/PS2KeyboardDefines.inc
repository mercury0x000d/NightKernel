; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; PS2KeyboardDefines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; keyboard commands
%define kLockScroll								0
%define kLockNum								1
%define kLockCaps								2



; keyboard commands
%define kCmdKeyboardSetLEDs						0xED
%define kCmdKeyboardEcho						0xEE
%define kCmdKeyboardGetSetScanCode				0xF0
%define kCmdKeyboardSetAllKeysAutorepeat		0xF7
%define kCmdKeyboardSetAllKeysMakeRelease		0xF8
%define kCmdKeyboardSetAllKeysMake				0xF9
%define kCmdKeyboardSetAllKeysAutorepeat		0xFA
%define kCmdKeyboardSetKeyAutorepeat			0xFB
%define kCmdKeyboardSetKeyMakeRelease			0xFC
%define kCmdKeyboardSetKeyMake					0xFD



; declare functions as global
global PS2KeyboardInit
global PS2KeyboardInputHandler
