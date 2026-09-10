#include <exec/libraries.h>
#include <exec/ports.h>
#include <proto/exec.h>
#include <proto/rexxsyslib.h>
#include <rexx/rxslib.h>
#include <rexx/storage.h>

#include "ai_compat.h"

struct RxsLib *RexxSysBase;
static struct MsgPort reply_port;
static struct RexxMsg *rxmsg;

static ULONG text_len(const char *s)
{
    ULONG n = 0;
    while (s[n] != '\0') ++n;
    return n;
}

static int setup_reply_port(void)
{
    BYTE sig = AllocSignal(-1);
    if (sig == -1) return 0;

    reply_port.mp_Node.ln_Type = NT_MSGPORT;
    reply_port.mp_Flags = PA_SIGNAL;
    reply_port.mp_SigBit = (UBYTE)sig;
    reply_port.mp_SigTask = FindTask(0);
    reply_port.mp_MsgList.lh_Head = (struct Node *)&reply_port.mp_MsgList.lh_Tail;
    reply_port.mp_MsgList.lh_Tail = 0;
    reply_port.mp_MsgList.lh_TailPred = (struct Node *)&reply_port.mp_MsgList.lh_Head;
    return 1;
}

static void free_reply_port(void)
{
    FreeSignal((BYTE)reply_port.mp_SigBit);
}

int main(int argc, char **argv)
{
    struct MsgPort *target;
    struct RexxMsg *reply;
    LONG rc;

    ai_puts("RexxSend 0.1\nAmiInternals - Ploos AS\n\n");
    if (argc != 3) {
        ai_puts("Usage: RexxSend port-name command\n");
        return 10;
    }

    RexxSysBase = (struct RxsLib *)OpenLibrary((STRPTR)"rexxsyslib.library", 0);
    if (RexxSysBase == 0) {
        ai_puts("ARexx unavailable: rexxsyslib.library not present\n");
        return 5;
    }
    if (!setup_reply_port()) {
        CloseLibrary((struct Library *)RexxSysBase);
        ai_puts("Cannot allocate reply signal\n");
        return 5;
    }

    rxmsg = CreateRexxMsg(&reply_port, (STRPTR)"rexx", (STRPTR)"AMIINTERNALS");
    if (rxmsg == 0) {
        free_reply_port();
        CloseLibrary((struct Library *)RexxSysBase);
        ai_puts("Cannot create RexxMsg\n");
        return 5;
    }
    rxmsg->rm_Action = RXCOMM;
    rxmsg->rm_Args[0] = CreateArgstring((STRPTR)argv[2], text_len(argv[2]));
    if (rxmsg->rm_Args[0] == 0) {
        DeleteRexxMsg(rxmsg);
        free_reply_port();
        CloseLibrary((struct Library *)RexxSysBase);
        ai_puts("Cannot create command argstring\n");
        return 5;
    }

    Forbid();
    target = FindPort((STRPTR)argv[1]);
    if (target != 0) PutMsg(target, (struct Message *)rxmsg);
    Permit();
    if (target == 0) {
        DeleteArgstring(rxmsg->rm_Args[0]);
        DeleteRexxMsg(rxmsg);
        free_reply_port();
        CloseLibrary((struct Library *)RexxSysBase);
        ai_puts("Target port not found\n");
        return 5;
    }

    WaitPort(&reply_port);
    reply = (struct RexxMsg *)GetMsg(&reply_port);
    if (reply == 0) {
        free_reply_port();
        CloseLibrary((struct Library *)RexxSysBase);
        ai_puts("No ARexx reply received\n");
        return 5;
    }

    rc = reply->rm_Result1;
    ai_puts("RC ");
    ai_put_s32(rc);
    ai_puts("\n");
    if (reply->rm_Result2 != 0) {
        ai_puts("Result ");
        ai_puts((const char *)reply->rm_Result2);
        ai_puts("\n");
    }

    DeleteArgstring(reply->rm_Args[0]);
    DeleteRexxMsg(reply);
    free_reply_port();
    CloseLibrary((struct Library *)RexxSysBase);
    return rc == 0 ? 0 : 5;
}
