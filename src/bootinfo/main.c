#include <exec/execbase.h>
#include <proto/exec.h>

#include "ai_compat.h"

struct BootSnapshot {
    UWORD version;
    UWORD revision;
    APTR cold_capture;
    APTR cool_capture;
    APTR warm_capture;
    APTR debug_entry;
    ULONG lowmem_checksum;
    ULONG exec_checksum;
};

static void put_hex32(ULONG value)
{
    static const char digits[] = "0123456789ABCDEF";
    char out[9];
    int shift;
    int i = 0;

    for (shift = 28; shift >= 0; shift -= 4) {
        out[i++] = digits[(value >> shift) & 0x0FUL];
    }
    out[i] = '\0';
    ai_puts(out);
}

static void put_ptr(const char *label, APTR value)
{
    ai_puts(label);
    ai_puts(" 0x");
    put_hex32((ULONG)value);
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct BootSnapshot snapshot;

    ai_puts("BootInfo 0.1\nAmiInternals - Ploos AS\n\n");
    if (sysbase == 0) {
        ai_puts("ExecBase unavailable\n");
        return 20;
    }

    Forbid();
    Disable();
    snapshot.version = sysbase->LibNode.lib_Version;
    snapshot.revision = sysbase->LibNode.lib_Revision;
    snapshot.cold_capture = (APTR)sysbase->ColdCapture;
    snapshot.cool_capture = (APTR)sysbase->CoolCapture;
    snapshot.warm_capture = (APTR)sysbase->WarmCapture;
    snapshot.debug_entry = (APTR)sysbase->DebugEntry;
    snapshot.lowmem_checksum = (ULONG)sysbase->LowMemChkSum;
    snapshot.exec_checksum = (ULONG)sysbase->ChkSum;
    Enable();
    Permit();

    ai_puts("Exec ");
    ai_put_u32((ULONG)snapshot.version);
    ai_puts(".");
    ai_put_u32((ULONG)snapshot.revision);
    ai_puts("\n");
    put_ptr("ColdCapture", snapshot.cold_capture);
    put_ptr("CoolCapture", snapshot.cool_capture);
    put_ptr("WarmCapture", snapshot.warm_capture);
    put_ptr("DebugEntry", snapshot.debug_entry);
    ai_puts("LowMemChkSum 0x");
    put_hex32(snapshot.lowmem_checksum);
    ai_puts("\nExecChkSum 0x");
    put_hex32(snapshot.exec_checksum);
    ai_puts("\n");
    return 0;
}
