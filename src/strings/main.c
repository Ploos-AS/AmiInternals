#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define READ_BYTES 256
#define STRING_BYTES 256

static UBYTE input[READ_BYTES];
static char text[STRING_BYTES];

static LONG parse_count(const char *s, ULONG *value)
{
    ULONG v = 0;
    ULONG digit;

    if (!s || !*s) return 0;
    while (*s) {
        if (*s < '0' || *s > '9') return 0;
        digit = (ULONG)(*s - '0');
        if (v > 3276 || (v == 3276 && digit > 7)) return 0;
        v = v * 10 + digit;
        ++s;
    }
    *value = v;
    return 1;
}

static LONG printable(UBYTE c)
{
    return c >= 32 && c <= 126;
}

static void emit_text(LONG length)
{
    if (length > 0) Write(Output(), text, length);
    Write(Output(), "\n", 1);
}

int main(int argc, char **argv)
{
    BPTR fh;
    ULONG minimum = 4;
    LONG got = 0;
    LONG used = 0;
    LONG i;

    ai_puts("Strings 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 3) {
        ai_puts("Usage: Strings file [minimum]\n");
        return 10;
    }
    if (argc == 3 && (!parse_count(argv[2], &minimum) || minimum == 0 || minimum >= STRING_BYTES)) {
        ai_puts("Invalid minimum\n");
        return 10;
    }

    fh = Open((STRPTR)argv[1], MODE_OLDFILE);
    if (!fh) {
        ai_puts("Cannot open file\n");
        return 5;
    }

    for (;;) {
        got = Read(fh, input, READ_BYTES);
        if (got <= 0) break;

        for (i = 0; i < got; ++i) {
            if (printable(input[i])) {
                if (used < STRING_BYTES - 1) {
                    text[used++] = (char)input[i];
                } else {
                    emit_text(used);
                    used = 0;
                    text[used++] = (char)input[i];
                }
            } else {
                if ((ULONG)used >= minimum) emit_text(used);
                used = 0;
            }
        }
    }

    if (got >= 0 && (ULONG)used >= minimum) emit_text(used);
    Close(fh);
    return got < 0 ? 5 : 0;
}
