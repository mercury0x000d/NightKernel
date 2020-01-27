; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; tasks.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.


extern tTaskInfo.pageDirAddress
extern tTaskInfo.entryPoint
extern tTaskInfo.esp
extern tTaskInfo.esp0
extern tTaskInfo.stackAddress
extern tTaskInfo.kernelStackAddress
extern tTaskInfo.priority
extern tTaskInfo.turnsRemaining
extern tTaskInfo.unused
extern tTaskInfo.switchInLow
extern tTaskInfo.switchInHigh
extern tTaskInfo.cycleCountLow
extern tTaskInfo.cycleCountHigh
extern tTaskInfo.spawnedBy
extern tTaskInfo.taskFlags
extern tTaskInfo.name

; function definitions
extern TaskInit
extern TaskKill
extern TaskMemDisposeAll
extern TaskNameSet
extern TaskNew
extern TaskSwitch
