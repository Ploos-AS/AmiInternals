CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000

BUILD_DIR := build
COMMON_OBJS := \
	$(BUILD_DIR)/common/compat.o \
	$(BUILD_DIR)/common/output.o

INFO_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/info/main.o

.PHONY: all clean info check-config

all: info

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 1.2+"

info: $(BUILD_DIR)/Info

$(BUILD_DIR)/Info: $(INFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(INFO_OBJS)

$(BUILD_DIR)/common/%.o: src/common/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/info/%.o: src/info/%.c include/ai_compat.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
