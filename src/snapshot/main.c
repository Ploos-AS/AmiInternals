#include <exec/execbase.h>
#include <exec/lists.h>
#include <proto/exec.h>

#include "ai_compat.h"

#define MAX_LIST_NODES 512

struct ListCount {
    ULONG count;
    LONG truncated;
};

static struct ListCount count_list(struct List *list)
{
    struct ListCount result;
    struct Node *node;

    result.count = 0;
    result.truncated = 0;

    for (node = list->lh_Head;
         node != 0 && node->ln_Succ != 0 && result.count < MAX_LIST_NODES;
         node = node->ln_Succ) {
        ++result.count;
    }

    if (node != 0 && node->ln_Succ != 0) {
        result.truncated = 1;
    }

    return result;
}

static void put_key_u32(const char *key, ULONG value)
{
    ai_puts(key);
    ai_puts("=");
    ai_put_u32(value);
    ai_puts("\n");
}

int main(void)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    struct AIExecInfo info;
    struct ListCount ready;
    struct ListCount waiting;
    struct ListCount libraries;
    struct ListCount devices;
    struct ListCount resources;
    ULONG truncated;

    if (sysbase == 0) {
        ai_puts("Snapshot 0.1\nAmiInternals - Ploos AS\n\nERROR=SysBase unavailable\n");
        return 5;
    }

    ai_get_exec_info(&info);

    Forbid();
    ready = count_list(&sysbase->TaskReady);
    waiting = count_list(&sysbase->TaskWait);
    libraries = count_list(&sysbase->LibList);
    devices = count_list(&sysbase->DeviceList);
    resources = count_list(&sysbase->ResourceList);
    Permit();

    truncated = (ULONG)(ready.truncated || waiting.truncated ||
                        libraries.truncated || devices.truncated ||
                        resources.truncated);

    ai_puts("Snapshot 0.1\nAmiInternals - Ploos AS\n\n");
    put_key_u32("FORMAT", 1);
    put_key_u32("EXEC_VERSION", (ULONG)info.version);
    put_key_u32("EXEC_REVISION", (ULONG)info.revision);
    put_key_u32("CHIP_FREE", info.chip_free);
    put_key_u32("FAST_FREE", info.fast_free);
    put_key_u32("ANY_FREE", info.any_free);
    put_key_u32("CHIP_LARGEST", info.chip_largest);
    put_key_u32("FAST_LARGEST", info.fast_largest);
    put_key_u32("ANY_LARGEST", info.any_largest);
    put_key_u32("TASK_READY", ready.count);
    put_key_u32("TASK_WAIT", waiting.count);
    put_key_u32("LIBRARIES", libraries.count);
    put_key_u32("DEVICES", devices.count);
    put_key_u32("RESOURCES", resources.count);
    put_key_u32("TRUNCATED", truncated);

    return truncated ? 5 : 0;
}
