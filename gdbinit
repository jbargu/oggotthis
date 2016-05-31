target remote localhost:1234
source gdbinit.py
source gdbinit_real_mode.txt
break *0x7c20
c
