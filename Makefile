CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer -noixemul
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000 -noixemul

BUILD_DIR := build
COMMON_OBJS := \
	$(BUILD_DIR)/common/compat.o \
	$(BUILD_DIR)/common/output.o

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

.PHONY: all clean info mem tasks libs ports devices resources residents assigns mounts df du find which tree env head tail hex strings check-config

all: info mem tasks libs ports devices resources residents assigns mounts df du find which tree env head tail hex strings

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

$(BUILD_DIR)/Info: $(INFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(INFO_OBJS)
$(BUILD_DIR)/Mem: $(MEM_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(MEM_OBJS)
$(BUILD_DIR)/Tasks: $(TASKS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(TASKS_OBJS)
$(BUILD_DIR)/Libs: $(LIBS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(LIBS_OBJS)
$(BUILD_DIR)/Ports: $(PORTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(PORTS_OBJS)
$(BUILD_DIR)/Devices: $(DEVICES_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(DEVICES_OBJS)
$(BUILD_DIR)/Resources: $(RESOURCES_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(RESOURCES_OBJS)
$(BUILD_DIR)/Residents: $(RESIDENTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(RESIDENTS_OBJS)
$(BUILD_DIR)/Assigns: $(ASSIGNS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(ASSIGNS_OBJS)
$(BUILD_DIR)/Mounts: $(MOUNTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(MOUNTS_OBJS)
$(BUILD_DIR)/DF: $(DF_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(DF_OBJS)
$(BUILD_DIR)/DU: $(DU_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(DU_OBJS)
$(BUILD_DIR)/Find: $(FIND_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(FIND_OBJS)
$(BUILD_DIR)/Which: $(WHICH_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(WHICH_OBJS)
$(BUILD_DIR)/Tree: $(TREE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(TREE_OBJS)
$(BUILD_DIR)/Env: $(ENV_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(ENV_OBJS)
$(BUILD_DIR)/Head: $(HEAD_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(HEAD_OBJS)
$(BUILD_DIR)/Tail: $(TAIL_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(TAIL_OBJS)
$(BUILD_DIR)/Hex: $(HEX_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(HEX_OBJS)
$(BUILD_DIR)/Strings: $(STRINGS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(STRINGS_OBJS)

$(BUILD_DIR)/common/%.o: src/common/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/info/%.o: src/info/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/mem/%.o: src/mem/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/tasks/%.o: src/tasks/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/libs/%.o: src/libs/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/ports/%.o: src/ports/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/devices/%.o: src/devices/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/resources/%.o: src/resources/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/residents/%.o: src/residents/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/assigns/%.o: src/assigns/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/mounts/%.o: src/mounts/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/df/%.o: src/df/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/du/%.o: src/du/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/find/%.o: src/find/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/which/%.o: src/which/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/tree/%.o: src/tree/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/env/%.o: src/env/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/head/%.o: src/head/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/tail/%.o: src/tail/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/hex/%.o: src/hex/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/strings/%.o: src/strings/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
