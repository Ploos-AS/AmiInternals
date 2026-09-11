#include <exec/resident.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define RESIDENT_TEXT_MAX 96

static void put_hex32(ULONG value)
{
    static const char digits[] = "0123456789ABCDEF";
    char out[9];
    int shift;
    int i = 0;

    for (shift = 28; shift >= 0; shift -= 4) {
        out[i++] = digits[(value >> shift) & 0x0FUL];
    }
    out[i] = '\0';
    ai_puts(out);
}

static void copy_text(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        dst[0] = '\0';
        return;
    }
    while (i < RESIDENT_TEXT_MAX - 1 && src[i] != '\0') {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct Resident *resident;
    UBYTE version;
    UBYTE flags;
    UBYTE type;
    BYTE priority;
    char name[RESIDENT_TEXT_MAX];
    char id[RESIDENT_TEXT_MAX];

    ai_puts("ROMInfo 0.1\nAmiInternals - Ploos AS\n\n");
    resident = FindResident((STRPTR)"exec.library");
    if (resident == 0) {
        ai_puts("exec.library resident not found\n");
        return 5;
    }
    if (resident->rt_MatchWord != RTC_MATCHWORD || resident->rt_MatchTag != resident) {
        ai_puts("Invalid exec.library resident\n");
        return 5;
    }

    Forbid();
    version = resident->rt_Version;
    flags = resident->rt_Flags;
    type = resident->rt_Type;
    priority = resident->rt_Pri;
    copy_text(name, resident->rt_Name);
    copy_text(id, resident->rt_IdString);
    Permit();

    ai_puts("Resident 0x");
    put_hex32((ULONG)resident);
    ai_puts("\nVersion ");
    ai_put_u32((ULONG)version);
    ai_puts("\nFlags 0x");
    put_hex32((ULONG)flags);
    ai_puts("\nType ");
    ai_put_u32((ULONG)type);
    ai_puts("\nPriority ");
    ai_put_s32((LONG)priority);
    ai_puts("\nName ");
    ai_puts(name[0] != '\0' ? name : "<unnamed>");
    ai_puts("\nId ");
    ai_puts(id[0] != '\0' ? id : "<none>");
    ai_puts("\n");
    return 0;
}
