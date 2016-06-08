target remote localhost:1234
source gdbinit.py
source gdbinit_real_mode.txt
break *0x7c00
break *0x7c5e
break *0x7c85
c
