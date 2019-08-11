# let's make a kernel image. or test it out. or both! :D

asflags = -f bin -F null -g -l night.lst



allcd:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/KERNEL.SYS kernel.asm

	${Copy built kernel to CD image}
	mkisofs -o builds/kernel.iso builds/KERNEL.SYS scripts/kcopy.bat

	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running



allhd:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/KERNEL.SYS kernel.asm

	${Make a folder to which we will mount the vdi image}
	@mkdir VBoxDisk -p

	${Dispose of a possible previous instance of the loop device}
	@sudo losetup -d /dev/loop0 || true

	${Mount existing drive image to folder "VBoxDisk" using loop device}
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	${Delete old kernel image from virtual disk}
	@sudo rm ./VBoxDisk/KERNEL.SYS

	${Copy built kernel to VDI image}
	@sudo cp "builds/KERNEL.SYS" "./VBoxDisk/KERNEL.SYS"

	${Unmount virtual disk}
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	${Remove loop device}
	@sudo losetup -d /dev/loop0

	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running


build:
	${Assemble the Night Kernel}
	@nasm $(asflags) -o builds/KERNEL.SYS kernel.asm



imagecd:
	${Copy built kernel to CD image}
	mkisofs -o builds/kernel.iso builds/KERNEL.SYS scripts/kcopy.bat



imagehd:
	${Make a folder to which we will mount the vdi image}
	@mkdir VBoxDisk -p

	${Dispose of a possible previous instance of the loop device}
	@sudo losetup -d /dev/loop0 || true

	${Mount existing drive image to folder "VBoxDisk" using loop device}
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk

	${Delete old kernel image from virtual disk}
	@sudo rm ./VBoxDisk/KERNEL.SYS

	${Copy built kernel to VDI image}
	@sudo cp "builds/KERNEL.SYS" "./VBoxDisk/KERNEL.SYS"

	${Unmount virtual disk}
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	${Remove loop device}
	@sudo losetup -d /dev/loop0



mount:
	${Make a folder to which we will mount the vdi image}
	@mkdir VBoxDisk -p

	${Dispose of a possible previous instance of the loop device}
	@sudo losetup -d /dev/loop0 || true

	${Mount existing drive image to folder "VBoxDisk" using loop device}
	@sudo losetup /dev/loop0 ./builds/Night.vdi -o 2129408
	@sudo mount /dev/loop0 ./VBoxDisk


run:
	$(info Press Ctrl-C in this terminal to end VM execution.)
	@virtualbox --startvm "Night" --debug-command-line --start-running



unmount:
	${Unmount virtual disk}
	@sudo umount ./VBoxDisk
	@sudo rmdir VBoxDisk

	${Remove loop device}
	@sudo losetup -d /dev/loop0
