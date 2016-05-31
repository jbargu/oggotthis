mov ax, 0x0003					  ; set text video mode
int 0x10

; copy first sector of disk (this part gets hooked)
mov al, 0x01              ; load 1 sector
mov ah, 0x02              ; read sector
mov bx, 0x7e00            ; destination address + ES
mov cx, 0x0001            ; cylinder 0, sector=1
xor dh, dh                ; head 0
int 0x13

mov ax, 0xB800
mov es, ax
mov ax, 0x7e0						  ; set registers
mov ds, ax

mov di, 0x0							  ; our counter
disp_lp:
	mov al, [ds:di]				  ; get char from sector
	mov si, di
	add si, si						  ; compute desitination index
	mov byte [es:si], al	  ; save to video buffer
	mov byte [es:si+1], 0x01 ; set color
	inc di
	cmp di, 0x200					  ; size of sector = 512
	jl disp_lp

lp:
	jmp lp

times (218 - ($-$$)) nop      ; Pad for disk time stamp
db "My normal bootloader signature.$"

DiskTimeStamp times 8 db 0    ; Disk Time Stamp
times (0x1b4 - ($-$$)) nop    ; Pad For MBR Partition Table

UID times 10 db 0             ; Unique Disk ID
PT1 times 16 db 0             ; First Partition Entry
PT2 times 16 db 0             ; Second Partition Entry
PT3 times 16 db 0             ; Third Partition Entry
PT4 times 16 db 0             ; Fourth Partition Entry

dw 0xAA55                     ; Boot Signature
