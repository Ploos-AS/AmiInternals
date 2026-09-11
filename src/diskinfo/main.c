#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static struct InfoData info_data;

static void put_hex32(ULONG value)
{
    static const char digits[] = "0123456789ABCDEF";
    char text[9];
    int i;

    for (i = 7; i >= 0; --i) {
        text[i] = digits[value & 0x0f];
        value >>= 4;
    }
    text[8] = '\0';
    ai_puts(text);
}

static int put_byte_count(ULONG blocks, ULONG block_size)
{
    if (block_size != 0 && blocks > 0xffffffffUL / block_size) {
        ai_puts("OVERFLOW");
        return 0;
    }
    ai_put_u32(blocks * block_size);
    return 1;
}

int main(int argc, char **argv)
{
    STRPTR path = (STRPTR)"";
    BPTR lock;
    ULONG total;
    ULONG used;
    ULONG free_blocks;
    ULONG block_size;
    int complete = 1;

    ai_puts("DiskInfo 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: DiskInfo [path]\n");
        return 10;
    }
    if (argc == 2) path = (STRPTR)argv[1];

    lock = Lock(path, ACCESS_READ);
    if (lock == 0) {
        ai_puts("Cannot lock path\n");
        return 5;
    }
    if (Info(lock, &info_data) == 0) {
        UnLock(lock);
        ai_puts("Disk information unavailable\n");
        return 5;
    }
    UnLock(lock);

    total = info_data.id_NumBlocks >= 0 ? (ULONG)info_data.id_NumBlocks : 0;
    used = info_data.id_NumBlocksUsed >= 0 ? (ULONG)info_data.id_NumBlocksUsed : 0;
    free_blocks = total >= used ? total - used : 0;
    block_size = info_data.id_BytesPerBlock >= 0 ? (ULONG)info_data.id_BytesPerBlock : 0;

    ai_puts("DiskType 0x");
    put_hex32((ULONG)info_data.id_DiskType);
    ai_puts("\nBlockSize ");
    ai_put_u32(block_size);
    ai_puts("\nTotalBlocks ");
    ai_put_u32(total);
    ai_puts("\nUsedBlocks ");
    ai_put_u32(used);
    ai_puts("\nFreeBlocks ");
    ai_put_u32(free_blocks);
    ai_puts("\nBytesTotal ");
    if (!put_byte_count(total, block_size)) complete = 0;
    ai_puts("\nBytesFree ");
    if (!put_byte_count(free_blocks, block_size)) complete = 0;
    ai_puts("\n");
    return complete ? 0 : 5;
}
