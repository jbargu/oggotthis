IMG=freedos.img
ASM=virus.asm
OBJECT=virus
FLOPPY=floppy.flp
BACKUP_MBR=freedos_backup.bin
RAINBOW=rainbow.asm

all: compile copy

$(OBJECT): $(ASM)
	nasm -f bin $(ASM)

run: $(FLOPPY) copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(IMG)

debug: $(FLOPPY) copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(IMG) -S -s

run-hd: $(FLOPPY) copy
	qemu-system-i386 -boot c -fda $(FLOPPY) -hda $(IMG)

debug-hd: $(FLOPPY) copy
	qemu-system-i386 -boot c -fda $(FLOPPY) -hda $(IMG) -S -s

gdb:
	gdb -x gdbinit

voltron:
	tmuxifier load-window voltron

copy: $(FLOPPY) $(OBJECT)
	dd if=$(OBJECT) of=$(FLOPPY) bs=512 count=1 conv=notrunc

rainbow:
	nasm -f bin $(RAINBOW)

backup: $(IMG)
	dd if=$(IMG) of=$(BACKUP_MBR) bs=512 count=1

restore: $(IMG)
	dd if=$(BACKUP_MBR) of=$(IMG) bs=512 count=1 conv=notrunc

$(FLOPPY): rainbow
	dd if=/dev/zero of=$(FLOPPY) bs=512 count=2880
	dd if=rainbow of=$(FLOPPY) bs=512 count=1 conv=notrunc seek=1

clean:
	rm $(OBJECT) $(FLOPPY) rainbow
