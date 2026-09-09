#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/libraries.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_HANDLERS 64
#define NAME_LEN 64

struct HandlerRow {
    ULONG task;
    char name[NAME_LEN];
};

static struct HandlerRow rows[MAX_HANDLERS];

static void copy_bstr(char *dst, BSTR bstr)
{
    UBYTE *src;
    int len;
    int i;

    if (!bstr) {
        dst[0] = '-';
        dst[1] = '\0';
        return;
    }

    src = (UBYTE *)BADDR(bstr);
    len = (int)src[0];
    if (len > NAME_LEN - 1) len = NAME_LEN - 1;
    for (i = 0; i < len; ++i) dst[i] = (char)src[i + 1];
    dst[len] = '\0';
}

int main(void)
{
    struct DosLibrary *dosbase;
    struct RootNode *root;
    struct DosInfo *info;
    struct DevInfo *entry;
    int count = 0;
    int visited = 0;
    int i;

    dosbase = (struct DosLibrary *)OpenLibrary((STRPTR)"dos.library", 0);
    if (!dosbase) {
        ai_puts("Handlers: cannot open dos.library\n");
        return 20;
    }

    root = dosbase->dl_Root;
    if (!root || !root->rn_Info) {
        CloseLibrary((struct Library *)dosbase);
        ai_puts("Handlers: DOS root information unavailable\n");
        return 20;
    }

    info = (struct DosInfo *)BADDR(root->rn_Info);

    Forbid();
    entry = (struct DevInfo *)BADDR(info->di_DevInfo);
    while (entry && visited < 256 && count < MAX_HANDLERS) {
        ++visited;
        if (entry->dvi_Task != 0) {
            rows[count].task = (ULONG)entry->dvi_Task;
            copy_bstr(rows[count].name, entry->dvi_Name);
            ++count;
        }
        entry = (struct DevInfo *)BADDR(entry->dvi_Next);
    }
    Permit();

    CloseLibrary((struct Library *)dosbase);

    ai_puts("Handlers 0.1\nAmiInternals - Ploos AS\n\n");
    ai_puts("Task Name\n");
    for (i = 0; i < count; ++i) {
        ai_put_u32(rows[i].task);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }
    if (count >= MAX_HANDLERS || visited >= 256) ai_puts("\nWarning: handler list truncated\n");
    return 0;
}
