#include <exec/execbase.h>
#include <exec/interrupts.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define INT_COUNT 16
#define NAME_LEN 48

struct IntRow {
    ULONG code;
    ULONG data;
    char name[NAME_LEN];
};

static struct IntRow rows[INT_COUNT];

static void copy_name(char *dst, const char *src)
{
    int i = 0;
    if (!src) src = "-";
    while (i < NAME_LEN - 1 && src[i]) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    int i;

    ai_puts("Interrupts 0.1\nAmiInternals - Ploos AS\n\n");

    if (!sysbase) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    /* Keep task switches and interrupt-vector replacement out of the bounded
       snapshot.  Output is deliberately performed only after restoring both. */
    Forbid();
    Disable();
    for (i = 0; i < INT_COUNT; ++i) {
        rows[i].code = (ULONG)sysbase->IntVects[i].iv_Code;
        rows[i].data = (ULONG)sysbase->IntVects[i].iv_Data;
        copy_name(rows[i].name,
                  sysbase->IntVects[i].iv_Node ? sysbase->IntVects[i].iv_Node->ln_Name : 0);
    }
    Enable();
    Permit();

    ai_puts("Int Code Data Name\n");
    for (i = 0; i < INT_COUNT; ++i) {
        ai_put_u32((ULONG)i);
        ai_puts(" ");
        ai_put_u32(rows[i].code);
        ai_puts(" ");
        ai_put_u32(rows[i].data);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }
    return 0;
}
