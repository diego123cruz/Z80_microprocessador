# Makefile

CC=gcc
CPP=g++
CFLAGS=-g -Wall
LDFLAGS=

BNSOURCES=bin2ntf.c functions.c
BNOBJECTS=$(addprefix obj/, $(BNSOURCES:.c=.o))
BNSRCS=$(addprefix src/, $(BNSOURCES))

WNSOURCES=wav2ntf.c functions.c
WNOBJECTS=$(addprefix obj/, $(WNSOURCES:.c=.o))
WNSRCS=$(addprefix src/, $(WNSOURCES))

NWSOURCES=ntf2wav.c functions.c
NWOBJECTS=$(addprefix obj/, $(NWSOURCES:.c=.o))
NWSRCS=$(addprefix src/, $(NWSOURCES))

NBSOURCES=ntf2bin.c functions.c
NBOBJECTS=$(addprefix obj/, $(NBSOURCES:.c=.o))
NBSRCS=$(addprefix src/, $(NBSOURCES))

all: bin2ntf wav2ntf ntf2wav ntf2bin

wav2ntf: $(WNOBJECTS)
	$(CC) $(LDFLAGS) $(WNOBJECTS) -o out/$@

ntf2wav: $(NWOBJECTS)
	$(CC) $(LDFLAGS) $(NWOBJECTS) -o out/$@

bin2ntf: $(BNOBJECTS)
	$(CC) $(LDFLAGS) $(BNOBJECTS) -o out/$@

ntf2bin: $(NBOBJECTS)
	$(CC) $(LDFLAGS) $(NBOBJECTS) -o out/$@

obj/%.o : src/%.c
	@mkdir -p obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/%.o : src/%.cpp
	@mkdir -p obj
	$(CPP) $(CFLAGS) -c $< -o $@

clean:
	rm -f out/* *.o obj/*.o core *~

# DO NOT DELETE
