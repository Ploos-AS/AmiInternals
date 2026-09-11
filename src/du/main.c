#include <dos/dos.h>
#include <dos/dosextens.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define MAX_DEPTH 16
#define MAX_ENTRIES_PER_DIR 1024
#define PATH_LEN 256

/*
 * Keep recursive DOS work buffers out of the CLI stack.  Static storage also
 * gives FileInfoBlock the compiler's natural alignment, which is important on
 * classic 68k DOS implementations.
 */
static struct FileInfoBlock fib_slots[MAX_DEPTH + 1];
static char path_slots[MAX_DEPTH + 1][PATH_LEN];

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

    if (base[i] != '\0') return 0;

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
    struct FileInfoBlock *fib;
    LONG ioerr;
    ULONG entries = 0;

    if (depth > MAX_DEPTH) {
        ++error_count;
        return;
    }

    fib = &fib_slots[depth];
    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0) {
        ++error_count;
        return;
    }

    if (Examine(lock, fib) == 0) {
        ++error_count;
        UnLock(lock);
        return;
    }

    if (fib->fib_DirEntryType < 0) {
        ++file_count;
        add_size(fib->fib_Size);
        UnLock(lock);
        return;
    }

    ++dir_count;
    while (entries < MAX_ENTRIES_PER_DIR && ExNext(lock, fib) != 0) {
        char *child = path_slots[depth];
        const char *name = (const char *)fib->fib_FileName;

        ++entries;
        if (!append_name(child, path, name)) {
            ++error_count;
            continue;
        }

        if (fib->fib_DirEntryType < 0) {
            ++file_count;
            add_size(fib->fib_Size);
        } else if (depth < MAX_DEPTH) {
            scan_dir(child, depth + 1);
        } else {
            ++error_count;
        }
    }

    if (entries >= MAX_ENTRIES_PER_DIR) {
        ++error_count;
    } else {
        /* End-of-directory is normal; every other ExNext failure is an error. */
        ioerr = IoErr();
        if (ioerr != ERROR_NO_MORE_ENTRIES) {
            ++error_count;
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

    /* Emit direct DOS output before traversal so a classic-only traversal
     * failure can be distinguished from argc/argv startup failure. */
    ai_puts("DU 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Bytes Files Dirs Errors Path\n");

    scan_dir(path, 0);

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
