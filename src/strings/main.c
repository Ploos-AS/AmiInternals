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

static LONG write_text(LONG length)
{
    if (length <= 0) return 1;
    return Write(Output(), text, length) == length;
}

static LONG write_newline(void)
{
    return Write(Output(), "\n", 1) == 1;
}

int main(int argc, char **argv)
{
    BPTR fh;
    ULONG minimum = 4;
    LONG got = 0;
    LONG used = 0;
    LONG emitted = 0;
    LONG output_ok = 1;
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
                if (used == STRING_BYTES - 1) {
                    if (!write_text(used)) {
                        output_ok = 0;
                        break;
                    }
                    emitted = 1;
                    used = 0;
                }
                text[used++] = (char)input[i];
            } else {
                if (emitted) {
                    if (!write_text(used) || !write_newline()) {
                        output_ok = 0;
                        break;
                    }
                } else if ((ULONG)used >= minimum) {
                    if (!write_text(used) || !write_newline()) {
                        output_ok = 0;
                        break;
                    }
                }
                used = 0;
                emitted = 0;
            }
        }
        if (!output_ok) break;
    }

    if (output_ok && got >= 0) {
        if (emitted) {
            if (!write_text(used) || !write_newline()) output_ok = 0;
        } else if ((ULONG)used >= minimum) {
            if (!write_text(used) || !write_newline()) output_ok = 0;
        }
    }

    Close(fh);
    if (!output_ok) return 5;
    return got < 0 ? 5 : 0;
}
