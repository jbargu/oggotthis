# OGGotThis

A boot sector virus, which spreads to every disk when booting from infected device. After booting it loads original MBR and stays resident in high memory, hooking interrupt 0x13 in process. Every 40th access to disk will print a super evil message. It also redirects any reads to the first sector (CHS 0-0-1, infected) to the second sector(CHS 0-0-2, original MBR) to conceal its identity.

![Output, after running dir](http://s33.postimg.org/rii4wjqin/dir_virus.png)

Disclaimer:
**This was built for educational purposes only. Always run this in a virtual machine and double check what you have plugged in. Running this unconstrained means you will infect yourself or others in the process! Although harmless it will still spread like wildfire and destroy non compliant boot sectors, thus rendering the device unbootable. I do not take any responsibility for any damage caused through use of this software!**

## Install

Below are described steps and commands for Ubuntu.

### Testing environment

You have to install [FreeDOS](http://www.freedos.org/) and some sort of emulator (I used [qemu](http://wiki.qemu.org/Main_Page)).

```
sudo apt-get install qemu
```

To ease the pain, [here's](https://en.wikibooks.org/wiki/QEMU/FreeDOS) the tutorial to install FreeDOS in qemu. I used `freedos.img` for name of the disk, otherwise you have to change it in Makefile.

### Tools

Our favourite Intel syntax assembler, am I right?

```
sudo apt-get install nasm
```

Additionally we need some sort of hex editor for seeing stuff. I used dhex:

```
sudo apt-get install dhex
```

For debugging you need GDB or any kind of debugger. If you're on Linux, you're fine. If you want to upgrade your experience, use [Voltron](https://github.com/snare/voltron).


## How it works

First it queries all devices. When it detects attached drive, checks whether it contains our virus signature. If it doesn't it starts infecting. It copies original MBR to 2nd sector and copyies infected MBR to 1st sector.

When all devices are infected it's time to become IMMORTAL (memory resident). It decreases available memory (stored on 0040:13h) by 1KB and copies itself to that location. OS won't ever use this memory, because that memory doesn't exist from its point of view. Then it copies original MBR to 0x7c00 and installs disk hook. Afterwards it jumps to original MBR and that's it. Disk hook stays in memory even after OS runs and intercepts any access to disk.

What's disk hook for? It redirects any read accesses to first sector to second sector, therefore hiding our presence on the disk. Secondly when original MBR will try to access original partition table it will reroute this to original one. User won't be able to figure out that MBR is infected from inside (unless he writes his own driver), which bypasses int 0x13. Additionally it prints a message for every 40th access to the disk (to show it works).

## How do I test it?

For testing purposes we need OS (FreeDOS). OS will reside on hard disk, while our infected virus will reside on floppy disk. First things first, backup freedos.img. Copy it to somewhere safe.

Then run

```
make backup
```

which will create backup of first sector.

If at any time you want to revert to original sector, just run `make restore`. I assume everything is backed up by now.

Run

```
dhex freedos.img
```

and observe first sector (0x0-0x1FF), it should contain something like "active partition not found".


First we will run

```
make run
```

You should see some pretty rainbow colors (just a decoy). This will make infected floppy (`floppy.flp`) and boot from it with FreeDOS attached.

If we run

```
dhex freedos.img
```

now, we should see different code (there should be phrase "VIRUS SIGNATURE" hidden somewhere in there).


Now we can run

```
make run-hd
```

which will run freedos.img. It should boot to command prompt, if you do simple `dir` you should see some evil messages popping up. That's it, if you were to run this with some other uninfected device attached it should copy itself to the infected device as well. Note that probably you won't see any other messages after first `dir` since FreeDOS caches it - virus is still very much alive.

## Debugging

There's another make rule for debugging infected floppy:

```
make debug
```

or debugging infected FreeDOS:

```
make debug-hd
```

which pauses QEMU.  Then simply call


```
make gdb
```

And it should break at 0x7c00. Then go wild.

