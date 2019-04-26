# Night Kernel
# Copyright 1995 - 2019 by mercury0x0d
# Makefile is a part of the Night Kernel

# The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
# version.

# The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY# without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
# <http://www.gnu.org/licenses/>.

# See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

ARCH			:= i686
FRMT			:= elf

#Directories
OBJDIR			:= obj
OUTPUTDIR		:= output
BUILDDIR		:= builds
ASMINCLUDEPATH	:= ./include/
TARGET			:= $(OUTPUTDIR)/kernel.sys

# Compilers
# CC 				:= $(ARCH)-$(FRMT)-gcc
# LD				:= $(ARCH)-$(FRMT)-ld
LD				:= ld
ASM				:= nasm
RM				:= rm
ASMFLAGS 		:= -f elf -I$(ASMINCLUDEPATH)
LDOPTIONS		:= -m elf_i386
COPTIONS		:= -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
				   -nostartfiles -nodefaultlibs

WARNINGS 		:= -Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
					-Wwrite-strings -Wmissing-prototypes -Wmissing-declarations \
					-Wredundant-decls -Wnested-externs -Winline -Wno-long-long \
					-Wconversion -Wstrict-prototypes

PROJDIRS			:= api drivers include io system video
.PHONY:  all clean dist

# Get the folders together
ASMSRCFILES		:= kernel.asm $(shell find $(PROJDIRS) -type f -name "*.asm")
# ASMSRCFILES		:= $(foreach DIR, $(PROJDIRS), $(wildcard $(DIR/*.asm)))
ASMINCFILES		:= $(shell find $(PROJDIRS) -type f -name "*.inc")

# OBJFILES		:= $(patsubst %.asm, %.o, $(ASMSRCFILES))
OBJFILES		:= $(foreach OBJECT, $(patsubst %.asm, %.o, $(ASMSRCFILES)), $(OBJDIR)/$(OBJECT))

# Misc stuff
LOOPDEVICE		:= /dev/loop0
VBOXIMAGE		:= $(BUILDDIR)/Night.vdi

# General make rules
print-% : ; @echo $* = $($*)
# target: help - Display callable targets.
help:
	@egrep "^# target:" [Mm]akefile
	$(info ASMSRCFILES = $(ASMSRCFILES))
	$(info ASMINCFILES = $(ASMINCFILES))
	$(info OBJFILES = $(OBJFILES))
	$(info OBJDIR = $(OBJDIR))
	$(info TARGET = $(TARGET))
	$(info BUILDDIR = $(BUILDDIR))
	$(info LOOPDEVICE = $(LOOPDEVICE))
	$(info VBOXIMAGE = $(VBOXIMAGE))
	$(info LINKER = $(LD) $(LDOPTIONS))

all : $(TARGET)

#$(TARGET) : $(OBJFILES)
#   mkdir -p $(@D)
#   $(LD) $(LDOPTIONS) -o $@ -T linker.ld $+

$(TARGET): $(OBJFILES) 
	mkdir -p $(@D)
	$(info Makes the final output kernel file from $(OBJFILES))
	$(LD) -T linker.ld $(LDOPTIONS) -o $@ $(OBJFILES)

$(OBJDIR)/%.o : %.asm
	@mkdir -p $(@D)
	$(info ==== .asm($<) -> .o($@) rule)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.o : %.c
	@mkdir -p $(@D)
	$(info ==== .c($<) -> .o($@) rule)
	$(CC) $(COPTIONS) $(WARNINGS) -o $@ $<

os.vm: $(TARGET)
	mkdir VBoxDisk -p 
	sudo losetup -d $(LOOPDEVICE) || true 
	sudo losetup $(LOOPDEVICE) ./builds/Night.vdi -o 2129408
	sudo mount $(LOOPDEVICE) ./VBoxDisk
	sudo rm ./VBoxDisk/kernel.sys
	sudo cp "$(TARGET)" "./VBoxDisk/kernel.sys"
	sudo umount ./VBoxDisk
	$(RM) -r VBoxDisk
	sudo losetup -d /dev/loop0

clean:
	-$(RM) $(wildcard $(OBJFILES) kernel.o kernel.bin kernel.sys)
	-$(RM) -r $(OBJDIR)
	-$(RM) -r $(OUTPUTDIR)
	
