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
OBJDIR			:= builds/obj
OUTPUTDIR		:= builds
ASMINCLUDEPATH	:= ./include
TARGET			:= $(OUTPUTDIR)/KERNEL.SYS
SCRIPTS			:= ./scripts

# ISO stuff
ISO_TARGET		:= $(OUTPUTDIR)/NIGHT.ISO
ISO_SCRIPTS 	:= $(SCRIPTS)/kcopy.bat
# Where ISO_LINUX lives on your system
ISOLINUX 		:= ./boot/isolinux

# A floppy image is needed to boot with ISOLINUX
# besides, it may be handy to be able to test on older systems
FLOPPY			:= $(OUTPUTDIR)/NIGHT.IMG


# Compilers
ASM				:= nasm
ASMFLAGS 		:= -f elf -I$(ASMINCLUDEPATH)
# CC 				:= $(ARCH)-$(FRMT)-gcc
COPTIONS		:= -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs
LD				:= ld
LDOPTIONS		:= -T scripts/linker.ld -m elf_i386 --sort-common
RM				:= rm
WARNINGS 		:= -Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings \
					-Wmissing-prototypes -Wmissing-declarations -Wredundant-decls -Wnested-externs \
					-Winline -Wno-long-long -Wconversion -Wstrict-prototypes




# Get the folders together
PROJDIRS		:= api drivers include io system video
SRCFILES		:=  kernel.asm $(foreach DIR, $(PROJDIRS), $(wildcard $(DIR)/*.asm $(DIR)/*.c))
ASMINCFILES		:= $(shell find $(PROJDIRS) -type f -name "*.inc")
OBJFILES		:= $(foreach OBJECT, $(patsubst %.asm, %.o, $(patsubst %.c, %.o, $(SRCFILES))), $(OBJDIR)/$(OBJECT))
LOOPDEVICE		:= /dev/loop0



# General make rules
build : $(TARGET)
$(OBJDIR)/%.o : %.asm
	@mkdir -p $(@D)
	$(info ==== .asm($<) -> .o($@) rule)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(TARGET): $(OBJFILES) 
	mkdir -p $(@D)
	$(info Makes the final output kernel file from $(OBJFILES))
	$(LD)  $(LDOPTIONS) -o $@ $(OBJFILES) --cref --print-map > $(OUTPUTDIR)/kernel.map



clean:
	-$(RM) $(wildcard $(OBJFILES) kernel.o kernel.bin KERNEL.SYS)
	-$(RM) -r $(OBJDIR)



floppy:
	-mkdir $(OUTPUTDIR)/floppy
	sudo mount -o loop $(FLOPPY) $(OUTPUTDIR)/floppy
	sudo cp $(TARGET) $(OUTPUTDIR)/floppy/KERNEL.SYS
	sudo umount $(OUTPUTDIR)/floppy
	sudo rm -r builds/floppy	



# target: help - Display callable targets.
help:
	@egrep "^# target:" [Mm]akefile
	$(info SRCFILES = $(SRCFILES))
	$(info ASMINCFILES = $(ASMINCFILES))
	$(info OBJFILES = $(OBJFILES))
	$(info OBJDIR = $(OBJDIR))
	$(info TARGET = $(TARGET))
	$(info LOOPDEVICE = $(LOOPDEVICE))
	$(info LINKER = $(LD) $(LDOPTIONS))



iso: $(TARGET) floppy
	mkdir $(OUTPUTDIR)/CD_root
	mkdir $(OUTPUTDIR)/CD_root/isolinux
	mkdir $(OUTPUTDIR)/CD_root/images
	mkdir $(OUTPUTDIR)/CD_root/kernel
	cp $(ISOLINUX)/isolinux.bin $(OUTPUTDIR)/CD_root/isolinux/isolinux.bin
	cp $(ISOLINUX)/isolinux.cfg $(OUTPUTDIR)/CD_root/isolinux/isolinux.cfg
	cp $(FLOPPY) $(OUTPUTDIR)/CD_root/images/NIGHT.IMG
	cp $(ISOLINUX)/memdisk $(OUTPUTDIR)/CD_root/kernel/memdisk
	mkisofs -o $(OUTPUTDIR)/NIGHT.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
	 -no-emul-boot -boot-load-size 4 -boot-info-table $(OUTPUTDIR)/CD_root
	rm -r $(OUTPUTDIR)/CD_root



print-%:
	@echo $* = $($*)



run:
	virtualbox --startvm "Night" --debug-command-line --start-running



update:
	./scripts/xenops --file "include/globalsDefines.inc"



vm: $(TARGET)
	mkdir VBoxDisk -p
	sleep .05
	sudo losetup -d $(LOOPDEVICE) || true
	sleep .05
	sudo losetup $(LOOPDEVICE) ./builds/Night.vdi -o 2129408
	sleep .05
	sudo mount $(LOOPDEVICE) ./VBoxDisk
	sleep .05
	sudo rm ./VBoxDisk/KERNEL.SYS
	sleep .05
	sudo cp "$(TARGET)" "./VBoxDisk/KERNEL.SYS"
	sleep .05
	sudo umount ./VBoxDisk
	sleep .05
	$(RM) -r VBoxDisk
	sleep .05
	sudo losetup -d /dev/loop0
