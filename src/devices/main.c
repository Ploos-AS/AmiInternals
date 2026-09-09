#include <exec/devices.h>
#include <exec/execbase.h>
#include <exec/lists.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_DEVICES 64
#define DEVICE_NAME_LEN 64

struct DeviceRow {
    UWORD version;
    UWORD revision;
    char name[DEVICE_NAME_LEN];
};

static struct DeviceRow rows[MAX_DEVICES];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < DEVICE_NAME_LEN - 1 && src[i] != '\0') {
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
    for (node = sysbase->DeviceList.lh_Head;
         node != 0 && node->ln_Succ != 0 && count < MAX_DEVICES;
         node = node->ln_Succ) {
        struct Device *device = (struct Device *)node;

        rows[count].version = device->dd_Library.lib_Version;
        rows[count].revision = device->dd_Library.lib_Revision;
        copy_name(rows[count].name, device->dd_Library.lib_Node.ln_Name);
        ++count;
    }
    Permit();

    ai_puts("Devices 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Version Name\n");

    for (i = 0; i < count; ++i) {
        ai_put_version(rows[i].version, rows[i].revision);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_DEVICES) {
        ai_puts("\nWarning: device list truncated\n");
    }

    return 0;
}
