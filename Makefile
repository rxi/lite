PREFIX ?= $(HOME)/.local

OBJ_DIR ?= $(shell pwd)/build
SRC_DIR := $(shell pwd)/src

SRC_EXT := c
OBJ_EXT := o

SRCS := $(shell find $(SRC_DIR) -name *.$(SRC_EXT))

SOURCES := $(foreach sname, $(SRCS), $(abspath $(sname)))
OBJECTS := $(patsubst $(SRC_DIR)/%.$(SRC_EXT), $(OBJ_DIR)/%.$(OBJ_EXT), $(SOURCES))

CFLAGS ?=
LDLAGS ?=

CFLAGS +=-Wall -O3 -g -std=gnu11 -fno-strict-aliasing -Isrc
LDFLAGS +=-lSDL2 -lm -ldl

ifeq ($(OS),Windows_NT)
  TARGET ?= lite.exe
  CC := x86_64-w64-mingw32-gcc
  CFLAGS += -DLUA_USE_POPEN -Iwinlib/SDL2-2.0.10/x86_64-w64-mingw32/include
  LDFLAGS += -Lwinlib/SDL2-2.0.10/x86_64-w64-mingw32/lib -lmingw32 -lSDL2main -mwindows res.res
	x86_64-w64-mingw32-windres res.rc -O coff -o res.res
else
  TARGET ?= lite
  CC := gcc
  UNAME := $(shell uname -s)
  ifeq ($(UNAME_S),Linux)
    CFLAGS +=-DLUA_USE_POSIX -fPIC -DLUA_COMPAT_ALL
  endif
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
