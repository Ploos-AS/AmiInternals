#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/devices.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define NAME_LEN 64

static int same_name(const char *a, const char *b)
{
    while (*a && *b && *a == *b) {
        ++a;
        ++b;
    }
    return *a == '\0' && *b == '\0';
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct Node *node;
    struct Device *found = 0;
    UWORD version = 0;
    UWORD revision = 0;
    char name[NAME_LEN];
    int i = 0;

    name[0] = '\0';

    Forbid();
    for (node = sysbase->DeviceList.lh_Head;
         node != 0 && node->ln_Succ != 0;
         node = node->ln_Succ) {
        if (node->ln_Name && same_name(node->ln_Name, "input.device")) {
            found = (struct Device *)node;
            version = found->dd_Library.lib_Version;
            revision = found->dd_Library.lib_Revision;
            while (i < NAME_LEN - 1 && node->ln_Name[i]) {
                name[i] = node->ln_Name[i];
                ++i;
            }
            name[i] = '\0';
            break;
        }
    }
    Permit();

    ai_puts("InputInfo 0.1\nAmiInternals - Ploos AS\n\n");
    ai_puts("Device .......... ");
    ai_puts(found ? name : "not present");
    ai_puts("\n");
    if (found) {
        ai_puts("Version ......... ");
        ai_put_version(version, revision);
        ai_puts("\n");
    }

    return found ? 0 : 5;
}
