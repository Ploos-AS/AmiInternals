#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/tasks.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define NAME_LEN 64
#define MAX_TASK_VISITS 1024

struct TaskSnapshot {
    ULONG address;
    BYTE priority;
    UBYTE state;
    UBYTE flags;
    BYTE id_nest;
    BYTE td_nest;
    ULONG sig_alloc;
    ULONG sig_wait;
    ULONG sig_recvd;
    ULONG sig_except;
    ULONG sp_reg;
    ULONG sp_lower;
    ULONG sp_upper;
    char name[NAME_LEN];
};

static struct TaskSnapshot snapshot;

static void copy_name(char *dst, const char *src)
{
    int i = 0;
    if (!src) src = "<unnamed>";
    while (i < NAME_LEN - 1 && src[i]) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

static int same_name(const char *a, const char *b)
{
    unsigned char ca, cb;
    if (!a || !b) return 0;
    while (*a && *b) {
        ca = (unsigned char)*a++;
        cb = (unsigned char)*b++;
        if (ca >= 'A' && ca <= 'Z') ca = (unsigned char)(ca + ('a' - 'A'));
        if (cb >= 'A' && cb <= 'Z') cb = (unsigned char)(cb + ('a' - 'A'));
        if (ca != cb) return 0;
    }
    return *a == '\0' && *b == '\0';
}

static struct Task *find_in_list(struct List *list, const char *name, LONG *truncated)
{
    struct Node *node;
    ULONG visits = 0;

    for (node = list->lh_Head; node && node->ln_Succ && visits < MAX_TASK_VISITS; node = node->ln_Succ) {
        ++visits;
        if (same_name(node->ln_Name, name)) return (struct Task *)node;
    }

    if (node && node->ln_Succ) *truncated = 1;
    return 0;
}

static struct Task *find_task(struct ExecBase *sysbase, const char *name, LONG *truncated)
{
    struct Task *task;
    if (!name) return sysbase->ThisTask;
    task = sysbase->ThisTask;
    if (task && same_name(task->tc_Node.ln_Name, name)) return task;
    task = find_in_list(&sysbase->TaskReady, name, truncated);
    if (task) return task;
    return find_in_list(&sysbase->TaskWait, name, truncated);
}

static void take_snapshot(struct Task *task)
{
    snapshot.address = (ULONG)task;
    snapshot.priority = task->tc_Node.ln_Pri;
    snapshot.state = task->tc_State;
    snapshot.flags = task->tc_Flags;
    snapshot.id_nest = task->tc_IDNestCnt;
    snapshot.td_nest = task->tc_TDNestCnt;
    snapshot.sig_alloc = task->tc_SigAlloc;
    snapshot.sig_wait = task->tc_SigWait;
    snapshot.sig_recvd = task->tc_SigRecvd;
    snapshot.sig_except = task->tc_SigExcept;
    snapshot.sp_reg = (ULONG)task->tc_SPReg;
    snapshot.sp_lower = (ULONG)task->tc_SPLower;
    snapshot.sp_upper = (ULONG)task->tc_SPUpper;
    copy_name(snapshot.name, task->tc_Node.ln_Name);
}

static void value(const char *label, ULONG v)
{
    ai_puts(label);
    ai_put_u32(v);
    ai_puts("\n");
}

int main(int argc, char **argv)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct Task *task;
    const char *name = 0;
    LONG truncated = 0;

    ai_puts("TaskInfo 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: TaskInfo [task-name]\n");
        return 10;
    }
    if (argc == 2) name = argv[1];
    if (!sysbase) {
        ai_puts("ExecBase unavailable\n");
        return 5;
    }

    Forbid();
    task = find_task(sysbase, name, &truncated);
    if (task) take_snapshot(task);
    Permit();

    if (!task) {
        if (truncated) ai_puts("Task search limit reached\n");
        else ai_puts("Task not found\n");
        return 5;
    }

    ai_puts("Name ............ "); ai_puts(snapshot.name); ai_puts("\n");
    value("Address ......... ", snapshot.address);
    ai_puts("Priority ........ "); ai_put_s32((LONG)snapshot.priority); ai_puts("\n");
    value("State ........... ", (ULONG)snapshot.state);
    value("Flags ........... ", (ULONG)snapshot.flags);
    ai_puts("ID nest ......... "); ai_put_s32((LONG)snapshot.id_nest); ai_puts("\n");
    ai_puts("TD nest ......... "); ai_put_s32((LONG)snapshot.td_nest); ai_puts("\n");
    value("Signals alloc ... ", snapshot.sig_alloc);
    value("Signals wait .... ", snapshot.sig_wait);
    value("Signals received  ", snapshot.sig_recvd);
    value("Signals except .. ", snapshot.sig_except);
    value("SP .............. ", snapshot.sp_reg);
    value("Stack lower ..... ", snapshot.sp_lower);
    value("Stack upper ..... ", snapshot.sp_upper);
    return 0;
}
