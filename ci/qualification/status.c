/* Runs immediately after the tool, before any other CLI command. */
#include <dos/dosextens.h>
#include <proto/exec.h>
#include "ai_compat.h"

extern struct DosLibrary *DOSBase;

int main(void)
{
    struct Process *process = (struct Process *)FindTask(0);
    struct CommandLineInterface *cli =
        (struct CommandLineInterface *)BADDR(process->pr_CLI);
    LONG previous_rc = cli->cli_ReturnCode;
    struct Library *wb;

    ai_puts("Previous RC: ");
    ai_put_s32(previous_rc);
    ai_puts("\nDOS: ");
    ai_put_version(DOSBase->dl_lib.lib_Version, DOSBase->dl_lib.lib_Revision);
    wb = OpenLibrary("workbench.library", 0);
    if (wb) {
        ai_puts("\nWorkbench: ");
        ai_put_version(wb->lib_Version, wb->lib_Revision);
        CloseLibrary(wb);
    }
    ai_puts("\n");
    return 0;
}
