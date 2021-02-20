PREFIX ?= $(HOME)/.local
TARGET ?= lite

OBJ_DIR ?= $(shell pwd)/build
SRC_DIR := $(shell pwd)/src

SRC_EXT := c
OBJ_EXT := o

SRCS := $(shell find $(SRC_DIR) -name *.$(SRC_EXT))

SOURCES := $(foreach sname, $(SRCS), $(abspath $(sname)))
OBJECTS := $(patsubst $(SRC_DIR)/%.$(SRC_EXT), $(OBJ_DIR)/%.$(OBJ_EXT), $(SOURCES))

CC := gcc
CFLAGS ?=
LDLAGS ?=

CFLAGS +=-Wall -O3 -g -std=gnu11 -fno-strict-aliasing -Isrc
LDFLAGS +=-lSDL2 -lm -ldl

UNAME := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
CFLAGS +=-DLUA_USE_POSIX -fPIC -DLUA_COMPAT_ALL
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%$(SRC_EXT)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	-rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

install: all
	@echo Installing to $(PREFIX) ...
	@mkdir -p $(PREFIX)/bin/
	@cp -fp $(TARGET) $(PREFIX)/bin/
	@mkdir -p $(PREFIX)/bin/data
	@echo Copying lua files to $(PREFIX)/bin/data
	@cp -r data/* $(PREFIX)/bin/data/
	@echo Complete.
