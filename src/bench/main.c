#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define DEFAULT_LOOPS 200000UL

static volatile ULONG sink;

static LONG parse_loops(const char *s, ULONG *out)
{
    ULONG value = 0;
    if (s == 0 || *s == '\0') return 0;
    while (*s != '\0') {
        ULONG digit;
        if (*s < '0' || *s > '9') return 0;
        digit = (ULONG)(*s - '0');
        if (value > (4000000000UL - digit) / 10UL) return 0;
        value = value * 10UL + digit;
        ++s;
    }
    if (value == 0) return 0;
    *out = value;
    return 1;
}

static ULONG stamp_ticks(const struct DateStamp *ds)
{
    return (ULONG)ds->ds_Days * 24UL * 60UL * (ULONG)TICKS_PER_SECOND +
           (ULONG)ds->ds_Minute * 60UL * (ULONG)TICKS_PER_SECOND +
           (ULONG)ds->ds_Tick;
}

int main(int argc, char **argv)
{
    struct DateStamp before;
    struct DateStamp after;
    ULONG loops = DEFAULT_LOOPS;
    ULONG i;
    ULONG start;
    ULONG end;

    ai_puts("Bench 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: Bench [loops]\n");
        return 10;
    }
    if (argc == 2 && !parse_loops(argv[1], &loops)) {
        ai_puts("Invalid loop count\n");
        return 10;
    }

    DateStamp(&before);
    for (i = 0; i < loops; ++i) {
        sink = (sink + i) ^ (i >> 3);
    }
    DateStamp(&after);

    start = stamp_ticks(&before);
    end = stamp_ticks(&after);

    ai_puts("Loops         ");
    ai_put_u32(loops);
    ai_puts("\nElapsed ticks ");
    ai_put_u32(end - start);
    ai_puts("\nChecksum      ");
    ai_put_u32(sink);
    ai_puts("\n");
    return 0;
}
