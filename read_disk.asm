; program for reading first sector on the default drive
org 0x100

mov ax, 0x0003					  ; set text video mode
int 0x10

mov ah, 0x19						  ; get default drive
int 0x21
mov dl, al							  ; save default drive to dl for int 13h
mov dl, 0x00


; copy first sector of disk (this part gets hooked under virus)
mov al, 0x01              ; load 1 sector
mov ah, 0x02              ; read sector
mov bx, 0x7e00            ; destination address + ES
mov cx, 0x0001            ; cylinder 0, sector=1
xor dh, dh                ; head 0
int 0x13

mov ax, 0x7e0
mov es, ax

mov ah, 0x0E
xor bx, bx
mov di, 0x0							  ; our counter
disp_lp:
	mov al, [es:di]				  ; get char from sector
	int 0x10
	inc di
	cmp di, 0x200					  ; size of sector = 512
	jl disp_lp

lp:
	jmp lp
