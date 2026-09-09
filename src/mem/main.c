#include <exec/types.h>

#include "ai_compat.h"

static void line_value(const char *label, ULONG value)
{
    ai_puts(label);
    ai_put_u32(value);
    ai_puts(" bytes\n");
}

static void memory_group(const char *name, ULONG free_bytes, ULONG largest)
{
    ai_puts(name);
    ai_puts("\n");
    line_value("  Free .......... ", free_bytes);
    line_value("  Largest ....... ", largest);
    line_value("  Fragmented .... ", free_bytes - largest);
}

int main(void)
{
    struct AIExecInfo info;

    ai_get_exec_info(&info);

    ai_puts("Mem 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    memory_group("Chip", info.chip_free, info.chip_largest);
    ai_puts("\n");
    memory_group("Fast", info.fast_free, info.fast_largest);
    ai_puts("\n");
    memory_group("All", info.any_free, info.any_largest);

    return 0;
}
