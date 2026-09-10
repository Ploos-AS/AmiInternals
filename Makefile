CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer -noixemul
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000 -noixemul

BUILD_DIR := build
COMMON_OBJS := $(BUILD_DIR)/common/compat.o $(BUILD_DIR)/common/output.o

INFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/info/main.o
MEM_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/mem/main.o
TASKS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/tasks/main.o
LIBS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/libs/main.o
PORTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/ports/main.o
DEVICES_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/devices/main.o
RESOURCES_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/resources/main.o
RESIDENTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/residents/main.o
ASSIGNS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/assigns/main.o
MOUNTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/mounts/main.o
DF_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/df/main.o
DU_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/du/main.o
FIND_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/find/main.o
WHICH_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/which/main.o
TREE_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/tree/main.o
ENV_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/env/main.o
HEAD_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/head/main.o
TAIL_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/tail/main.o
HEX_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/hex/main.o
STRINGS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/strings/main.o
TASKINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/taskinfo/main.o
EXECINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/execinfo/main.o
INTERRUPTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/interrupts/main.o
VECTORS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/vectors/main.o
PATCHES_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/patches/main.o
ALERTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/alerts/main.o
HANDLERS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/handlers/main.o
INPUTINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/inputinfo/main.o
DOCTOR_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/doctor/main.o
SNAPSHOT_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/snapshot/main.o
SNAPDIFF_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/snapdiff/main.o
TIMER_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/timer/main.o
BENCH_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/bench/main.o
WATCHTASK_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/watchtask/main.o
WATCHPORT_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/watchport/main.o
WATCHMEM_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/watchmem/main.o
DISKINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/diskinfo/main.o
BOOTINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/bootinfo/main.o
ROMINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/rominfo/main.o
TRACKINFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/trackinfo/main.o
FLOPPYTEST_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/floppytest/main.o
DISKCHECK_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/diskcheck/main.o
BOOTSAVE_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/bootsave/main.o
BOOTRESTORE_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/bootrestore/main.o

TOOLS := info mem tasks libs ports devices resources residents assigns mounts df du find which tree env head tail hex strings taskinfo execinfo interrupts vectors patches alerts handlers inputinfo doctor snapshot snapdiff timer bench watchtask watchport watchmem diskinfo bootinfo rominfo trackinfo floppytest diskcheck bootsave bootrestore

.PHONY: all clean check-config $(TOOLS)
all: $(TOOLS)

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 1.2+"
	@echo "Runtime qualification for Kickstart 1.2 is still required."

info: $(BUILD_DIR)/Info
mem: $(BUILD_DIR)/Mem
tasks: $(BUILD_DIR)/Tasks
libs: $(BUILD_DIR)/Libs
ports: $(BUILD_DIR)/Ports
devices: $(BUILD_DIR)/Devices
resources: $(BUILD_DIR)/Resources
residents: $(BUILD_DIR)/Residents
assigns: $(BUILD_DIR)/Assigns
mounts: $(BUILD_DIR)/Mounts
df: $(BUILD_DIR)/DF
du: $(BUILD_DIR)/DU
find: $(BUILD_DIR)/Find
which: $(BUILD_DIR)/Which
tree: $(BUILD_DIR)/Tree
env: $(BUILD_DIR)/Env
head: $(BUILD_DIR)/Head
tail: $(BUILD_DIR)/Tail
hex: $(BUILD_DIR)/Hex
strings: $(BUILD_DIR)/Strings
taskinfo: $(BUILD_DIR)/TaskInfo
execinfo: $(BUILD_DIR)/ExecInfo
interrupts: $(BUILD_DIR)/Interrupts
vectors: $(BUILD_DIR)/Vectors
patches: $(BUILD_DIR)/Patches
alerts: $(BUILD_DIR)/Alerts
handlers: $(BUILD_DIR)/Handlers
inputinfo: $(BUILD_DIR)/InputInfo
doctor: $(BUILD_DIR)/Doctor
snapshot: $(BUILD_DIR)/Snapshot
snapdiff: $(BUILD_DIR)/SnapDiff
timer: $(BUILD_DIR)/Timer
bench: $(BUILD_DIR)/Bench
watchtask: $(BUILD_DIR)/WatchTask
watchport: $(BUILD_DIR)/WatchPort
watchmem: $(BUILD_DIR)/WatchMem
diskinfo: $(BUILD_DIR)/DiskInfo
bootinfo: $(BUILD_DIR)/BootInfo
rominfo: $(BUILD_DIR)/ROMInfo
trackinfo: $(BUILD_DIR)/TrackInfo
floppytest: $(BUILD_DIR)/FloppyTest
diskcheck: $(BUILD_DIR)/DiskCheck
bootsave: $(BUILD_DIR)/BootSave
bootrestore: $(BUILD_DIR)/BootRestore

$(BUILD_DIR)/Info: $(INFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Mem: $(MEM_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Tasks: $(TASKS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Libs: $(LIBS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Ports: $(PORTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Devices: $(DEVICES_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Resources: $(RESOURCES_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Residents: $(RESIDENTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Assigns: $(ASSIGNS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Mounts: $(MOUNTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/DF: $(DF_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/DU: $(DU_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Find: $(FIND_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Which: $(WHICH_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Tree: $(TREE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Env: $(ENV_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Head: $(HEAD_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Tail: $(TAIL_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Hex: $(HEX_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Strings: $(STRINGS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/TaskInfo: $(TASKINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/ExecInfo: $(EXECINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Interrupts: $(INTERRUPTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Vectors: $(VECTORS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Patches: $(PATCHES_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Alerts: $(ALERTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Handlers: $(HANDLERS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/InputInfo: $(INPUTINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Doctor: $(DOCTOR_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Snapshot: $(SNAPSHOT_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/SnapDiff: $(SNAPDIFF_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Timer: $(TIMER_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/Bench: $(BENCH_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/WatchTask: $(WATCHTASK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/WatchPort: $(WATCHPORT_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/WatchMem: $(WATCHMEM_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/DiskInfo: $(DISKINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/BootInfo: $(BOOTINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/ROMInfo: $(ROMINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/TrackInfo: $(TRACKINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/FloppyTest: $(FLOPPYTEST_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/DiskCheck: $(DISKCHECK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/BootSave: $(BOOTSAVE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
$(BUILD_DIR)/BootRestore: $(BOOTRESTORE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/common/%.o: src/common/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%/main.o: src/%/main.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
