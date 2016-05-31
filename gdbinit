target remote localhost:1234
source gdbinit.py
source gdbinit_real_mode.txt
break *0x7c00
break *0x7e0b
break *0x7e38
break *0x7d41
c
