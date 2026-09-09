#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/tasks.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_TASKS 64
#define TASK_NAME_LEN 64

struct TaskRow {
    char state;
    BYTE priority;
    char name[TASK_NAME_LEN];
};

static struct TaskRow rows[MAX_TASKS];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < TASK_NAME_LEN - 1 && src[i] != '\0') {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

static void add_task(int *count, struct Task *task, char state)
{
    if (task == 0 || *count >= MAX_TASKS) {
        return;
    }

    rows[*count].state = state;
    rows[*count].priority = task->tc_Node.ln_Pri;
    copy_name(rows[*count].name, task->tc_Node.ln_Name);
    ++(*count);
}

static void add_list(int *count, struct List *list, char state)
{
    struct Node *node;

    for (node = list->lh_Head; node != 0 && node->ln_Succ != 0; node = node->ln_Succ) {
        add_task(count, (struct Task *)node, state);
        if (*count >= MAX_TASKS) {
            break;
        }
    }
}

static const char *state_name(char state)
{
    if (state == 'R') {
        return "RUN  ";
    }
    if (state == 'r') {
        return "READY";
    }
    return "WAIT ";
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    int count = 0;
    int i;

    Forbid();
    add_task(&count, sysbase->ThisTask, 'R');
    add_list(&count, &sysbase->TaskReady, 'r');
    add_list(&count, &sysbase->TaskWait, 'w');
    Permit();

    ai_puts("Tasks 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("State Pri Name\n");

    for (i = 0; i < count; ++i) {
        ai_puts(state_name(rows[i].state));
        ai_puts(" ");
        ai_put_s32((LONG)rows[i].priority);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_TASKS) {
        ai_puts("\nWarning: task list truncated\n");
    }

    return 0;
}
