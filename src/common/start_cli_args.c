/* Minimal AmigaOS 1.2-compatible CLI startup with argc/argv construction.
 * No ReadArgs(), utility.library, libnix startup or C library dependency.
 */
#include <exec/execbase.h>
#include <dos/dosextens.h>
#include <proto/exec.h>

#define AI_MAX_ARGS 16
#define AI_CMDLINE_LEN 256

struct ExecBase *SysBase;
struct DosLibrary *DOSBase;
extern int main(int argc, char **argv);

static char argbuf[AI_CMDLINE_LEN];
static char *argv_store[AI_MAX_ARGS + 2];
static char program_name[] = "AmiInternals";

static int build_argv(LONG length, const char *line)
{
    LONG i = 0;
    int argc = 1;
    int out = 0;

    argv_store[0] = program_name;

    if (length < 0) length = 0;
    if (length > AI_CMDLINE_LEN - 1) length = AI_CMDLINE_LEN - 1;

    while (i < length) {
        int quoted = 0;

        while (i < length && (line[i] == ' ' || line[i] == '\t' ||
                              line[i] == '\r' || line[i] == '\n')) {
            ++i;
        }
        if (i >= length) break;
        if (argc > AI_MAX_ARGS) break;

        argv_store[argc++] = &argbuf[out];
        if (line[i] == '"') {
            quoted = 1;
            ++i;
        }

        while (i < length) {
            char c = line[i++];

            if (quoted) {
                if (c == '"') break;
            } else if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
                break;
            }

            if (out < AI_CMDLINE_LEN - 1) {
                argbuf[out++] = c;
            }
        }

        if (out < AI_CMDLINE_LEN) {
            argbuf[out++] = '\0';
        }
    }

    argv_store[argc] = 0;
    return argc;
}

LONG ai_start_cli_args(LONG length, const char *line)
{
    struct Process *process;
    LONG result;
    int argc;

    SysBase = *(struct ExecBase **)4;
    process = (struct Process *)FindTask(0);
    if (process->pr_CLI == 0) {
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

    argc = build_argv(length, line);
    result = main(argc, argv_store);
    CloseLibrary((struct Library *)DOSBase);
    return result;
}
