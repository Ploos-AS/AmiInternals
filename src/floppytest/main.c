#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static struct InfoData info_data;

int main(int argc, char **argv)
{
    STRPTR path = (STRPTR)"DF0:";
    BPTR lock;
    ULONG total;
    ULONG used;
    ULONG block_size;

    ai_puts("FloppyTest 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: FloppyTest [volume]\n");
        return 10;
    }
    if (argc == 2) path = (STRPTR)argv[1];

    lock = Lock(path, ACCESS_READ);
    if (lock == 0) {
        ai_puts("Media NOT ACCESSIBLE\n");
        return 5;
    }
    if (Info(lock, &info_data) == 0) {
        UnLock(lock);
        ai_puts("Media information unavailable\n");
        return 5;
    }
    UnLock(lock);

    if (info_data.id_NumBlocks <= 0 ||
        info_data.id_NumBlocksUsed < 0 ||
        info_data.id_NumBlocksUsed > info_data.id_NumBlocks ||
        info_data.id_BytesPerBlock <= 0) {
        ai_puts("Media information invalid\n");
        return 5;
    }

    total = (ULONG)info_data.id_NumBlocks;
    used = (ULONG)info_data.id_NumBlocksUsed;
    block_size = (ULONG)info_data.id_BytesPerBlock;

    ai_puts("Media ACCESSIBLE\n");
    ai_puts("BlockSize "); ai_put_u32(block_size); ai_puts("\n");
    ai_puts("TotalBlocks "); ai_put_u32(total); ai_puts("\n");
    ai_puts("UsedBlocks "); ai_put_u32(used); ai_puts("\n");
    ai_puts("DOSReadOnlyProbe PASS\n");
    ai_puts("SectorReadTest NOT PERFORMED\n");
    return 0;
}
