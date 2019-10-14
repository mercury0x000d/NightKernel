; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; IDE Controller defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%define kATAChannelPrimary						0x00
%define kATAChannelSecondary					0x01

%define kATACommandReadPIO						0x20
%define kATACommandReadPIOExt					0x24
%define kATACommandReadDMAExt					0x25
%define kATACommandWritePIO						0x30
%define kATACommandWritePIOExt					0x34
%define kATACommandWriteDMAExt					0x35
%define	kATACommandRead_Verify					0x40
%define	kATACommandDoDiagnostics				0x90
%define kATACommandPacket						0xA0
%define kATACommandIdentifyPacket				0xA1
%define kATACommandReadDMA						0xC8
%define kATACommandWriteDMA						0xCA
%define	kATACommandStandbyImmediate				0xE0
%define	kATACommandIdleImmediate				0xE1
%define	kATACommandStandby						0xE2
%define	kATACommandIdle							0xE3
%define	kATACommandCheckPowerMode				0xE5
%define	kATACommandSetSleepMode					0xE6
%define kATACommandCacheFlush					0xE7
%define kATACommandCacheFlushExt				0xEA
%define kATACommandIdentify						0xEC

%define kATADirectionRead						0x00
%define kATADirectionWrite						0x01

%define kATAErrorNoAddressMark					0x01
%define kATAErrorTrackZeroNotFound				0x02
%define kATAErrorCommandAborted					0x04
%define kATAErrorMediaChangeRequest				0x08
%define kATAErrorIDMarkNotFound					0x10
%define kATAErrorMediaChanged					0x20
%define kATAErrorUncorrectableData				0x40
%define kATAErrorBadBlock						0x80

%define kATARegisterData						0x00	; read/write
%define kATARegisterError						0x01	; read only
%define kATARegisterFeatures					0x01	; write only
%define kATARegisterSecCount0					0x02	; read/write
%define kATARegisterLBA0						0x03	; read/write
%define kATARegisterLBA1						0x04	; read/write
%define kATARegisterLBA2						0x05	; read/write
%define kATARegisterLBA3						0x03	; read/write?
%define kATARegisterLBA4						0x04	; read/write?
%define kATARegisterLBA5						0x05	; read/write?
%define kATARegisterHDDevSel					0x06	; read/write
%define kATARegisterCommand						0x07	; write only
%define kATARegisterStatus						0x07	; read only
%define kATARegisterSecCount1					0x08	; read/write?
%define kATARegisterControl						0x0C	; write only
%define kATARegisterAltStatus					0x0C	; read only
%define kATARegisterDeviceAddress				0x0D	; ?

%define	kATAResultOK							0x00
%define	kATAResultNoDrive						0x01
%define	kATAResultError							0x02
%define	kATAResultTimeout						0x03

%define kATAStatusError							0x01
%define kATAStatusIndex							0x02
%define kATAStatusCorrectedData					0x04
%define kATAStatusDataRequestReady				0x08
%define kATAStatusDriveSeekComplete				0x10
%define kATAStatusDriveWriteFault				0x20
%define kATAStatusDriveReady					0x40
%define kATAStatusBusy							0x80





; declare functions as global
global IDEATAPISectorReadPIO
global IDEATASectorReadLBA28PIO
global IDEATASectorWriteLBA28PIO
global IDEDetectChannelDevices
global IDEDriveIdentify
global IDEInit
global IDEInterruptHandlerPrimary
global IDEInterruptHandlerSecondary
global IDEServiceHandler
global IDEWaitForReady
