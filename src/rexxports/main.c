#include <exec/execbase.h>
#include <exec/ports.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_PORTS 128
#define NAME_LEN 80

struct PortSnap {
    UBYTE sigbit;
    char name[NAME_LEN];
};

static struct PortSnap ports[MAX_PORTS];

static void copy_name(char *dst, const char *src)
{
    ULONG i = 0;
    if (src == 0) {
        dst[0] = '-';
        dst[1] = '\0';
        return;
    }
    while (src[i] != '\0' && i + 1 < NAME_LEN) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct ExecBase *SysBase = *(struct ExecBase **)4;
    struct MsgPort *p;
    ULONG count = 0;

    ai_puts("RexxPorts 0.1\nAmiInternals - Ploos AS\n\n");
    if (SysBase == 0) return 20;

    Forbid();
    p = (struct MsgPort *)SysBase->PortList.lh_Head;
    while (p != 0 && p->mp_Node.ln_Succ != 0 && count < MAX_PORTS) {
        if (p->mp_Node.ln_Name != 0 && p->mp_Node.ln_Name[0] != '\0') {
            ports[count].sigbit = p->mp_SigBit;
            copy_name(ports[count].name, p->mp_Node.ln_Name);
            ++count;
        }
        p = (struct MsgPort *)p->mp_Node.ln_Succ;
    }
    Permit();

    ai_puts("Sig Name\n");
    for (ULONG i = 0; i < count; ++i) {
        ai_put_u32((ULONG)ports[i].sigbit);
        ai_puts(" ");
        ai_puts(ports[i].name);
        ai_puts("\n");
    }
    ai_puts("\nNamed public ports: ");
    ai_put_u32(count);
    ai_puts("\nNote: Exec MsgPorts are not type-tagged as ARexx; names are candidates only.\n");
    return 0;
}
