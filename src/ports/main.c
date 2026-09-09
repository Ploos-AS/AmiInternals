#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/ports.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_PORTS 64
#define PORT_NAME_LEN 64

struct PortRow {
    UBYTE signal_bit;
    char name[PORT_NAME_LEN];
};

static struct PortRow rows[MAX_PORTS];

static void copy_name(char *dst, const char *src)
{
    int i = 0;

    if (src == 0) {
        src = "<unnamed>";
    }

    while (i < PORT_NAME_LEN - 1 && src[i] != '\0') {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = '\0';
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct Node *node;
    int count = 0;
    int i;

    Forbid();
    for (node = sysbase->PortList.lh_Head;
         node != 0 && node->ln_Succ != 0 && count < MAX_PORTS;
         node = node->ln_Succ) {
        struct MsgPort *port = (struct MsgPort *)node;

        rows[count].signal_bit = port->mp_SigBit;
        copy_name(rows[count].name, port->mp_Node.ln_Name);
        ++count;
    }
    Permit();

    ai_puts("Ports 0.1\n");
    ai_puts("AmiInternals - Ploos AS\n\n");
    ai_puts("Sig Name\n");

    for (i = 0; i < count; ++i) {
        ai_put_u32((ULONG)rows[i].signal_bit);
        ai_puts(" ");
        ai_puts(rows[i].name);
        ai_puts("\n");
    }

    if (count >= MAX_PORTS) {
        ai_puts("\nWarning: port list truncated\n");
    }

    return 0;
}
