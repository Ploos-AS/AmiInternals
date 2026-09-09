#include <exec/execbase.h>
#include <exec/libraries.h>
#include <exec/lists.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_LIBS 96
#define LIB_NAME_LEN 64

struct LibRow {
    UWORD version;
    UWORD revision;
    char name[LIB_NAME_LEN];
};

static struct LibRow rows[MAX_LIBS];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < LIB_NAME_LEN - 1 && src[i] != '\0') {
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
    for (node = sysbase->LibList.lh_Head;
         node != 0 && node->ln_Succ != 0 && count < MAX_LIBS;
         node = node->ln_Succ) {
        struct Library *lib = (struct Library *)node;

        rows[count].version = lib->lib_Version;
        rows[count].revision = lib->lib_Revision;
        copy_name(rows[count].name, lib->lib_Node.ln_Name);
        ++count;
    }
    Permit();

    ai_puts("Libs 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Version Name\n");

    for (i = 0; i < count; ++i) {
        ai_put_version(rows[i].version, rows[i].revision);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_LIBS) {
        ai_puts("\nWarning: library list truncated\n");
    }

    return 0;
}
