#include <exec/execbase.h>
#include <exec/types.h>
#include <proto/exec.h>

#include "ai_compat.h"

struct AlertSnapshot {
    ULONG value[4];
};

static struct AlertSnapshot snapshot;

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    int i;

    ai_puts("Alerts 0.1\nAmiInternals - Ploos AS\n\n");

    if (!sysbase) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    /* LastAlert is Exec-owned state.  Keep the snapshot short and restore
       scheduling/interrupts before doing any output. */
    Forbid();
    Disable();
    for (i = 0; i < 4; ++i) {
        snapshot.value[i] = (ULONG)sysbase->LastAlert[i];
    }
    Enable();
    Permit();

    ai_puts("LastAlert[0] ");
    ai_put_u32(snapshot.value[0]);
    ai_puts("\nLastAlert[1] ");
    ai_put_u32(snapshot.value[1]);
    ai_puts("\nLastAlert[2] ");
    ai_put_u32(snapshot.value[2]);
    ai_puts("\nLastAlert[3] ");
    ai_put_u32(snapshot.value[3]);
    ai_puts("\n");

    if (snapshot.value[0] == 0 && snapshot.value[1] == 0 &&
        snapshot.value[2] == 0 && snapshot.value[3] == 0) {
        ai_puts("Status No recorded Exec alert\n");
    } else {
        ai_puts("Status Exec alert data present\n");
    }

    return 0;
}
