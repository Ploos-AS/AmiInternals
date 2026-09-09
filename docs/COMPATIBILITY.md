# Compatibility contract

## Minimum platform

AmiInternals targets a Motorola 68000 system running Kickstart / AmigaOS 1.2 as the minimum supported environment. This requirement applies to the core suite and shared runtime code.

## Forward compatibility

The same binaries should continue to operate on later classic AmigaOS versions whenever practical. Code must not infer structure layouts merely from what happens to work on one release.

Where an operation needs a newer library version:

1. inspect the library version at runtime;
2. expose the extra information only when supported;
3. keep the remainder of the utility usable;
4. document the version dependency.

## Dependencies

Core utilities must not require an FPU, ixemul, MUI, ReAction, GadTools, bsdsocket.library, a hard disk, or ARexx. ARexx-specific tools may naturally require RexxMast/ARexx at runtime.

## Safety

Inspection commands are read-only by default. Tools that intentionally change machine state must be separately named, explicit, and designed so accidental invocation cannot silently modify media.

## Compatibility-sensitive code

Direct traversal of Exec/DOS lists and private structures must be isolated in shared compatibility code. Each such implementation must state the oldest structure/API version it relies upon.
