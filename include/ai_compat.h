#ifndef AI_COMPAT_H
#define AI_COMPAT_H

#include <exec/types.h>

struct AIExecInfo {
    UWORD version;
    UWORD revision;
    ULONG chip_free;
    ULONG fast_free;
    ULONG any_free;
    ULONG chip_largest;
    ULONG fast_largest;
    ULONG any_largest;
};

void ai_get_exec_info(struct AIExecInfo *info);
void ai_puts(const char *text);
void ai_put_u32(ULONG value);
void ai_put_version(UWORD version, UWORD revision);

#endif
