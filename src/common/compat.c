#include <exec/execbase.h>
#include <exec/memory.h>
#include <proto/exec.h>

#include "ai_compat.h"

void ai_get_exec_info(struct AIExecInfo *info)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;

    info->version = sysbase->LibNode.lib_Version;
    info->revision = sysbase->LibNode.lib_Revision;

    info->chip_free = AvailMem(MEMF_CHIP);
    info->fast_free = AvailMem(MEMF_FAST);
    info->any_free = AvailMem(MEMF_ANY);

    info->chip_largest = AvailMem(MEMF_CHIP | MEMF_LARGEST);
    info->fast_largest = AvailMem(MEMF_FAST | MEMF_LARGEST);
    info->any_largest = AvailMem(MEMF_ANY | MEMF_LARGEST);
}
