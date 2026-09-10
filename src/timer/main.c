#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static LONG parse_ticks(const char *s)
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
    LONG requested = 1;
    ULONG start;
    ULONG end;

    ai_puts("Timer 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: Timer [ticks]\n");
        return 10;
    }
    if (argc == 2) {
        requested = parse_ticks(argv[1]);
        if (requested < 0) {
            ai_puts("Invalid tick count\n");
            return 10;
        }
    }

    DateStamp(&before);
    if (requested > 0) Delay(requested);
    DateStamp(&after);

    start = stamp_ticks(&before);
    end = stamp_ticks(&after);

    ai_puts("Requested ticks ");
    ai_put_u32((ULONG)requested);
    ai_puts("\nElapsed ticks   ");
    ai_put_u32(end - start);
    ai_puts("\n");
    return 0;
}
