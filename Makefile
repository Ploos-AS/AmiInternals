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

.PHONY: all clean info mem tasks check-config

all: info mem tasks

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 1.2+"
	@echo "Runtime qualification for Kickstart 1.2 is still required."

info: $(BUILD_DIR)/Info
mem: $(BUILD_DIR)/Mem
tasks: $(BUILD_DIR)/Tasks

$(BUILD_DIR)/Info: $(INFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(INFO_OBJS)

$(BUILD_DIR)/Mem: $(MEM_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(MEM_OBJS)

$(BUILD_DIR)/Tasks: $(TASKS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(TASKS_OBJS)

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

clean:
	rm -rf $(BUILD_DIR)
