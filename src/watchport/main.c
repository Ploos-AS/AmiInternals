#include <exec/execbase.h>
#include <exec/lists.h>
#include <proto/exec.h>
#include <proto/dos.h>

#include "ai_compat.h"

#define DEFAULT_SAMPLES 5
#define MAX_SAMPLES 100
#define MAX_PORT_VISITS 1024

#define PORT_ABSENT 0
#define PORT_PRESENT 1
#define PORT_UNKNOWN 2

static int same_name(const char *a, const char *b)
{
    if (a == 0 || b == 0) return 0;
    while (*a != '\0' && *b != '\0') {
        if (*a != *b) return 0;
        ++a;
        ++b;
    }
    return *a == '\0' && *b == '\0';
}

static LONG parse_samples(const char *s)
{
    LONG value = 0;
    if (s == 0 || *s == '\0') return -1;
    while (*s != '\0') {
        if (*s < '0' || *s > '9') return -1;
        value = value * 10 + (*s - '0');
        if (value > MAX_SAMPLES) return -1;
        ++s;
    }
    return value > 0 ? value : -1;
}

static int port_state(struct ExecBase *sysbase, const char *name)
{
    struct Node *node;
    ULONG visits = 0;
    int state = PORT_ABSENT;

    Forbid();
    for (node = sysbase->PortList.lh_Head;
         node != 0 && node->ln_Succ != 0 && visits < MAX_PORT_VISITS;
         node = node->ln_Succ) {
        ++visits;
        if (same_name(node->ln_Name, name)) {
            state = PORT_PRESENT;
            break;
        }
    }
    if (state == PORT_ABSENT && node != 0 && node->ln_Succ != 0) {
        state = PORT_UNKNOWN;
    }
    Permit();
    return state;
}

int main(int argc, char **argv)
{
    struct ExecBase *sysbase = *(struct ExecBase **)4;
    LONG samples = DEFAULT_SAMPLES;
    LONG i;
    LONG seen = 0;
    LONG unknown = 0;

    ai_puts("WatchPort 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc < 2 || argc > 3) {
        ai_puts("Usage: WatchPort port [samples]\n");
        return 10;
    }
    if (argc == 3) {
        samples = parse_samples(argv[2]);
        if (samples < 1) {
            ai_puts("Invalid sample count (1-100)\n");
            return 10;
        }
    }
    if (sysbase == 0) {
        ai_puts("ERROR SysBase unavailable\n");
        return 5;
    }

    ai_puts("Sample State\n");
    for (i = 0; i < samples; ++i) {
        int state = port_state(sysbase, argv[1]);
        ai_put_u32((ULONG)(i + 1));
        ai_puts(" ");
        if (state == PORT_PRESENT) {
            ai_puts("PRESENT\n");
            ++seen;
        } else if (state == PORT_UNKNOWN) {
            ai_puts("UNKNOWN\n");
            ++unknown;
        } else {
            ai_puts("ABSENT\n");
        }
        if (i + 1 < samples) Delay(1);
    }

    ai_puts("Seen ");
    ai_put_u32((ULONG)seen);
    ai_puts("/");
    ai_put_u32((ULONG)samples);
    ai_puts("\n");
    if (unknown > 0) {
        ai_puts("Warning: port list traversal limit reached\n");
    }
    return seen > 0 ? 0 : 5;
}
