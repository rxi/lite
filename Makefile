PREFIX ?= /usr/local
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

CFLAGS +=-Wall -O3 -g -std=gnu11 -fno-strict-aliasing -Isrc -fPIC -DLUA_COMPAT_ALL
LDFLAGS +=-lSDL2 -lm

UNAME := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
CFLAGS +=-DLUA_USE_POSIX
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%$(SRC_EXT)
	mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	-rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

install: all
	@echo Installing to $(DESTDIR)$(PREFIX) ...
	@mkdir -p $(DESTDIR)$(PREFIX)/bin/
	@cp -fp $(TARGET) $(DESTDIR)$(PREFIX)/bin/
	@echo Complete.
