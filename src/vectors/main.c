#include <exec/types.h>

#include "ai_compat.h"

#define FIRST_VECTOR 2
#define LAST_VECTOR 15

static const char *vector_name(int vector)
{
    switch (vector) {
        case 2: return "BusError";
        case 3: return "AddressError";
        case 4: return "IllegalInstruction";
        case 5: return "ZeroDivide";
        case 6: return "CHK";
        case 7: return "TRAPV";
        case 8: return "PrivilegeViolation";
        case 9: return "Trace";
        case 10: return "LineA";
        case 11: return "LineF";
        case 12: return "Reserved12";
        case 13: return "CoprocessorProtocol";
        case 14: return "FormatError";
        case 15: return "UninitializedInterrupt";
    }
    return "Unknown";
}

int main(void)
{
    volatile ULONG *vectors = (volatile ULONG *)0;
    ULONG values[LAST_VECTOR - FIRST_VECTOR + 1];
    int vector;
    int index = 0;

    for (vector = FIRST_VECTOR; vector <= LAST_VECTOR; ++vector) {
        values[index++] = vectors[vector];
    }

    ai_puts("Vectors 0.1\nAmiInternals - Ploos AS\n\n");
    ai_puts("Vector Address Name\n");
    index = 0;
    for (vector = FIRST_VECTOR; vector <= LAST_VECTOR; ++vector) {
        ai_put_u32((ULONG)vector);
        ai_puts(" ");
        ai_put_u32(values[index++]);
        ai_puts(" ");
        ai_puts(vector_name(vector));
        ai_puts("\n");
    }

    return 0;
}
