#include <dos/dos.h>
#include <dos/dosextens.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define MAX_DEPTH 16
#define PATH_LEN 256

/*
 * Keep recursive DOS work buffers out of the CLI stack.  Static storage also
 * gives FileInfoBlock the compiler's natural alignment, which is important on
 * classic 68k DOS implementations.
 */
static struct FileInfoBlock fib_slots[MAX_DEPTH + 1];
static char path_slots[MAX_DEPTH + 1][PATH_LEN];

static ULONG match_count;
static ULONG error_count;

static int chareq(char a, char b)
{
    if (a >= 'A' && a <= 'Z') a = (char)(a - 'A' + 'a');
    if (b >= 'A' && b <= 'Z') b = (char)(b - 'A' + 'a');
    return a == b;
}

static int contains_ci(const char *text, const char *needle)
{
    int i;
    int j;

    if (needle[0] == '\0') return 1;

    for (i = 0; text[i] != '\0'; ++i) {
        for (j = 0; needle[j] != '\0' && text[i + j] != '\0'; ++j) {
            if (!chareq(text[i + j], needle[j])) break;
        }
        if (needle[j] == '\0') return 1;
    }
    return 0;
}

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

static void scan_dir(const char *path, const char *needle, int depth)
{
    BPTR lock;
    struct FileInfoBlock *fib;

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

    while (ExNext(lock, fib) != 0) {
        char *child = path_slots[depth];

        if (!append_name(child, path, fib->fib_FileName)) {
            ++error_count;
            continue;
        }

        if (contains_ci(fib->fib_FileName, needle)) {
            ai_puts(child);
            ai_puts("\n");
            ++match_count;
        }

        if (fib->fib_DirEntryType >= 0) {
            if (depth < MAX_DEPTH) {
                scan_dir(child, needle, depth + 1);
            } else {
                ++error_count;
            }
        }
    }

    UnLock(lock);
}

int main(int argc, char **argv)
{
    const char *needle;
    const char *path = "";

    if (argc < 2 || argc > 3) {
        ai_puts("Usage: Find pattern [path]\n");
        return 10;
    }

    needle = argv[1];
    if (argc == 3) path = argv[2];

    ai_puts("Find 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    scan_dir(path, needle, 0);

    ai_puts("\nMatches: ");
    ai_put_u32(match_count);
    ai_puts("\nErrors: ");
    ai_put_u32(error_count);
    ai_puts("\n");

    return error_count != 0 ? 5 : 0;
}
