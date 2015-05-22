AS = /usr/local/bin/nasm
ASFLAGS = -fmacho64
CPPFLAGS += -std=c11 -Ofast -Wall -maes -mpclmul -msse -mssse3

.PHONY: all clean

all: perf43_8

perf43_8: perf43_8.o r43_8.o
r43_8.o: r43_8.s
perf43_8.o: perf43_8.c r43_8.h

clean:
	rm *.o
