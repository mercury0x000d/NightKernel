; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; PS2MouseDefines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; mouse commands
%define kCmdSetScale							0xE6
%define kCmdSetResolution						0xE8
%define kCmdStatusRequest						0xE9
%define kCmdSetStreamMode						0xEA
%define kCmdReadData							0xEB
%define kCmdResetWrapMode						0xEC
%define kCmdSetWrapMode							0xEE
%define kCmdSetRemoteMode						0xF0



; declare functions as global
global PS2MouseInit
global PS2MouseInputHandler
