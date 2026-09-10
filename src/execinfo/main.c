#include <exec/execbase.h>
#include <exec/lists.h>
#include <exec/nodes.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define LIST_LIMIT 1024

struct ListCount {
    ULONG count;
    LONG truncated;
};

struct ExecSnapshot {
    UWORD version;
    UWORD revision;
    ULONG sysbase;
    ULONG this_task;
    struct ListCount ready;
    struct ListCount wait;
    struct ListCount libs;
    struct ListCount devices;
    struct ListCount resources;
    struct ListCount ports;
    ULONG attn_flags;
    UBYTE id_nest;
    UBYTE td_nest;
};

static struct ExecSnapshot snapshot;

static struct ListCount count_list(struct List *list)
{
    struct ListCount result;
    struct Node *node;

    result.count = 0;
    result.truncated = 0;

    for (node = list->lh_Head; node && node->ln_Succ && result.count < LIST_LIMIT; node = node->ln_Succ) {
        ++result.count;
    }
    if (node && node->ln_Succ) result.truncated = 1;
    return result;
}

static void value(const char *label, ULONG v)
{
    ai_puts(label);
    ai_put_u32(v);
    ai_puts("\n");
}

static void list_value(const char *label, struct ListCount result)
{
    ai_puts(label);
    ai_put_u32(result.count);
    if (result.truncated) ai_puts("+");
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;

    ai_puts("ExecInfo 0.1\nAmiInternals - Ploos AS\n\n");

    if (!sysbase) {
        ai_puts("SysBase unavailable\n");
        return 5;
    }

    Forbid();
    snapshot.version = sysbase->LibNode.lib_Version;
    snapshot.revision = sysbase->LibNode.lib_Revision;
    snapshot.sysbase = (ULONG)sysbase;
    snapshot.this_task = (ULONG)sysbase->ThisTask;
    snapshot.ready = count_list(&sysbase->TaskReady);
    snapshot.wait = count_list(&sysbase->TaskWait);
    snapshot.libs = count_list(&sysbase->LibList);
    snapshot.devices = count_list(&sysbase->DeviceList);
    snapshot.resources = count_list(&sysbase->ResourceList);
    snapshot.ports = count_list(&sysbase->PortList);
    snapshot.attn_flags = (ULONG)sysbase->AttnFlags;
    snapshot.id_nest = (UBYTE)sysbase->IDNestCnt;
    snapshot.td_nest = (UBYTE)sysbase->TDNestCnt;
    Permit();

    ai_puts("Exec version ..... ");
    ai_put_version(snapshot.version, snapshot.revision);
    ai_puts("\n");
    value("SysBase ......... ", snapshot.sysbase);
    value("ThisTask ........ ", snapshot.this_task);
    list_value("Task ready ...... ", snapshot.ready);
    list_value("Task wait ....... ", snapshot.wait);
    list_value("Libraries ....... ", snapshot.libs);
    list_value("Devices ......... ", snapshot.devices);
    list_value("Resources ....... ", snapshot.resources);
    list_value("Ports ........... ", snapshot.ports);
    value("AttnFlags ....... ", snapshot.attn_flags);
    value("ID nest ......... ", (ULONG)snapshot.id_nest);
    value("TD nest ......... ", (ULONG)snapshot.td_nest);

    if (snapshot.ready.truncated || snapshot.wait.truncated || snapshot.libs.truncated ||
        snapshot.devices.truncated || snapshot.resources.truncated || snapshot.ports.truncated) {
        ai_puts("Note: '+' means traversal reached the 1024-node safety limit\n");
    }
    return 0;
}
