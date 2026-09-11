/* Minimal startup for the argument-free Q1 CLI tools, using only 1.2 APIs.
 * No libnix automatic library opening, constructors, or C library dependency.
 */
#include <exec/execbase.h>
#include <dos/dosextens.h>
#include <proto/exec.h>

struct ExecBase *SysBase;
struct DosLibrary *DOSBase;
extern int main(void);

LONG ai_start_cli(void)
{
    struct Process *process;
    LONG result;

    SysBase = *(struct ExecBase **)4;
    process = (struct Process *)FindTask(0);
    if (process->pr_CLI == 0) {
        /* These are CLI tools. Release the Workbench startup message safely. */
        struct Message *message;
        WaitPort(&process->pr_MsgPort);
        message = GetMsg(&process->pr_MsgPort);
        Forbid();
        ReplyMsg(message);
        return 20;
    }
    DOSBase = (struct DosLibrary *)OpenLibrary("dos.library", 0);
    if (DOSBase == 0) {
        return 20;
    }
    result = main();
    CloseLibrary((struct Library *)DOSBase);
    return result;
}
