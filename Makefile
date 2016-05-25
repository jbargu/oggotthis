IMG=freedos.img
ASM=virus.asm
OBJECT=virus
FLOPPY=floppy.flp
BACKUP_MBR=freedos_backup.bin

all: compile copy

$(OBJECT): $(ASM)
	nasm -f bin $(ASM)

run: $(FLOPPY) copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(IMG)

debug: $(FLOPPY) copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(IMG) -S -s

gdb:
	gdb -x gdbinit

voltron:
	tmuxifier load-window voltron

copy: $(FLOPPY) $(OBJECT)
	dd if=$(OBJECT) of=$(FLOPPY) bs=512 count=1 conv=notrunc

backup: $(IMG)
	dd if=$(IMG) of=$(BACKUP_MBR) bs=512 count=1

restore: $(IMG)
	dd if=$(BACKUP_MBR) of=$(IMG) bs=512 count=1 conv=notrunc

$(FLOPPY):
	dd if=/dev/zero of=$(FLOPPY) bs=512 count=2880


