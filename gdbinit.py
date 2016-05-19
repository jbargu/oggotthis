class NextInstructionAddress(gdb.Command):
    """
Run until Next Instruction address.

Usage: nia

Put a temporary breakpoint at the address of the next instruction, and continue.

Useful to step over int interrupts.

See also: http://stackoverflow.com/questions/24491516/how-to-step-over-interrupt-calls-when-debugging-a-bootloader-bios-with-gdb-and-q
"""
    def __init__(self):
        super().__init__(
            'nia',
            gdb.COMMAND_BREAKPOINTS,
            gdb.COMPLETE_NONE,
            False
        )
    def invoke(self, arg, from_tty):
        frame = gdb.selected_frame()
        arch = frame.architecture()
        pc = gdb.selected_frame().pc()
        length = arch.disassemble(pc)[0]['length']
        gdb.Breakpoint('*' + str(pc + length), temporary = True)
        gdb.execute('continue')
NextInstructionAddress()
