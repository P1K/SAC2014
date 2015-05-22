MTPATH = ......../SFMT-src-1.4

vpath %.c = $(MTPATH)
vpath %.h = $(MTPATH)

CPPFLAGS += -std=c11 -Ofast -Wall -msse -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mavx
CPPFLAGS += -I$(MTPATH)
LDFLAGS  += -lm4ri -lm4rie

.PHONY: all clean

all: brutal_random

brutal_random: brutal_random.o SFMT.o
brutal_random.o: CPPFLAGS += -DSFMT_MEXP=607
brutal_random.o: CPPFLAGS += -DLOGOMANY=23
brutal_random.o: brutal_random.c SFMT.h

SFMT.o: CPPFLAGS += -DSFMT_MEXP=607
SFMT.o: SFMT.c SFMT.h

clean:
	rm *.o
