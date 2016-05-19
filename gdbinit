target remote localhost:1234
source /usr/local/lib/python3.4/dist-packages/voltron/entry.py
source gdbinit.py
voltron init
set disassembly-flavor intel
layout regs
display/i $pc
break *0x7c00
c
