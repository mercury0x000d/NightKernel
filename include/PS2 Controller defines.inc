; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; PS2 Controller defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; PS/2 controller errors
%define kErrPS2AckFail							0xFF00
%define kErrPS2ControllerReadTimeout			0xFF01
%define kErrPS2ControllerWriteTimeout			0xFF02





; declare functions as global
global PS2ControllerCommand
global PS2ControllerInit
global PS2ControllerPortTest
global PS2ControllerWaitDataRead
global PS2ControllerWaitDataWrite
global PS2DeviceCommand
global PS2DeviceIdentify
global PS2InitKeyboard
global PS2InitMouse
global PS2InputHandlerDispatch
global PS2InputHandlerKeyboard
global PS2InputHandlerMouse
global PS2NewConnect
global PS2Port1InterruptHandler
global PS2Port2InterruptHandler
global PS2PortInitDevice
global PS2PortSendTo2
