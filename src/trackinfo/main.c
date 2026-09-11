#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

static struct InfoData info_data;

int main(int argc, char **argv)
{
    STRPTR path = (STRPTR)"DF0:";
    BPTR lock;
    ULONG blocks;
    ULONG bytes_per_block;
    ULONG sectors = 0;

    ai_puts("TrackInfo 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc > 2) {
        ai_puts("Usage: TrackInfo [volume]\n");
        return 10;
    }
    if (argc == 2) path = (STRPTR)argv[1];

    lock = Lock(path, ACCESS_READ);
    if (lock == 0) {
        ai_puts("Cannot lock volume\n");
        return 5;
    }
    if (Info(lock, &info_data) == 0) {
        UnLock(lock);
        ai_puts("Volume information unavailable\n");
        return 5;
    }
    UnLock(lock);

    if (info_data.id_NumBlocks <= 0 || info_data.id_BytesPerBlock <= 0) {
        ai_puts("Invalid volume geometry data\n");
        return 5;
    }

    blocks = (ULONG)info_data.id_NumBlocks;
    bytes_per_block = (ULONG)info_data.id_BytesPerBlock;

    /* Classic Amiga DD/HD floppy geometry, inferred only for exact known sizes. */
    if (blocks == 1760UL && bytes_per_block == 512UL) sectors = 11;
    else if (blocks == 3520UL && bytes_per_block == 512UL) sectors = 22;

    ai_puts("Blocks "); ai_put_u32(blocks); ai_puts("\n");
    ai_puts("BytesPerBlock "); ai_put_u32(bytes_per_block); ai_puts("\n");
    if (sectors != 0) {
        ai_puts("Cylinders 80\nHeads 2\nSectorsPerTrack ");
        ai_put_u32(sectors);
        ai_puts("\nTracks 160\nGeometry INFERRED\n");
    } else {
        ai_puts("Geometry UNKNOWN\n");
    }
    return 0;
}
