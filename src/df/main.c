#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/libraries.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_VOLUMES 64
#define MAX_DOS_ENTRIES 256
#define VOLUME_NAME_LEN 64

struct VolumeRow {
    char name[VOLUME_NAME_LEN];
};

static struct VolumeRow rows[MAX_VOLUMES];
static struct InfoData info_data;

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
    if (len > VOLUME_NAME_LEN - 1) {
        len = VOLUME_NAME_LEN - 1;
    }

    for (i = 0; i < len; ++i) {
        dst[i] = (char)src[i + 1];
    }
    dst[len] = '\0';
}

static void make_volume_path(char *dst, const char *name)
{
    int i = 0;

    while (name[i] != '\0' && i < VOLUME_NAME_LEN - 2) {
        dst[i] = name[i];
        ++i;
    }
    dst[i++] = ':';
    dst[i] = '\0';
}

int main(void)
{
    struct DosLibrary *dosbase;
    struct RootNode *root;
    struct DosInfo *dosinfo;
    struct DevInfo *entry;
    int count = 0;
    int visited = 0;
    int i;

    dosbase = (struct DosLibrary *)OpenLibrary((STRPTR)"dos.library", 0);
    if (dosbase == 0) {
        ai_puts("DF: cannot open dos.library\n");
        return 20;
    }

    root = dosbase->dl_Root;
    if (root == 0 || root->rn_Info == 0) {
        CloseLibrary((struct Library *)dosbase);
        ai_puts("DF: DOS root information unavailable\n");
        return 20;
    }

    dosinfo = (struct DosInfo *)BADDR(root->rn_Info);

    /* V1.x-compatible DevInfo traversal. Snapshot only; never wait while forbidden. */
    Forbid();
    entry = (struct DevInfo *)BADDR(dosinfo->di_DevInfo);
    while (entry != 0 && visited < MAX_DOS_ENTRIES && count < MAX_VOLUMES) {
        if (entry->dvi_Type == DLT_VOLUME && entry->dvi_Task != 0) {
            copy_bstr(rows[count].name, entry->dvi_Name);
            ++count;
        }
        ++visited;
        entry = (struct DevInfo *)BADDR(entry->dvi_Next);
    }
    Permit();

    CloseLibrary((struct Library *)dosbase);

    ai_puts("DF 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("BlockSize Total Used Free Name\n");

    for (i = 0; i < count; ++i) {
        char path[VOLUME_NAME_LEN + 2];
        BPTR lock;

        make_volume_path(path, rows[i].name);
        lock = Lock((STRPTR)path, ACCESS_READ);
        if (lock == 0) {
            ai_puts("? ? ? ? ");
            ai_puts(rows[i].name);
            ai_puts("\n");
            continue;
        }

        if (Info(lock, &info_data) != 0) {
            ULONG total = info_data.id_NumBlocks >= 0 ? (ULONG)info_data.id_NumBlocks : 0;
            ULONG used = info_data.id_NumBlocksUsed >= 0 ? (ULONG)info_data.id_NumBlocksUsed : 0;
            ULONG free_blocks = total >= used ? total - used : 0;
            ULONG block_size = info_data.id_BytesPerBlock >= 0 ? (ULONG)info_data.id_BytesPerBlock : 0;

            ai_put_u32(block_size);
            ai_puts(" ");
            ai_put_u32(total);
            ai_puts(" ");
            ai_put_u32(used);
            ai_puts(" ");
            ai_put_u32(free_blocks);
            ai_puts(" ");
            ai_puts(rows[i].name);
            ai_puts("\n");
        } else {
            ai_puts("? ? ? ? ");
            ai_puts(rows[i].name);
            ai_puts("\n");
        }

        UnLock(lock);
    }

    if (visited >= MAX_DOS_ENTRIES) {
        ai_puts("\nWarning: DOS list traversal limit reached\n");
    } else if (count >= MAX_VOLUMES) {
        ai_puts("\nWarning: volume list truncated\n");
    }

    return 0;
}
