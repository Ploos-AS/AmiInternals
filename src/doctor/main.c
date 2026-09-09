#include <exec/execbase.h>
#include <proto/exec.h>

#include "ai_compat.h"

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct AIExecInfo info;
    int warnings = 0;

    ai_puts("Doctor 0.1\nAmiInternals - Ploos AS\n\n");

    if (sysbase == 0) {
        ai_puts("FAIL SysBase unavailable\n");
        return 5;
    }

    ai_get_exec_info(&info);

    ai_puts("OK   SysBase present\n");
    ai_puts("INFO Exec version ");
    ai_put_version(info.version, info.revision);
    ai_puts("\n");

    if (sysbase->ThisTask != 0) {
        ai_puts("OK   Current task present\n");
    } else {
        ai_puts("WARN Current task unavailable\n");
        ++warnings;
    }

    ai_puts("INFO Chip free ");
    ai_put_u32(info.chip_free);
    ai_puts("\nINFO Fast free ");
    ai_put_u32(info.fast_free);
    ai_puts("\nINFO Total free ");
    ai_put_u32(info.any_free);
    ai_puts("\n");

    if (info.any_free == 0) {
        ai_puts("WARN Exec reports no free memory\n");
        ++warnings;
    } else {
        ai_puts("OK   Free memory reported\n");
    }

    ai_puts("\nResult: ");
    if (warnings == 0) {
        ai_puts("OK\n");
        return 0;
    }

    ai_puts("WARN (warnings=");
    ai_put_u32((ULONG)warnings);
    ai_puts(")\n");
    return 5;
}
