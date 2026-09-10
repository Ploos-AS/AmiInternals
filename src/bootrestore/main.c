#include <devices/trackdisk.h>
#include <exec/io.h>
#include <exec/ports.h>
#include <exec/tasks.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define BOOTBLOCK_SIZE 1024

static UBYTE bootblock[BOOTBLOCK_SIZE];
static struct MsgPort port;
static struct IOStdReq io;

static int streq(const char *a, const char *b)
{
    while (*a != '\0' && *b != '\0') {
        if (*a++ != *b++) return 0;
    }
    return *a == '\0' && *b == '\0';
}

static int parse_unit(const char *s, ULONG *unit)
{
    if (s == 0 || s[0] != 'D' || s[1] != 'F' || s[2] < '0' || s[2] > '3') return 0;
    if (s[3] != '\0' && !(s[3] == ':' && s[4] == '\0')) return 0;
    *unit = (ULONG)(s[2] - '0');
    return 1;
}

static int setup_io(ULONG unit)
{
    BYTE sig = AllocSignal(-1);
    if (sig == -1) return 0;

    port.mp_Node.ln_Type = NT_MSGPORT;
    port.mp_Flags = PA_SIGNAL;
    port.mp_SigBit = (UBYTE)sig;
    port.mp_SigTask = FindTask(0);
    NewList(&port.mp_MsgList);

    io.io_Message.mn_Node.ln_Type = NT_MESSAGE;
    io.io_Message.mn_ReplyPort = &port;
    io.io_Message.mn_Length = sizeof(io);

    if (OpenDevice((STRPTR)"trackdisk.device", unit, (struct IORequest *)&io, 0) != 0) {
        FreeSignal(sig);
        return 0;
    }
    return 1;
}

static void teardown_io(void)
{
    BYTE sig = (BYTE)port.mp_SigBit;
    CloseDevice((struct IORequest *)&io);
    FreeSignal(sig);
}

int main(int argc, char **argv)
{
    ULONG unit;
    BPTR fh;
    LONG got;
    UBYTE extra;

    ai_puts("BootRestore 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc != 4 || !parse_unit(argv[1], &unit) || !streq(argv[3], "YES")) {
        ai_puts("Usage: BootRestore DF0: bootblock-file YES\n");
        ai_puts("WARNING: writes raw boot block data. Final YES is mandatory.\n");
        return 10;
    }

    fh = Open((STRPTR)argv[2], MODE_OLDFILE);
    if (fh == 0) {
        ai_puts("Cannot open input file\n");
        return 5;
    }
    got = Read(fh, bootblock, BOOTBLOCK_SIZE);
    if (got != BOOTBLOCK_SIZE || Read(fh, &extra, 1) != 0) {
        Close(fh);
        ai_puts("Input must be exactly 1024 bytes\n");
        return 5;
    }
    Close(fh);

    if (!setup_io(unit)) {
        ai_puts("Cannot open trackdisk.device\n");
        return 5;
    }

    io.io_Command = CMD_WRITE;
    io.io_Data = bootblock;
    io.io_Length = BOOTBLOCK_SIZE;
    io.io_Offset = 0;
    if (DoIO((struct IORequest *)&io) != 0 || io.io_Actual != BOOTBLOCK_SIZE) {
        teardown_io();
        ai_puts("Boot block write failed\n");
        return 5;
    }

    io.io_Command = CMD_UPDATE;
    io.io_Data = 0;
    io.io_Length = 0;
    io.io_Offset = 0;
    if (DoIO((struct IORequest *)&io) != 0) {
        teardown_io();
        ai_puts("Boot block update failed\n");
        return 5;
    }
    teardown_io();

    ai_puts("Restored 1024-byte boot block to DF");
    ai_put_u32(unit);
    ai_puts("\n");
    return 0;
}
