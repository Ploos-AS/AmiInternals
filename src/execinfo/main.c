#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/nodes.h>

#include "ai_compat.h"

static ULONG count_list(struct List *list, ULONG limit)
{
    ULONG count = 0;
    struct Node *node;
    for (node = list->lh_Head; node && node->ln_Succ && count < limit; node = node->ln_Succ) {
        ++count;
    }
    return count;
}

static void value(const char *label, ULONG v)
{
    ai_puts(label);
    ai_put_u32(v);
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    ULONG ready;
    ULONG wait;
    ULONG libs;
    ULONG devices;
    ULONG resources;
    ULONG ports;

    ready = count_list(&sysbase->TaskReady, 1024);
    wait = count_list(&sysbase->TaskWait, 1024);
    libs = count_list(&sysbase->LibList, 1024);
    devices = count_list(&sysbase->DeviceList, 1024);
    resources = count_list(&sysbase->ResourceList, 1024);
    ports = count_list(&sysbase->PortList, 1024);

    ai_puts("ExecInfo 0.1\nAmiInternals - Ploos AS\n\n");
    ai_puts("Exec version ..... ");
    ai_put_version(sysbase->LibNode.lib_Version, sysbase->LibNode.lib_Revision);
    ai_puts("\n");
    value("SysBase ......... ", (ULONG)sysbase);
    value("ThisTask ........ ", (ULONG)sysbase->ThisTask);
    value("Task ready ...... ", ready);
    value("Task wait ....... ", wait);
    value("Libraries ....... ", libs);
    value("Devices ......... ", devices);
    value("Resources ....... ", resources);
    value("Ports ........... ", ports);
    value("AttnFlags ....... ", (ULONG)sysbase->AttnFlags);
    value("ID nest ......... ", (ULONG)(UBYTE)sysbase->IDNestCnt);
    value("TD nest ......... ", (ULONG)(UBYTE)sysbase->TDNestCnt);
    return 0;
}
