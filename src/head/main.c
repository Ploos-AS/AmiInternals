#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define READ_SIZE 256
#define DEFAULT_LINES 10

static char buffer[READ_SIZE];

static LONG parse_count(const char *s)
{
    LONG value = 0;
    if (s == 0 || *s == '\0') return -1;
    while (*s != '\0') {
        if (*s < '0' || *s > '9') return -1;
        value = value * 10 + (*s - '0');
        if (value > 32767) return -1;
        ++s;
    }
    return value;
}

int main(int argc, char **argv)
{
    BPTR fh;
    LONG wanted = DEFAULT_LINES;
    LONG lines = 0;
    LONG got;
    LONG i;

    ai_puts("Head 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 3) {
        ai_puts("Usage: Head file [lines]\n");
        return 10;
    }
    if (argc == 3) {
        wanted = parse_count(argv[2]);
        if (wanted < 0) {
            ai_puts("Invalid line count\n");
            return 10;
        }
    }
    if (wanted == 0) return 0;

    fh = Open((STRPTR)argv[1], MODE_OLDFILE);
    if (!fh) {
        ai_puts("Cannot open file\n");
        return 5;
    }

    while (lines < wanted && (got = Read(fh, buffer, READ_SIZE)) > 0) {
        LONG start = 0;
        for (i = 0; i < got; ++i) {
            if (buffer[i] == '\n') {
                ++lines;
                if (lines >= wanted) {
                    LONG count = i - start + 1;
                    if (Write(Output(), buffer + start, count) != count) {
                        Close(fh);
                        return 5;
                    }
                    Close(fh);
                    return 0;
                }
            }
        }
        if (Write(Output(), buffer + start, got - start) != got - start) {
            Close(fh);
            return 5;
        }
    }

    Close(fh);
    return got < 0 ? 5 : 0;
}
