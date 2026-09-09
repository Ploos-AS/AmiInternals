#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define VALUE_LEN 256

static char value[VALUE_LEN];

static int read_var(const char *name)
{
    BPTR fh;
    LONG got;
    int i;

    fh = Open((STRPTR)name, MODE_OLDFILE);
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
    char path[VALUE_LEN];
    int i;
    int j;

    ai_puts("Env 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    if (argc != 2) {
        ai_puts("Usage: Env name\n");
        return 10;
    }

    path[0] = 'E'; path[1] = 'N'; path[2] = 'V'; path[3] = ':';
    i = 4;
    j = 0;
    while (argv[1][j] != '\0' && i < VALUE_LEN - 1) {
        path[i++] = argv[1][j++];
    }
    path[i] = '\0';

    if (argv[1][j] != '\0') {
        ai_puts("Error: name too long\n");
        return 10;
    }

    if (!read_var(path)) {
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
