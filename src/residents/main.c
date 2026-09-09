#include <exec/execbase.h>
#include <exec/resident.h>

#include "ai_compat.h"

#define MAX_RESIDENTS 128
#define RESIDENT_NAME_LEN 64

struct ResidentRow {
    UBYTE version;
    UBYTE type;
    BYTE priority;
    char name[RESIDENT_NAME_LEN];
};

static struct ResidentRow rows[MAX_RESIDENTS];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < RESIDENT_NAME_LEN - 1 && src[i] != '\0') {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    APTR *modules = (APTR *)sysbase->ResModules;
    int count = 0;
    int i;

    if (modules != 0) {
        while (modules[count] != 0 && count < MAX_RESIDENTS) {
            struct Resident *resident = (struct Resident *)modules[count];

            if (resident != 0 &&
                resident->rt_MatchWord == RTC_MATCHWORD &&
                resident->rt_MatchTag == resident) {
                rows[count].version = resident->rt_Version;
                rows[count].type = resident->rt_Type;
                rows[count].priority = resident->rt_Pri;
                copy_name(rows[count].name, resident->rt_Name);
            } else {
                rows[count].version = 0;
                rows[count].type = 0;
                rows[count].priority = 0;
                copy_name(rows[count].name, "<invalid resident>");
            }
            ++count;
        }
    }

    ai_puts("Residents 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Ver Type Pri Name\n");

    for (i = 0; i < count; ++i) {
        ai_put_u32((ULONG)rows[i].version);
        ai_puts(" ");
        ai_put_u32((ULONG)rows[i].type);
        ai_puts(" ");
        ai_put_s32((LONG)rows[i].priority);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_RESIDENTS) {
        ai_puts("\nWarning: resident list truncated\n");
    }

    return 0;
}
