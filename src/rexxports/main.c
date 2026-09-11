#include <exec/execbase.h>
#include <exec/ports.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_PORTS 128
#define MAX_PORT_VISITS 1024
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
    ULONG visits = 0;
    LONG truncated = 0;

    ai_puts("RexxPorts 0.1\nAmiInternals - Ploos AS\n\n");
    if (SysBase == 0) return 20;

    Forbid();
    p = (struct MsgPort *)SysBase->PortList.lh_Head;
    while (p != 0 && p->mp_Node.ln_Succ != 0 && visits < MAX_PORT_VISITS) {
        ++visits;
        if (p->mp_Node.ln_Name != 0 && p->mp_Node.ln_Name[0] != '\0') {
            if (count < MAX_PORTS) {
                ports[count].sigbit = p->mp_SigBit;
                copy_name(ports[count].name, p->mp_Node.ln_Name);
                ++count;
            } else {
                truncated = 1;
            }
        }
        p = (struct MsgPort *)p->mp_Node.ln_Succ;
    }
    if (p != 0 && p->mp_Node.ln_Succ != 0) truncated = 1;
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
    if (truncated) {
        ai_puts("Warning: public port snapshot truncated.\n");
        return 5;
    }
    return 0;
}
