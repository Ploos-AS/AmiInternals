#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/tasks.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_PATH_ENTRIES 64
#define CANDIDATE_LEN 260

struct PathComponent {
    BPTR pc_Next;
    BPTR pc_Lock;
};

/* Keep DOS inspection storage out of the small classic CLI stack. */
static struct FileInfoBlock inspect_fib;
static char candidate[CANDIDATE_LEN];
static struct PathComponent *visited_path[MAX_PATH_ENTRIES];

static int has_path_syntax(const char *name)
{
    int i;

    for (i = 0; name[i] != '\0'; ++i) {
        if (name[i] == ':' || name[i] == '/') return 1;
    }
    return 0;
}

static int lock_is_entry(BPTR lock)
{
    if (lock == 0) return 0;
    return Examine(lock, &inspect_fib) != 0;
}

static int exists_relative_to(BPTR dir, const char *name)
{
    BPTR dup;
    BPTR old;
    BPTR entry;
    int found;

    dup = DupLock(dir);
    if (dup == 0) return 0;

    old = CurrentDir(dup);
    entry = Lock((STRPTR)name, ACCESS_READ);
    found = lock_is_entry(entry);
    if (entry != 0) UnLock(entry);
    CurrentDir(old);
    UnLock(dup);

    return found;
}

static void print_path_match(ULONG index, const char *name)
{
    ai_puts("PATH[");
    ai_put_u32(index);
    ai_puts("]:");
    ai_puts(name);
    ai_puts("\n");
}

static int lock_named_entry(const char *name)
{
    BPTR entry;
    int found;

    entry = Lock((STRPTR)name, ACCESS_READ);
    if (entry == 0) return 0;

    found = lock_is_entry(entry);
    UnLock(entry);
    return found;
}

static int path_component_seen(struct PathComponent *component, ULONG count)
{
    ULONG i;

    for (i = 0; i < count; ++i) {
        if (visited_path[i] == component) return 1;
    }
    return 0;
}

int main(int argc, char **argv)
{
    struct Process *process;
    struct CommandLineInterface *cli;
    struct PathComponent *component;
    ULONG index = 0;
    int path_cycle = 0;

    if (argc != 2) {
        ai_puts("Usage: Which file\n");
        return 10;
    }

    ai_puts("Which 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    if (has_path_syntax(argv[1])) {
        if (lock_named_entry(argv[1])) {
            ai_puts(argv[1]);
            ai_puts("\n");
            return 0;
        }
        ai_puts("Not found: ");
        ai_puts(argv[1]);
        ai_puts("\n");
        return 5;
    }

    if (lock_named_entry(argv[1])) {
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
            if (path_component_seen(component, index)) {
                path_cycle = 1;
                break;
            }
            visited_path[index] = component;

            if (component->pc_Lock != 0 && exists_relative_to(component->pc_Lock, argv[1])) {
                print_path_match(index, argv[1]);
                return 0;
            }
            component = (struct PathComponent *)BADDR(component->pc_Next);
            ++index;
        }
    }

    {
        int i = 0;
        int j = 0;
        candidate[i++] = 'C';
        candidate[i++] = ':';
        while (argv[1][j] != '\0' && i < CANDIDATE_LEN - 1) candidate[i++] = argv[1][j++];
        candidate[i] = '\0';

        if (argv[1][j] == '\0' && lock_named_entry(candidate)) {
            ai_puts(candidate);
            ai_puts("\n");
            return 0;
        }
    }

    ai_puts("Not found: ");
    ai_puts(argv[1]);
    ai_puts("\n");
    if (path_cycle) {
        ai_puts("Warning: CLI path cycle detected\n");
    } else if (index >= MAX_PATH_ENTRIES) {
        ai_puts("Warning: CLI path traversal limit reached\n");
    }
    return 5;
}
