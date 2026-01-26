# SPDX-License-Identifier: GPL-2.0

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra
TARGET = mem_load

all: $(TARGET)

$(TARGET): mem_load.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET) mem_load.c

clean:
	rm -f $(TARGET)

install:
	install -d $(DESTDIR)$(bindir)
	install -m 0755 $(TARGET) $(DESTDIR)$(bindir)/

.PHONY: all clean install
