#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/libraries.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define VALUE_LEN 256
#define MAX_DOS_ENTRIES 256

static char value[VALUE_LEN];

static int bstr_equals(BSTR bstr, const char *text)
{
    UBYTE *src;
    int len;
    int i;

    if (bstr == 0) return 0;

    src = (UBYTE *)BADDR(bstr);
    len = (int)src[0];

    for (i = 0; i < len; ++i) {
        char a = (char)src[i + 1];
        char b = text[i];

        if (b == '\0') return 0;
        if (a >= 'a' && a <= 'z') a = (char)(a - 'a' + 'A');
        if (b >= 'a' && b <= 'z') b = (char)(b - 'a' + 'A');
        if (a != b) return 0;
    }

    return text[len] == '\0';
}

static BPTR find_env_lock(void)
{
    struct DosLibrary *dosbase;
    struct RootNode *root;
    struct DosInfo *info;
    struct DevInfo *entry;
    BPTR lock = 0;
    int visited = 0;

    dosbase = (struct DosLibrary *)OpenLibrary((STRPTR)"dos.library", 0);
    if (dosbase == 0) return 0;

    root = dosbase->dl_Root;
    if (root != 0 && root->rn_Info != 0) {
        info = (struct DosInfo *)BADDR(root->rn_Info);

        /*
         * Classic DOS keeps assigns in DevInfo, but implementations do not
         * all expose a directory assign with the same dvi_Type value.  The
         * stable properties we need are the assign name and a usable lock.
         */
        Forbid();
        entry = (struct DevInfo *)BADDR(info->di_DevInfo);
        while (entry != 0 && visited < MAX_DOS_ENTRIES) {
            if (entry->dvi_Lock != 0 &&
                bstr_equals(entry->dvi_Name, "ENV")) {
                lock = entry->dvi_Lock;
                break;
            }
            ++visited;
            entry = (struct DevInfo *)BADDR(entry->dvi_Next);
        }
        Permit();
    }

    CloseLibrary((struct Library *)dosbase);
    return lock;
}

static int read_var_from_lock(BPTR env_lock, const char *name)
{
    BPTR old_dir;
    BPTR fh;
    LONG got;
    int i;

    old_dir = CurrentDir(env_lock);
    fh = Open((STRPTR)name, MODE_OLDFILE);
    CurrentDir(old_dir);

    if (fh == 0) return 0;

    got = Read(fh, value, VALUE_LEN - 1);
    Close(fh);
    if (got < 0) return 0;

    value[got] = '\0';
    for (i = 0; i < got; ++i) {
        if (value[i] == '\n' || value[i] == '\r') {
            value[i] = '\0';
            break;
        }
    }
    return 1;
}

int main(int argc, char **argv)
{
    BPTR env_lock;

    ai_puts("Env 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    if (argc != 2) {
        ai_puts("Usage: Env name\n");
        return 10;
    }

    env_lock = find_env_lock();
    if (env_lock == 0) {
        ai_puts("ENV: assign unavailable\n");
        return 5;
    }

    if (!read_var_from_lock(env_lock, argv[1])) {
        ai_puts("Not found: ");
        ai_puts(argv[1]);
        ai_puts("\n");
        return 5;
    }

    ai_puts(argv[1]);
    ai_puts("=");
    ai_puts(value);
    ai_puts("\n");
    return 0;
}
