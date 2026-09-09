#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define BUFFER_SIZE 512
#define DEFAULT_LINES 10

static char buffer[BUFFER_SIZE];

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
    LONG end;
    LONG pos;
    LONG got = 0;
    LONG lines = 0;
    LONG i;

    ai_puts("Tail 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 3) {
        ai_puts("Usage: Tail file [lines]\n");
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

    if (Seek(fh, 0, OFFSET_END) < 0) {
        Close(fh);
        ai_puts("Cannot seek file\n");
        return 5;
    }
    end = Seek(fh, 0, OFFSET_CURRENT);
    if (end < 0) {
        Close(fh);
        ai_puts("Cannot determine file size\n");
        return 5;
    }
    pos = end;

    while (pos > 0 && lines <= wanted) {
        LONG chunk = pos > BUFFER_SIZE ? BUFFER_SIZE : pos;
        pos -= chunk;
        if (Seek(fh, pos, OFFSET_BEGINNING) < 0) {
            Close(fh);
            return 5;
        }
        got = Read(fh, buffer, chunk);
        if (got != chunk) {
            Close(fh);
            return 5;
        }
        for (i = got - 1; i >= 0; --i) {
            if (buffer[i] == '\n') {
                ++lines;
                if (lines > wanted) {
                    pos += i + 1;
                    goto found_start;
                }
            }
        }
    }
    pos = 0;

found_start:
    if (Seek(fh, pos, OFFSET_BEGINNING) < 0) {
        Close(fh);
        return 5;
    }
    while ((got = Read(fh, buffer, BUFFER_SIZE)) > 0)
        Write(Output(), buffer, got);

    Close(fh);
    return got < 0 ? 5 : 0;
}
