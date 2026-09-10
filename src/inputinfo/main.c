#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/devices.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define NAME_LEN 64
#define MAX_DEVICE_VISITS 1024

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
    UWORD version = 0;
    UWORD revision = 0;
    char name[NAME_LEN];
    int i = 0;
    int found = 0;
    int visits = 0;
    int truncated = 0;

    name[0] = '\0';

    ai_puts("InputInfo 0.1\nAmiInternals - Ploos AS\n\n");

    if (!sysbase) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    Forbid();
    node = sysbase->DeviceList.lh_Head;
    while (node != 0 && node->ln_Succ != 0 && visits < MAX_DEVICE_VISITS) {
        ++visits;
        if (node->ln_Name && same_name(node->ln_Name, "input.device")) {
            struct Device *device = (struct Device *)node;
            version = device->dd_Library.lib_Version;
            revision = device->dd_Library.lib_Revision;
            while (i < NAME_LEN - 1 && node->ln_Name[i]) {
                name[i] = node->ln_Name[i];
                ++i;
            }
            name[i] = '\0';
            found = 1;
            break;
        }
        node = node->ln_Succ;
    }
    if (!found && node != 0 && node->ln_Succ != 0 && visits >= MAX_DEVICE_VISITS) {
        truncated = 1;
    }
    Permit();

    ai_puts("Device .......... ");
    ai_puts(found ? name : "not present");
    ai_puts("\n");
    if (found) {
        ai_puts("Version ......... ");
        ai_put_version(version, revision);
        ai_puts("\n");
    } else if (truncated) {
        ai_puts("Warning: device list traversal limit reached\n");
    }

    return found ? 0 : 5;
}
