; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
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

; PS/2 PS/2 Controller Configuration Byte bits
%define kCCBPort1IRQ							1
%define kCCBPort2IRQ							2
%define kCCBPOSTFlag							4
%define kCCBPort1Disable						16
%define kCCBPort2Disable						32
%define kCCBPort1Translation					64

%define kPS2TimeoutTicks						64			; 0.25 seconds
%define kPS2DataPort							0x60
%define kPS2StatusRegister						0x64
%define kPS2CommandRegister						0x64

; device types
%define kDevNone								0xFFFF		; technically, an oooooold AT keyboard would return this as well since it doesn't support the Identify commnad, but... we won't support that.
%define kDevMouseStandard						0xFF00
%define kDevTrackball							0xFF02
%define kDevMouseWheel							0xFF03
%define kDevMouse5Button						0xFF04
%define kDevKeyboardMFWithTranslation1			0xAB41
%define kDevKeyboardMF							0xAB83
%define kDevKeyboardMFWithTranslation2			0xABC1

; PS/2 Controller commands
%define kCmdReadConfigByte						0x20
%define kCmdReadMemoryByte00					0x20
%define kCmdReadMemoryByte01					0x21
%define kCmdReadMemoryByte02					0x22
%define kCmdReadMemoryByte03					0x23
%define kCmdReadMemoryByte04					0x24
%define kCmdReadMemoryByte05					0x25
%define kCmdReadMemoryByte06					0x26
%define kCmdReadMemoryByte07					0x27
%define kCmdReadMemoryByte08					0x28
%define kCmdReadMemoryByte09					0x29
%define kCmdReadMemoryByte10					0x2A
%define kCmdReadMemoryByte11					0x2B
%define kCmdReadMemoryByte12					0x2C
%define kCmdReadMemoryByte13					0x2D
%define kCmdReadMemoryByte14					0x2E
%define kCmdReadMemoryByte15					0x2F
%define kCmdReadMemoryByte16					0x30
%define kCmdReadMemoryByte17					0x31
%define kCmdReadMemoryByte18					0x32
%define kCmdReadMemoryByte19					0x33
%define kCmdReadMemoryByte20					0x34
%define kCmdReadMemoryByte21					0x35
%define kCmdReadMemoryByte22					0x36
%define kCmdReadMemoryByte23					0x37
%define kCmdReadMemoryByte24					0x38
%define kCmdReadMemoryByte25					0x39
%define kCmdReadMemoryByte26					0x3A
%define kCmdReadMemoryByte27					0x3B
%define kCmdReadMemoryByte28					0x3C
%define kCmdReadMemoryByte29					0x3D
%define kCmdReadMemoryByte30					0x3E
%define kCmdReadMemoryByte31					0x3F

%define kCmdWriteConfigByte						0x60
%define kCmdWriteMemoryByte00					0x60
%define kCmdWriteMemoryByte01					0x61
%define kCmdWriteMemoryByte02					0x62
%define kCmdWriteMemoryByte03					0x63
%define kCmdWriteMemoryByte04					0x64
%define kCmdWriteMemoryByte05					0x65
%define kCmdWriteMemoryByte06					0x66
%define kCmdWriteMemoryByte07					0x67
%define kCmdWriteMemoryByte08					0x68
%define kCmdWriteMemoryByte09					0x69
%define kCmdWriteMemoryByte10					0x6A
%define kCmdWriteMemoryByte11					0x6B
%define kCmdWriteMemoryByte12					0x6C
%define kCmdWriteMemoryByte13					0x6D
%define kCmdWriteMemoryByte14					0x6E
%define kCmdWriteMemoryByte15					0x6F
%define kCmdWriteMemoryByte16					0x70
%define kCmdWriteMemoryByte17					0x71
%define kCmdWriteMemoryByte18					0x72
%define kCmdWriteMemoryByte19					0x73
%define kCmdWriteMemoryByte20					0x74
%define kCmdWriteMemoryByte21					0x75
%define kCmdWriteMemoryByte22					0x76
%define kCmdWriteMemoryByte23					0x77
%define kCmdWriteMemoryByte24					0x78
%define kCmdWriteMemoryByte25					0x79
%define kCmdWriteMemoryByte26					0x7A
%define kCmdWriteMemoryByte27					0x7B
%define kCmdWriteMemoryByte28					0x7C
%define kCmdWriteMemoryByte29					0x7D
%define kCmdWriteMemoryByte30					0x7E
%define kCmdWriteMemoryByte31					0x7F

