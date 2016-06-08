IMG=freedos.img
ASM=virus.asm
OBJECT=virus
FLOPPY=floppy.flp
BACKUP_MBR=freedos_backup.bin
RAINBOW=rainbow.asm
READ_DSK=read_disk.asm
RD_OBJECT=read_disk
HD=freedos.img

all: compile copy

$(OBJECT): $(ASM)
	nasm -f bin $(ASM)

run: $(FLOPPY) $(HD) restore copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(HD)

debug: $(FLOPPY) restore copy
	qemu-system-i386 -boot a -fda $(FLOPPY) -hda $(HD) -S -s

run-hd: $(FLOPPY) $(HD) copy
	qemu-system-i386 -boot c -fda $(FLOPPY) -hda $(HD)

debug-hd: $(FLOPPY) copy
	qemu-system-i386 -boot c -fda $(FLOPPY) -hda $(HD) -S -s

gdb:
	gdb -x gdbinit

copy: $(FLOPPY) $(OBJECT)
	dd if=$(OBJECT) of=$(FLOPPY) bs=512 count=1 conv=notrunc

rainbow:
	nasm -f bin $(RAINBOW)

$(RD_OBJECT): $(READ_DSK)
	nasm -f bin $(READ_DSK)

#$(HD): $(READ_DSK)
	#dd if=/dev/zero of=$(HD) bs=512 count=5000
	#dd if=$(RD_OBJECT) of=$(HD) bs=512 count=1 conv=notrunc seek=1

$(FLOPPY): rainbow
	dd if=/dev/zero of=$(FLOPPY) bs=512 count=2880
	dd if=rainbow of=$(FLOPPY) bs=512 count=1 conv=notrunc seek=1

backup: $(IMG)
	dd if=$(IMG) of=$(BACKUP_MBR) bs=512 count=1

restore: $(HD) $(RD_OBJECT)
	dd if=$(BACKUP_MBR) of=$(HD) bs=512 count=1 conv=notrunc

clean:
	rm $(OBJECT) $(FLOPPY) rainbow read_dsk
