#include <dos/dos.h>
#include <dos/dosextens.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define MAX_DEPTH 32
#define PATH_LEN 256

static ULONG total_bytes;
static ULONG file_count;
static ULONG dir_count;
static ULONG error_count;

static int append_name(char *dst, const char *base, const char *name)
{
    int i = 0;
    int j = 0;

    while (base[i] != '\0' && i < PATH_LEN - 1) {
        dst[i] = base[i];
        ++i;
    }

    if (i != 0 && dst[i - 1] != ':' && dst[i - 1] != '/') {
        if (i >= PATH_LEN - 1) return 0;
        dst[i++] = '/';
    }

    while (name[j] != '\0' && i < PATH_LEN - 1) {
        dst[i++] = name[j++];
    }
    dst[i] = '\0';

    return name[j] == '\0';
}

static void add_size(LONG size)
{
    ULONG value;

    if (size <= 0) return;
    value = (ULONG)size;
    if (0xffffffffUL - total_bytes < value) {
        total_bytes = 0xffffffffUL;
    } else {
        total_bytes += value;
    }
}

static void scan_dir(const char *path, int depth)
{
    BPTR lock;
    struct FileInfoBlock fib;

    if (depth > MAX_DEPTH) {
        ++error_count;
        return;
    }

    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0) {
        ++error_count;
        return;
    }

    if (Examine(lock, &fib) == 0) {
        ++error_count;
        UnLock(lock);
        return;
    }

    if (fib.fib_DirEntryType < 0) {
        ++file_count;
        add_size(fib.fib_Size);
        UnLock(lock);
        return;
    }

    ++dir_count;
    while (ExNext(lock, &fib) != 0) {
        char child[PATH_LEN];

        if (!append_name(child, path, fib.fib_FileName)) {
            ++error_count;
            continue;
        }

        if (fib.fib_DirEntryType < 0) {
            ++file_count;
            add_size(fib.fib_Size);
        } else {
            scan_dir(child, depth + 1);
        }
    }

    UnLock(lock);
}

int main(int argc, char **argv)
{
    const char *path = "";

    if (argc > 2) {
        ai_puts("Usage: DU [path]\n");
        return 10;
    }
    if (argc == 2) path = argv[1];

    scan_dir(path, 0);

    ai_puts("DU 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Bytes Files Dirs Errors Path\n");
    ai_put_u32(total_bytes);
    ai_puts(" ");
    ai_put_u32(file_count);
    ai_puts(" ");
    ai_put_u32(dir_count);
    ai_puts(" ");
    ai_put_u32(error_count);
    ai_puts(" ");
    ai_puts(path[0] != '\0' ? path : ".");
    ai_puts("\n");

    return error_count != 0 ? 5 : 0;
}
