org 100h

section .text

start:
	mov ax, 0x013
	int 0x10
	mov ax, 0x0A000
	mov ss, ax
	mov di, 0
	mov cx, 64000 ; length
	mov bx, 0
	mov ax, 0
lo:
	mov [ss:di], ax
	inc di
	inc bx
	cmp bx, 0
	je next
	inc ax
next:
	cmp di, cx
	jb lo
	inc bx
	jmp lo

int 0x10
