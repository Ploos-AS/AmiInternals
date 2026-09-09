#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/tasks.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_PATH_ENTRIES 64

struct PathComponent {
    BPTR pc_Next;
    BPTR pc_Lock;
};

static int has_path_syntax(const char *name)
{
    int i;

    for (i = 0; name[i] != '\0'; ++i) {
        if (name[i] == ':' || name[i] == '/') return 1;
    }
    return 0;
}

static int exists_relative_to(BPTR dir, const char *name)
{
    BPTR dup;
    BPTR old;
    BPTR file;

    dup = DupLock(dir);
    if (dup == 0) return 0;

    old = CurrentDir(dup);
    file = Lock((STRPTR)name, ACCESS_READ);
    CurrentDir(old);
    UnLock(dup);

    if (file == 0) return 0;
    UnLock(file);
    return 1;
}

static void print_path_match(ULONG index, const char *name)
{
    ai_puts("PATH[");
    ai_put_u32(index);
    ai_puts("]:");
    ai_puts(name);
    ai_puts("\n");
}

int main(int argc, char **argv)
{
    struct Process *process;
    struct CommandLineInterface *cli;
    struct PathComponent *component;
    BPTR file;
    ULONG index = 0;

    if (argc != 2) {
        ai_puts("Usage: Which command\n");
        return 10;
    }

    ai_puts("Which 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    if (has_path_syntax(argv[1])) {
        file = Lock((STRPTR)argv[1], ACCESS_READ);
        if (file != 0) {
            UnLock(file);
            ai_puts(argv[1]);
            ai_puts("\n");
            return 0;
        }
        ai_puts("Not found: ");
        ai_puts(argv[1]);
        ai_puts("\n");
        return 5;
    }

    file = Lock((STRPTR)argv[1], ACCESS_READ);
    if (file != 0) {
        UnLock(file);
        ai_puts("CURRENT:");
        ai_puts(argv[1]);
        ai_puts("\n");
        return 0;
    }

    process = (struct Process *)FindTask(0);
    cli = 0;
    if (process != 0 && process->pr_CLI != 0) {
        cli = (struct CommandLineInterface *)BADDR(process->pr_CLI);
    }

    if (cli != 0) {
        component = (struct PathComponent *)BADDR(cli->cli_CommandDir);
        while (component != 0 && index < MAX_PATH_ENTRIES) {
            if (component->pc_Lock != 0 && exists_relative_to(component->pc_Lock, argv[1])) {
                print_path_match(index, argv[1]);
                return 0;
            }
            component = (struct PathComponent *)BADDR(component->pc_Next);
            ++index;
        }
    }

    {
        char candidate[260];
        int i = 0;
        int j = 0;
        candidate[i++] = 'C';
        candidate[i++] = ':';
        while (argv[1][j] != '\0' && i < 259) candidate[i++] = argv[1][j++];
        candidate[i] = '\0';

        if (argv[1][j] == '\0') {
            file = Lock((STRPTR)candidate, ACCESS_READ);
            if (file != 0) {
                UnLock(file);
                ai_puts(candidate);
                ai_puts("\n");
                return 0;
            }
        }
    }

    ai_puts("Not found: ");
    ai_puts(argv[1]);
    ai_puts("\n");
    if (index >= MAX_PATH_ENTRIES) {
        ai_puts("Warning: CLI path traversal limit reached\n");
    }
    return 5;
}
