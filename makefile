# let's make a kernel image. or test it out. or both! :D

asflags = -f bin -F null -g -l night.lst



build:
	$(info Assembling the Night Kernel...)
	@nasm $(asflags) -o builds/kernel.sys kernel.asm
	@./xenops --file system/globals.asm



updateimage:
	$(info Making a folder to which we will mount the vdi image...)
	@mkdir VBoxDisk -p

	$(info Disposing of a possible previous instance of the loop device...)
	@sudo losetup -d /dev/loop0 || true

	$(info Mounting existing drive image to folder "VBoxDisk" using loop device...)
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	$(info Deleting old kernel image from virtual disk...)
	@sudo rm ./VBoxDisk/kernel.sys

	$(info Copying new kernel to virtual disk...)
	@sudo cp "builds/kernel.sys" "./VBoxDisk/kernel.sys"

	$(info Unmounting virtual disk...)
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	$(info Removing loop device...)
	@sudo losetup -d /dev/loop0



run:
	$(info Booting VM. (Press Ctrl-C in this terminal to end.))
	@virtualbox --startvm "Night" --debug-command-line --start-running



all:
	$(info Assembling the Night Kernel...)
	@nasm $(asflags) -o builds/kernel.sys kernel.asm
	@./xenops --file system/globals.asm

	$(info Making a folder to which we will mount the vdi image...)
	@mkdir VBoxDisk -p

	$(info Disposing of a possible previous instance of the loop device...)
	@sudo losetup -d /dev/loop0 || true

	$(info Mounting existing drive image to folder "VBoxDisk" using loop device...)
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	$(info Deleting old kernel image from virtual disk...)
	@sudo rm ./VBoxDisk/kernel.sys

	$(info Copying new kernel to virtual disk...)
	@sudo cp "builds/kernel.sys" "./VBoxDisk/kernel.sys"

	$(info Unmounting virtual disk...)
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	$(info Removing loop device...)
	@sudo losetup -d /dev/loop0

	$(info Build complete, booting VM. (Press Ctrl-C in this terminal to end.))
	@virtualbox --startvm "Night" --debug-command-line --start-running

# should there be an issue trying the previous functions (or if you just want to 
# test it a different way) try this one. make sure you have a 
# snapshot so you can revert back after testing. (You need to install FD manually on the VM btw)
manual:
	$(info Assembling the Night Kernel...)
	@nasm $(asflags) -o builds/kernel.sys kernel.asm

	$(info Making ISO image...)
	mkisofs -o builds/kernel.iso builds/kernel.sys docs/scripts/kcopy.bat

	$(info Build complete, booting VM. (Press Ctrl-C in this terminal to end.))
	@virtualbox --startvm "Night" --debug-command-line --start-running

	# of course, we update the kernel build number with the best tool on earth ever made! :P
	./xenops --file globals.asm

