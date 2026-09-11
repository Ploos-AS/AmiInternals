#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static void file_puts(BPTR file, const char *text)
{
    const char *p = text;
    LONG len = 0;

    while (*p++) {
        ++len;
    }
    if (len > 0) {
        Write(file, (APTR)text, len);
    }
}

static void file_put_u32(BPTR file, ULONG value)
{
    char buf[11];
    int i = 10;

    buf[i] = '\0';
    do {
        buf[--i] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);
    file_puts(file, &buf[i]);
}

static void write_direct_evidence(int argc, char **argv)
{
    BPTR file;
    int i;

    file = Open("SYS:Q4/arg-direct.txt", MODE_NEWFILE);
    if (file == 0) {
        return;
    }

    file_puts(file, "Q4ArgProbe 0.2\n");
    file_puts(file, "argc: ");
    file_put_u32(file, (ULONG)argc);
    file_puts(file, "\n");

    for (i = 0; i < argc; ++i) {
        file_puts(file, "argv[");
        file_put_u32(file, (ULONG)i);
        file_puts(file, "]: ");
        file_puts(file, argv[i] != 0 ? argv[i] : "<null>");
        file_puts(file, "\n");
    }

    Close(file);
}

int main(int argc, char **argv)
{
    int i;

    write_direct_evidence(argc, argv);

    ai_puts("Q4ArgProbe 0.2\n");
    ai_puts("argc: ");
    ai_put_u32((ULONG)argc);
    ai_puts("\n");

    for (i = 0; i < argc; ++i) {
        ai_puts("argv[");
        ai_put_u32((ULONG)i);
        ai_puts("]: ");
        ai_puts(argv[i] != 0 ? argv[i] : "<null>");
        ai_puts("\n");
    }

    return 0;
}
