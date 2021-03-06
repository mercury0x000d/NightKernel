; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; tasks defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; a 1 KiB stack is almost guaranteed to be too small in the future!
%define taskStackSize							1024
%define taskKernelStackSize						1024





; tTaskInfo struct, used to... *GASP* manage tasks (96 bytes)
struc tTaskInfo
	.pageDirAddress								resd 1
	.entryPoint									resd 1
	.esp										resd 1
	.esp0										resd 1
	.stackAddress								resd 1
	.kernelStackAddress							resd 1
	.priority									resb 1
	.turnsRemaining								resb 1
	.unused										resw 1
	.switchInLow								resd 1
	.switchInHigh								resd 1
	.cycleCountLow								resd 1
	.cycleCountHigh								resd 1
	.spawnedBy									resd 1
	.taskFlags									resd 1
	.name										resb 44
endstruc





; declare functions as global
global TaskInit
global TaskKill
global TaskMemDisposeAll
global TaskNameSet
global TaskNew
global TaskSwitch
