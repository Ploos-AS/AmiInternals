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

TOOLS := info mem tasks libs ports devices resources residents assigns mounts df du find which tree env head tail hex strings taskinfo execinfo interrupts vectors patches alerts

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

$(BUILD_DIR)/common/%.o: src/common/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%/main.o: src/%/main.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
