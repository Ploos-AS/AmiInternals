#include <proto/dos.h>

#include "ai_compat.h"

#define DEFAULT_SAMPLES 5
#define MAX_SAMPLES 100

static LONG parse_samples(const char *s)
{
    LONG value = 0;
    if (s == 0 || *s == '\0') return -1;
    while (*s != '\0') {
        if (*s < '0' || *s > '9') return -1;
        value = value * 10 + (*s - '0');
        if (value > MAX_SAMPLES) return -1;
        ++s;
    }
    return value > 0 ? value : -1;
}

int main(int argc, char **argv)
{
    LONG samples = DEFAULT_SAMPLES;
    LONG i;
    struct AIExecInfo info;
    ULONG first_any = 0;
    ULONG last_any = 0;

    ai_puts("WatchMem 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: WatchMem [samples]\n");
        return 10;
    }
    if (argc == 2) {
        samples = parse_samples(argv[1]);
        if (samples < 1) {
            ai_puts("Invalid sample count (1-100)\n");
            return 10;
        }
    }

    ai_puts("Sample ChipFree FastFree TotalFree\n");
    for (i = 0; i < samples; ++i) {
        ai_get_exec_info(&info);
        if (i == 0) first_any = info.any_free;
        last_any = info.any_free;

        ai_put_u32((ULONG)(i + 1));
        ai_puts(" ");
        ai_put_u32(info.chip_free);
        ai_puts(" ");
        ai_put_u32(info.fast_free);
        ai_puts(" ");
        ai_put_u32(info.any_free);
        ai_puts("\n");

        if (i + 1 < samples) Delay(1);
    }

    ai_puts("FirstTotal ");
    ai_put_u32(first_any);
    ai_puts("\nLastTotal ");
    ai_put_u32(last_any);
    ai_puts("\n");
    return 0;
}
