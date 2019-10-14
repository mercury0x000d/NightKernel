; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; PS2 Controller.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; variable definitions
%include "include/PS2 Controller defines.inc"





; function definitions
extern PS2ControllerCommand
extern PS2ControllerInit
extern PS2ControllerPortTest
extern PS2ControllerWaitDataRead
extern PS2ControllerWaitDataWrite
extern PS2DeviceCommand
extern PS2DeviceIdentify
extern PS2InitKeyboard
extern PS2InitMouse
extern PS2InputHandlerDispatch
extern PS2InputHandlerKeyboard
extern PS2InputHandlerMouse
extern PS2NewConnect
extern PS2Port1InterruptHandler
extern PS2Port2InterruptHandler
extern PS2PortInitDevice
extern PS2PortSendTo2
