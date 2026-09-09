#include <exec/execbase.h>
#include <exec/types.h>

#include "ai_compat.h"

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    ULONG alert0 = (ULONG)sysbase->LastAlert[0];
    ULONG alert1 = (ULONG)sysbase->LastAlert[1];
    ULONG alert2 = (ULONG)sysbase->LastAlert[2];
    ULONG alert3 = (ULONG)sysbase->LastAlert[3];

    ai_puts("Alerts 0.1\nAmiInternals - Ploos AS\n\n");
    ai_puts("LastAlert[0] ");
    ai_put_u32(alert0);
    ai_puts("\nLastAlert[1] ");
    ai_put_u32(alert1);
    ai_puts("\nLastAlert[2] ");
    ai_put_u32(alert2);
    ai_puts("\nLastAlert[3] ");
    ai_put_u32(alert3);
    ai_puts("\n");

    if (alert0 == 0 && alert1 == 0 && alert2 == 0 && alert3 == 0) {
        ai_puts("Status No recorded Exec alert\n");
    } else {
        ai_puts("Status Exec alert data present\n");
    }

    return 0;
}
