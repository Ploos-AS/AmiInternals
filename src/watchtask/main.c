#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/tasks.h>
#include <proto/exec.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define DEFAULT_SAMPLES 5
#define MAX_SAMPLES 100
#define MAX_TASK_VISITS 1024

#define TASK_ABSENT 0
#define TASK_PRESENT 1
#define TASK_UNKNOWN -1

static int same_name(const char *a, const char *b)
{
    if (a == 0 || b == 0) return 0;
    while (*a != '\0' && *b != '\0') {
        if (*a != *b) return 0;
        ++a;
        ++b;
    }
    return *a == '\0' && *b == '\0';
}

static LONG parse_samples(const char *s)
{
    LONG value = 0;
    if (s == 0 || *s == '\0') return -1;
    while (*s != '\0') {
        if (*s < '0' || *s > '9') return -1;
        value = value * 10 + (*s - '0');
        if (value > MAX_SAMPLES) return -1;
        ++s;
    }
    return value > 0 ? value : -1;
}

static struct Task *find_in_list(struct List *list, const char *name, int *truncated)
{
    struct Node *node;
    ULONG visits = 0;

    for (node = list->lh_Head;
         node != 0 && node->ln_Succ != 0 && visits < MAX_TASK_VISITS;
         node = node->ln_Succ) {
        ++visits;
        if (same_name(node->ln_Name, name)) return (struct Task *)node;
    }

    if (node != 0 && node->ln_Succ != 0) *truncated = 1;
    return 0;
}

static int task_present(struct ExecBase *sysbase, const char *name)
{
    struct Task *found = 0;
    int truncated = 0;

    Forbid();
    if (sysbase->ThisTask != 0 && same_name(sysbase->ThisTask->tc_Node.ln_Name, name)) {
        found = sysbase->ThisTask;
    }
    if (found == 0) found = find_in_list(&sysbase->TaskReady, name, &truncated);
    if (found == 0) found = find_in_list(&sysbase->TaskWait, name, &truncated);
    Permit();

    if (found != 0) return TASK_PRESENT;
    return truncated ? TASK_UNKNOWN : TASK_ABSENT;
}

int main(int argc, char **argv)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    LONG samples = DEFAULT_SAMPLES;
    LONG i;
    LONG seen = 0;
    LONG unknown = 0;

    ai_puts("WatchTask 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 3) {
        ai_puts("Usage: WatchTask task [samples]\n");
        return 10;
    }
    if (argc == 3) {
        samples = parse_samples(argv[2]);
        if (samples < 1) {
            ai_puts("Invalid sample count (1-100)\n");
            return 10;
        }
    }
    if (sysbase == 0) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    ai_puts("Sample State\n");
    for (i = 0; i < samples; ++i) {
        int state = task_present(sysbase, argv[1]);
        ai_put_u32((ULONG)(i + 1));
        ai_puts(" ");
        if (state == TASK_PRESENT) {
            ai_puts("PRESENT\n");
            ++seen;
        } else if (state == TASK_UNKNOWN) {
            ai_puts("UNKNOWN\n");
            ++unknown;
        } else {
            ai_puts("ABSENT\n");
        }
        if (i + 1 < samples) Delay(1);
    }

    ai_puts("Seen ");
    ai_put_u32((ULONG)seen);
    ai_puts("/");
    ai_put_u32((ULONG)samples);
    ai_puts("\n");
    if (unknown > 0) {
        ai_puts("Warning: task list traversal limit reached\n");
    }
    return seen > 0 ? 0 : 5;
}
