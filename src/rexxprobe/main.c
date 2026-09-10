#include <exec/ports.h>
#include <proto/exec.h>

#include "ai_compat.h"

int main(int argc, char **argv)
{
    struct MsgPort *port;

    ai_puts("RexxProbe 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc != 2) {
        ai_puts("Usage: RexxProbe port-name\n");
        return 10;
    }

    Forbid();
    port = FindPort((STRPTR)argv[1]);
    Permit();

    ai_puts("Port ");
    ai_puts(argv[1]);
    ai_puts(port != 0 ? " PRESENT\n" : " ABSENT\n");
    ai_puts("Note: presence proves only a public Exec MsgPort, not ARexx capability.\n");
    return port != 0 ? 0 : 5;
}
