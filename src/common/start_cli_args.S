/* DOS LoadSeg entry for CLI tools that need argc/argv.
 * AmigaDOS enters with D0 = command-line length and A0 = command-line bytes.
 */
    .text
    .globl _start
_start:
    movem.l %d2-%d7/%a2-%a6,-(%sp)
    move.l %a0,-(%sp)
    move.l %d0,-(%sp)
    jsr _ai_start_cli_args
    addq.l #8,%sp
    movem.l (%sp)+,%d2-%d7/%a2-%a6
    rts
