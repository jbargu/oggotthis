target remote localhost:1234
source gdbinit.py
set disassembly-flavor intel
layout regs
display/i $pc
break *0x7c00
c