%define kCmdDisablePort2						0xA7
%define kCmdEnablePort2							0xA8
%define kCmdTestPort2							0xA9
%define kCmdTestController						0xAA
%define kCmdTestPort1							0xAB
%define kCmdDumpMemory							0xAC
%define kCmdDisablePort1						0xAD
%define kCmdEnablePort1							0xAE
%define kCmdReadInputPort						0xC0
%define kCmdCopyNibble1to2						0xC1
%define kCmdCopyNibble2to1						0xC2
%define kCmdReadOutputPort						0xD0
%define kCmdWriteControllerOutputPort			0xD1
%define kCmdWritePort1OutputPort				0xD2
%define kCmdWritePort2OutputPort				0xD3
%define kCmdWritePort2InputPort					0xD4
%define kCmdPulseOutputLines0000				0xF0
%define kCmdPulseOutputLines0001				0xF1
%define kCmdPulseOutputLines0010				0xF2
%define kCmdPulseOutputLines0011				0xF3
%define kCmdPulseOutputLines0100				0xF4
%define kCmdPulseOutputLines0101				0xF5
%define kCmdPulseOutputLines0110				0xF6
%define kCmdPulseOutputLines0111				0xF7
%define kCmdPulseOutputLines1000				0xF8
%define kCmdPulseOutputLines1001				0xF9
%define kCmdPulseOutputLines1010				0xFA
%define kCmdPulseOutputLines1011				0xFB
%define kCmdPulseOutputLines1100				0xFC
%define kCmdPulseOutputLines1101				0xFD
%define kCmdPulseOutputLines1110				0xFE
%define kCmdPulseOutputLines1111				0xFF

%define kControllerPortTestPass					0x00
%define kControllerPortClockLineStuckLow		0x01
%define kControllerPortClockLineStuckHigh		0x02
%define kControllerPortDataLineStuckLow			0x03
%define kControllerPortDataLineStuckHigh		0x04
%define kControllerTestPass						0x55
%define kControllerTestFail						0xFC

; commands common to all (most?) devices
%define kCmdGetDeviceID							0xF2
%define kCmdSetRate								0xF3
%define kCmdEnableDataReporting					0xF4
%define kCmdDisableDataReporting				0xF5
%define kCmdDeviceUseDefaultSettings			0xF6
%define kCmdDeviceResend						0xFE
%define kCmdDeviceReset							0xFF

; device command responses
%define kBufferOverrun1							0x00
%define kTestPass								0xAA
%define kEcho									0xEE
%define kCmdAcknowledged						0xFA
%define kTestFail1								0xFC
%define kTestFail2								0xFD
%define kResend									0xFE
%define kBufferOverrun2							0xFF



; declare functions as global
global PS2BufferClear
global PS2ControllerCommand
global PS2ControllerInit
global PS2ControllerPortTest
global PS2ControllerRead
global PS2ControllerReadWait
global PS2ControllerWrite
global PS2ControllerWriteWait
global PS2DeviceAnnounce
global PS2DeviceIdentify
global PS2DeviceWrite
global PS2InputHandlerDispatch
global PS2NewConnect
global PS2Port1InterruptHandler
global PS2Port2InterruptHandler
global PS2PortInitDevice
global PS2PortsDisable
global PS2PortsEnable
global PS2TestPorts
