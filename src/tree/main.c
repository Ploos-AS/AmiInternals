#include <dos/dos.h>
#include <dos/dosextens.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define MAX_DEPTH 16
#define PATH_LEN 256

static ULONG dir_count;
static ULONG file_count;
static ULONG error_count;
static struct FileInfoBlock fibs[MAX_DEPTH + 1];
static char paths[MAX_DEPTH + 1][PATH_LEN];

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

static void print_indent(int depth)
{
    int i;
    for (i = 0; i < depth; ++i) {
        ai_puts("  ");
    }
}

static void scan_dir(const char *path, int depth)
{
    BPTR lock;
    struct FileInfoBlock *fib;
    char *child;

    if (depth > MAX_DEPTH) {
        ++error_count;
        return;
    }

    fib = &fibs[depth];
    child = paths[depth];

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

    while (ExNext(lock, fib) != 0) {
        int is_dir = fib->fib_DirEntryType >= 0;

        print_indent(depth);
        ai_puts(is_dir ? "[D] " : "    ");
        ai_puts(fib->fib_FileName);
        ai_puts("\n");

        if (!append_name(child, path, fib->fib_FileName)) {
            ++error_count;
            continue;
        }

        if (is_dir) {
            ++dir_count;
            if (depth == MAX_DEPTH) {
                ++error_count;
            } else {
                scan_dir(child, depth + 1);
            }
        } else {
            ++file_count;
        }
    }

    UnLock(lock);
}

int main(int argc, char **argv)
{
    const char *path = "";

    if (argc > 2) {
        ai_puts("Usage: Tree [path]\n");
        return 10;
    }
    if (argc == 2) path = argv[1];

    ai_puts("Tree 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts(path[0] != '\0' ? path : ".");
    ai_puts("\n");

    scan_dir(path, 0);

    ai_puts("\nDirs: ");
    ai_put_u32(dir_count);
    ai_puts("\nFiles: ");
    ai_put_u32(file_count);
    ai_puts("\nErrors: ");
    ai_put_u32(error_count);
    ai_puts("\n");

    return error_count != 0 ? 5 : 0;
}
