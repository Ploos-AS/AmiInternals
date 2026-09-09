#include <exec/execbase.h>
#include <proto/exec.h>

#include "ai_compat.h"

static void put_ptr(const char *label, APTR value)
{
    ai_puts(label);
    ai_puts(" 0x");
    ai_put_hex32((ULONG)value);
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;

    ai_puts("BootInfo 0.1\nAmiInternals - Ploos AS\n\n");
    if (sysbase == 0) {
        ai_puts("ExecBase unavailable\n");
        return 20;
    }

    ai_puts("Exec ");
    ai_put_u32((ULONG)sysbase->LibNode.lib_Version);
    ai_puts(".");
    ai_put_u32((ULONG)sysbase->LibNode.lib_Revision);
    ai_puts("\n");
    put_ptr("ColdCapture", (APTR)sysbase->ColdCapture);
    put_ptr("CoolCapture", (APTR)sysbase->CoolCapture);
    put_ptr("WarmCapture", (APTR)sysbase->WarmCapture);
    put_ptr("DebugEntry", (APTR)sysbase->DebugEntry);
    ai_puts("LowMemChkSum 0x");
    ai_put_hex32((ULONG)sysbase->LowMemChkSum);
    ai_puts("\nExecChkSum 0x");
    ai_put_hex32((ULONG)sysbase->ChkSum);
    ai_puts("\n");
    return 0;
}
