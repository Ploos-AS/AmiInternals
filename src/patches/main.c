#include <exec/execbase.h>
#include <exec/types.h>
#include <proto/exec.h>

#include "ai_compat.h"

struct PatchSnapshot {
    LONG low_mem_checksum;
    ULONG exec_checksum;
    APTR cold_capture;
    APTR cool_capture;
    APTR warm_capture;
    APTR debug_entry;
};

static struct PatchSnapshot snapshot;

static void hook_line(const char *name, APTR address)
{
    ai_puts(name);
    ai_puts(" ");
    ai_put_u32((ULONG)address);
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;

    ai_puts("Patches 0.1\nAmiInternals - Ploos AS\n\n");

    if (!sysbase) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    /* Capture related ExecBase indicators as one bounded snapshot. */
    Forbid();
    Disable();
    snapshot.low_mem_checksum = (LONG)sysbase->LowMemChkSum;
    snapshot.exec_checksum = (ULONG)sysbase->ChkSum;
    snapshot.cold_capture = sysbase->ColdCapture;
    snapshot.cool_capture = sysbase->CoolCapture;
    snapshot.warm_capture = sysbase->WarmCapture;
    snapshot.debug_entry = sysbase->DebugEntry;
    Enable();
    Permit();

    ai_puts("LowMemChkSum ");
    ai_put_s32(snapshot.low_mem_checksum);
    ai_puts("\nExecChkSum ");
    ai_put_u32(snapshot.exec_checksum);
    ai_puts("\n\nHook Address\n");

    hook_line("ColdCapture", snapshot.cold_capture);
    hook_line("CoolCapture", snapshot.cool_capture);
    hook_line("WarmCapture", snapshot.warm_capture);
    hook_line("DebugEntry", snapshot.debug_entry);

    ai_puts("\nNote: non-zero hooks are indicators, not proof of an unsafe patch.\n");
    return 0;
}
