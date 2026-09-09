#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/libraries.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_MOUNTS 64
#define MOUNT_NAME_LEN 64

struct MountRow {
    UBYTE active;
    char name[MOUNT_NAME_LEN];
};

static struct MountRow rows[MAX_MOUNTS];

static void copy_bstr(char *dst, BSTR bstr)
{
    UBYTE *src;
    int len;
    int i;

    if (bstr == 0) {
        dst[0] = '<';
        dst[1] = 'u';
        dst[2] = 'n';
        dst[3] = 'n';
        dst[4] = 'a';
        dst[5] = 'm';
        dst[6] = 'e';
        dst[7] = 'd';
        dst[8] = '>';
        dst[9] = '\0';
        return;
    }

    src = (UBYTE *)BADDR(bstr);
    len = (int)src[0];
    if (len > MOUNT_NAME_LEN - 1) {
        len = MOUNT_NAME_LEN - 1;
    }

    for (i = 0; i < len; ++i) {
        dst[i] = (char)src[i + 1];
    }
    dst[len] = '\0';
}

int main(void)
{
    struct DosLibrary *dosbase;
    struct RootNode *root;
    struct DosInfo *info;
    struct DevInfo *entry;
    int count = 0;
    int i;

    dosbase = (struct DosLibrary *)OpenLibrary("dos.library", 0);
    if (dosbase == 0) {
        ai_puts("Mounts: cannot open dos.library\n");
        return 20;
    }

    root = dosbase->dl_Root;
    if (root == 0 || root->rn_Info == 0) {
        CloseLibrary((struct Library *)dosbase);
        ai_puts("Mounts: DOS root information unavailable\n");
        return 20;
    }

    info = (struct DosInfo *)BADDR(root->rn_Info);

    /* V1.x-compatible DevInfo traversal: snapshot while scheduling is forbidden. */
    Forbid();
    entry = (struct DevInfo *)BADDR(info->di_DevInfo);
    while (entry != 0 && count < MAX_MOUNTS) {
        if (entry->dvi_Type == DLT_DEVICE) {
            rows[count].active = entry->dvi_Task != 0 ? 1 : 0;
            copy_bstr(rows[count].name, entry->dvi_Name);
            ++count;
        }
        entry = (struct DevInfo *)BADDR(entry->dvi_Next);
    }
    Permit();

    CloseLibrary((struct Library *)dosbase);

    ai_puts("Mounts 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("State Name\n");

    for (i = 0; i < count; ++i) {
        ai_puts(rows[i].active ? "UP   " : "DOWN ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_MOUNTS) {
        ai_puts("\nWarning: mount list truncated\n");
    }

    return 0;
}
