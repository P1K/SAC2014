AS = /usr/local/bin/nasm
ASFLAGS = -fmacho64
CPPFLAGS += -std=c11 -Ofast -Wall -maes -mpclmul -msse -mssse3

.PHONY: all clean

all: gthingy

gthingy: gthingy.o gm.o
gm.o: gm.s
gthingy.o: gthingy.c gm.h


clean:
	rm *.o
