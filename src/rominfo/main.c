#include <exec/resident.h>
#include <proto/exec.h>

#include "ai_compat.h"

int main(void)
{
    struct Resident *resident;

    ai_puts("ROMInfo 0.1\nAmiInternals - Ploos AS\n\n");
    resident = FindResident((STRPTR)"exec.library");
    if (resident == 0) {
        ai_puts("exec.library resident not found\n");
        return 5;
    }

    ai_puts("Resident 0x");
    ai_put_hex32((ULONG)resident);
    ai_puts("\nVersion ");
    ai_put_u32((ULONG)resident->rt_Version);
    ai_puts("\nFlags 0x");
    ai_put_hex32((ULONG)resident->rt_Flags);
    ai_puts("\nType ");
    ai_put_u32((ULONG)resident->rt_Type);
    ai_puts("\nPriority ");
    ai_put_s32((LONG)resident->rt_Pri);
    ai_puts("\nName ");
    ai_puts(resident->rt_Name != 0 ? resident->rt_Name : "<unnamed>");
    ai_puts("\nId ");
    ai_puts(resident->rt_IdString != 0 ? resident->rt_IdString : "<none>");
    ai_puts("\n");
    return 0;
}
