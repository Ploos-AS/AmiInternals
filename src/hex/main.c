#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define LINE_BYTES 16
#define MAX_SEEK_OFFSET 0x7fffffffUL
#define SEEK_ADDRESS_SPACE 0x80000000UL

static UBYTE data[LINE_BYTES];
static char line[80];
static const char digits[] = "0123456789ABCDEF";

static void put_hex8(char *p, UBYTE value)
{
    p[0] = digits[(value >> 4) & 15];
    p[1] = digits[value & 15];
}

static void put_hex32(char *p, ULONG value)
{
    int i;
    for (i = 7; i >= 0; --i) {
        p[i] = digits[value & 15];
        value >>= 4;
    }
}

static LONG parse_u32(const char *s, ULONG *value)
{
    ULONG v = 0;
    int base = 10;
    int digit;
    if (!s || !*s) return 0;
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        base = 16;
        s += 2;
        if (!*s) return 0;
    }
    while (*s) {
        if (*s >= '0' && *s <= '9') digit = *s - '0';
        else if (base == 16 && *s >= 'a' && *s <= 'f') digit = *s - 'a' + 10;
        else if (base == 16 && *s >= 'A' && *s <= 'F') digit = *s - 'A' + 10;
        else return 0;
        if (digit >= base) return 0;
        if (v > (0xffffffffUL - (ULONG)digit) / (ULONG)base) return 0;
        v = v * (ULONG)base + (ULONG)digit;
        ++s;
    }
    *value = v;
    return 1;
}

static void emit_line(ULONG offset, LONG count)
{
    LONG i;
    LONG p = 0;
    put_hex32(line + p, offset); p += 8;
    line[p++] = ' '; line[p++] = ' ';
    for (i = 0; i < LINE_BYTES; ++i) {
        if (i < count) put_hex8(line + p, data[i]);
        else { line[p] = ' '; line[p + 1] = ' '; }
        p += 2;
        line[p++] = ' ';
    }
    line[p++] = ' ';
    for (i = 0; i < count; ++i) {
        UBYTE c = data[i];
        line[p++] = (c >= 32 && c <= 126) ? (char)c : '.';
    }
    line[p++] = '\n';
    Write(Output(), line, p);
}

int main(int argc, char **argv)
{
    BPTR fh;
    ULONG offset = 0;
    ULONG limit = 0;
    ULONG shown = 0;
    ULONG address_left;
    LONG got = 0;

    ai_puts("Hex 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 4) {
        ai_puts("Usage: Hex file [offset] [length]\n");
        return 10;
    }
    if (argc >= 3 && !parse_u32(argv[2], &offset)) {
        ai_puts("Invalid offset\n");
        return 10;
    }
    if (offset > MAX_SEEK_OFFSET) {
        ai_puts("Offset outside AmigaDOS seek range\n");
        return 10;
    }
    if (argc == 4 && !parse_u32(argv[3], &limit)) {
        ai_puts("Invalid length\n");
        return 10;
    }

    address_left = SEEK_ADDRESS_SPACE - offset;
    if (argc == 4 && limit > address_left) {
        ai_puts("Requested range outside AmigaDOS seek range\n");
        return 10;
    }

    fh = Open((STRPTR)argv[1], MODE_OLDFILE);
    if (!fh) {
        ai_puts("Cannot open file\n");
        return 5;
    }
    if (offset && Seek(fh, (LONG)offset, OFFSET_BEGINNING) < 0) {
        Close(fh);
        ai_puts("Cannot seek file\n");
        return 5;
    }

    for (;;) {
        LONG want = LINE_BYTES;
        ULONG position_left = address_left - shown;

        if (position_left == 0) break;
        if (position_left < LINE_BYTES) want = (LONG)position_left;

        if (argc == 4) {
            ULONG left;
            if (shown >= limit) break;
            left = limit - shown;
            if (left < (ULONG)want) want = (LONG)left;
        }
        got = Read(fh, data, want);
        if (got <= 0) break;
        emit_line(offset + shown, got);
        shown += (ULONG)got;
    }

    Close(fh);
    return got < 0 ? 5 : 0;
}
