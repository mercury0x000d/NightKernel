# let's make a kernel image. or test it out. or both! :D

asflags = -f bin -F null -g -l night.lst



build:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/kernel.sys kernel.asm



imagehd:
	${Make a folder to which we will mount the vdi image}
	@mkdir VBoxDisk -p

	${Dispose of a possible previous instance of the loop device}
	@sudo losetup -d /dev/loop0 || true

	${Mount existing drive image to folder "VBoxDisk" using loop device}
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	${Delete old kernel image from virtual disk}
	@sudo rm ./VBoxDisk/kernel.sys

	${Copy built kernel to VDI image}
	@sudo cp "builds/kernel.sys" "./VBoxDisk/kernel.sys"

	${Unmount virtual disk}
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	${Remove loop device}
	@sudo losetup -d /dev/loop0



imagecd:
	${Copy built kernel to CD image}
	mkisofs -o builds/kernel.iso builds/kernel.sys scripts/kcopy.bat



run:
	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running



allhd:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/kernel.sys kernel.asm

	${Make a folder to which we will mount the vdi image}
	@mkdir VBoxDisk -p

	${Dispose of a possible previous instance of the loop device}
	@sudo losetup -d /dev/loop0 || true

	${Mount existing drive image to folder "VBoxDisk" using loop device}
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	${Delete old kernel image from virtual disk}
	@sudo rm ./VBoxDisk/kernel.sys

	${Copy built kernel to VDI image}
	@sudo cp "builds/kernel.sys" "./VBoxDisk/kernel.sys"

	${Unmount virtual disk}
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	${Remove loop device}
	@sudo losetup -d /dev/loop0

	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running



allcd:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/kernel.sys kernel.asm

	${Copy built kernel to CD image}
	mkisofs -o builds/kernel.iso builds/kernel.sys scripts/kcopy.bat

	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running
