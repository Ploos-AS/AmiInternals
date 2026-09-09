#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static struct InfoData info_data;

int main(int argc, char **argv)
{
    STRPTR path = (STRPTR)"DF0:";
    BPTR lock;
    LONG errors = 0;
    ULONG total;
    ULONG used;
    ULONG block_size;

    ai_puts("DiskCheck 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: DiskCheck [volume]\n");
        return 10;
    }
    if (argc == 2) path = (STRPTR)argv[1];

    lock = Lock(path, ACCESS_READ);
    if (lock == 0) {
        ai_puts("Status INACCESSIBLE\n");
        return 5;
    }
    if (Info(lock, &info_data) == 0) {
        UnLock(lock);
        ai_puts("Status INFO_FAILED\n");
        return 5;
    }
    UnLock(lock);

    total = info_data.id_NumBlocks >= 0 ? (ULONG)info_data.id_NumBlocks : 0;
    used = info_data.id_NumBlocksUsed >= 0 ? (ULONG)info_data.id_NumBlocksUsed : 0;
    block_size = info_data.id_BytesPerBlock >= 0 ? (ULONG)info_data.id_BytesPerBlock : 0;

    if (block_size == 0) { ai_puts("Problem ZERO_BLOCK_SIZE\n"); ++errors; }
    if (total == 0) { ai_puts("Problem ZERO_TOTAL_BLOCKS\n"); ++errors; }
    if (used > total) { ai_puts("Problem USED_GT_TOTAL\n"); ++errors; }

    ai_puts("BlockSize "); ai_put_u32(block_size); ai_puts("\n");
    ai_puts("TotalBlocks "); ai_put_u32(total); ai_puts("\n");
    ai_puts("UsedBlocks "); ai_put_u32(used); ai_puts("\n");
    ai_puts("Problems "); ai_put_u32((ULONG)errors); ai_puts("\n");
    ai_puts(errors == 0 ? "Status BASIC_CHECK_PASS\n" : "Status BASIC_CHECK_FAIL\n");
    return errors == 0 ? 0 : 5;
}
