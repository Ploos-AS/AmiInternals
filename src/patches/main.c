#include <exec/execbase.h>
#include <exec/types.h>

#include "ai_compat.h"

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
    ai_puts("LowMemChkSum ");
    ai_put_s32((LONG)sysbase->LowMemChkSum);
    ai_puts("\nExecChkSum ");
    ai_put_u32((ULONG)sysbase->ChkSum);
    ai_puts("\n\nHook Address\n");

    hook_line("ColdCapture", sysbase->ColdCapture);
    hook_line("CoolCapture", sysbase->CoolCapture);
    hook_line("WarmCapture", sysbase->WarmCapture);
    hook_line("DebugEntry", sysbase->DebugEntry);

    ai_puts("\nNote: non-zero hooks are indicators, not proof of an unsafe patch.\n");
    return 0;
}
