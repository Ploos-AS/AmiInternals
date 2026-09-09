#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/nodes.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_RESOURCES 64
#define RESOURCE_NAME_LEN 64

struct ResourceRow {
    char name[RESOURCE_NAME_LEN];
};

static struct ResourceRow rows[MAX_RESOURCES];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < RESOURCE_NAME_LEN - 1 && src[i] != '\0') {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct Node *node;
    int count = 0;
    int i;

    Forbid();
    for (node = sysbase->ResourceList.lh_Head;
         node != 0 && node->ln_Succ != 0 && count < MAX_RESOURCES;
         node = node->ln_Succ) {
        copy_name(rows[count].name, node->ln_Name);
        ++count;
    }
    Permit();

    ai_puts("Resources 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Name\n");

    for (i = 0; i < count; ++i) {
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_RESOURCES) {
        ai_puts("\nWarning: resource list truncated\n");
    }

    return 0;
}
