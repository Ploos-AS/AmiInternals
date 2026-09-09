#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static BPTR ai_stdout(void)
{
    return Output();
}

void ai_puts(const char *text)
{
    const char *p = text;
    LONG len = 0;

    while (*p++) {
        ++len;
    }

    if (len > 0) {
        Write(ai_stdout(), (APTR)text, len);
    }
}

void ai_put_u32(ULONG value)
{
    char buf[11];
    int i = 10;

    buf[i] = '\0';
    do {
        buf[--i] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    ai_puts(&buf[i]);
}

void ai_put_version(UWORD version, UWORD revision)
{
    ai_put_u32((ULONG)version);
    ai_puts(".");
    ai_put_u32((ULONG)revision);
}
