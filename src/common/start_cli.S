/* DOS LoadSeg entry: preserve the caller's nonvolatile registers. */
    .text
    .globl _start
_start:
    movem.l %d2-%d7/%a2-%a6,-(%sp)
    jsr _ai_start_cli
    movem.l (%sp)+,%d2-%d7/%a2-%a6
    rts
