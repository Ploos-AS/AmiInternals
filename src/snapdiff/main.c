#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define READ_SIZE 256

static UBYTE left_buf[READ_SIZE];
static UBYTE right_buf[READ_SIZE];

int main(int argc, char **argv)
{
    BPTR left;
    BPTR right;
    LONG left_got;
    LONG right_got;
    ULONG offset = 0;
    ULONG first_diff = 0;
    ULONG differing = 0;
    int have_diff = 0;

    ai_puts("SnapDiff 0.1\nAmiInternals - Ploos AS\n\n");

    if (argc != 3) {
        ai_puts("Usage: SnapDiff snapshot1 snapshot2\n");
        return 10;
    }

    left = Open((STRPTR)argv[1], MODE_OLDFILE);
    if (!left) {
        ai_puts("Cannot open first snapshot\n");
        return 5;
    }

    right = Open((STRPTR)argv[2], MODE_OLDFILE);
    if (!right) {
        Close(left);
        ai_puts("Cannot open second snapshot\n");
        return 5;
    }

    for (;;) {
        LONG i;
        LONG common;
        LONG longest;

        left_got = Read(left, left_buf, READ_SIZE);
        right_got = Read(right, right_buf, READ_SIZE);
        if (left_got < 0 || right_got < 0) {
            Close(right);
            Close(left);
            ai_puts("Read error\n");
            return 5;
        }

        if (left_got == 0 && right_got == 0) {
            break;
        }

        common = left_got < right_got ? left_got : right_got;
        for (i = 0; i < common; ++i) {
            if (left_buf[i] != right_buf[i]) {
                if (!have_diff) {
                    first_diff = offset + (ULONG)i;
                    have_diff = 1;
                }
                ++differing;
            }
        }

        if (left_got != right_got) {
            ULONG extra = (ULONG)(left_got > right_got ? left_got - right_got : right_got - left_got);
            if (!have_diff) {
                first_diff = offset + (ULONG)common;
                have_diff = 1;
            }
            differing += extra;
        }

        longest = left_got > right_got ? left_got : right_got;
        offset += (ULONG)longest;
    }

    Close(right);
    Close(left);

    if (!have_diff) {
        ai_puts("Result=IDENTICAL\nBytesCompared=");
        ai_put_u32(offset);
        ai_puts("\n");
        return 0;
    }

    ai_puts("Result=DIFFERENT\nFirstDifference=");
    ai_put_u32(first_diff);
    ai_puts("\nDifferingBytes=");
    ai_put_u32(differing);
    ai_puts("\nBytesCompared=");
    ai_put_u32(offset);
    ai_puts("\n");
    return 5;
}
