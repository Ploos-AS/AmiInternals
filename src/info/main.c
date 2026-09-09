#include <exec/types.h>

#include "ai_compat.h"

static void line_value(const char *label, ULONG value)
{
    ai_puts(label);
    ai_put_u32(value);
    ai_puts(" bytes\n");
}

int main(void)
{
    struct AIExecInfo info;

    ai_get_exec_info(&info);

    ai_puts("Info 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");

    ai_puts("Exec ............ ");
    ai_put_version(info.version, info.revision);
    ai_puts("\n\n");

    line_value("Chip free ....... ", info.chip_free);
    line_value("Chip largest .... ", info.chip_largest);
    line_value("Fast free ....... ", info.fast_free);
    line_value("Fast largest .... ", info.fast_largest);
    line_value("Total free ...... ", info.any_free);
    line_value("Largest block ... ", info.any_largest);

    return 0;
}
