#include "ai_compat.h"

int main(int argc, char **argv)
{
    int i;

    ai_puts("Q4ArgProbe 0.1\n");
    ai_puts("argc: ");
    ai_put_u32((ULONG)argc);
    ai_puts("\n");

    for (i = 0; i < argc; ++i) {
        ai_puts("argv[");
        ai_put_u32((ULONG)i);
        ai_puts("]: ");
        ai_puts(argv[i] != 0 ? argv[i] : "<null>");
        ai_puts("\n");
    }

    return 0;
}
