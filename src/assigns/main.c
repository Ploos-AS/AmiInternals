#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/libraries.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_ASSIGNS 96
#define MAX_DEVINFO_VISITS 256
#define ASSIGN_NAME_LEN 64

struct AssignRow {
    LONG type;
    char name[ASSIGN_NAME_LEN];
};

static struct AssignRow rows[MAX_ASSIGNS];

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
    if (len > ASSIGN_NAME_LEN - 1) {
        len = ASSIGN_NAME_LEN - 1;
    }

    for (i = 0; i < len; ++i) {
        dst[i] = (char)src[i + 1];
    }
    dst[len] = '\0';
}

static const char *type_name(LONG type)
{
    if (type == DLT_DIRECTORY) {
        return "Dir";
    }
    if (type == DLT_LATE) {
        return "Late";
    }
    if (type == DLT_NONBINDING) {
        return "Nonbind";
    }
    return "Other";
}

int main(void)
{
    struct DosLibrary *dosbase;
    struct RootNode *root;
    struct DosInfo *info;
    struct DevInfo *entry;
    int count = 0;
    int visited = 0;
    int traversal_truncated = 0;
    int i;

    dosbase = (struct DosLibrary *)OpenLibrary((STRPTR)"dos.library", 0);
    if (dosbase == 0) {
        ai_puts("Assigns: cannot open dos.library\n");
        return 20;
    }

    root = dosbase->dl_Root;
    if (root == 0 || root->rn_Info == 0) {
        CloseLibrary((struct Library *)dosbase);
        ai_puts("Assigns: DOS root information unavailable\n");
        return 20;
    }

    info = (struct DosInfo *)BADDR(root->rn_Info);

    /* V1.x-compatible DevInfo traversal: snapshot while scheduling is forbidden. */
    Forbid();
    entry = (struct DevInfo *)BADDR(info->di_DevInfo);
    while (entry != 0 && visited < MAX_DEVINFO_VISITS && count < MAX_ASSIGNS) {
        ++visited;
        if (entry->dvi_Type == DLT_DIRECTORY ||
            entry->dvi_Type == DLT_LATE ||
            entry->dvi_Type == DLT_NONBINDING) {
            rows[count].type = entry->dvi_Type;
            copy_bstr(rows[count].name, entry->dvi_Name);
            ++count;
        }
        entry = (struct DevInfo *)BADDR(entry->dvi_Next);
    }
    if (entry != 0 && visited >= MAX_DEVINFO_VISITS) {
        traversal_truncated = 1;
    }
    Permit();

    CloseLibrary((struct Library *)dosbase);

    ai_puts("Assigns 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Type Name\n");

    for (i = 0; i < count; ++i) {
        ai_puts(type_name(rows[i].type));
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_ASSIGNS) {
        ai_puts("\nWarning: assign list truncated\n");
    }
    if (traversal_truncated) {
        ai_puts("\nWarning: DevInfo traversal limit reached\n");
    }

    return 0;
}
