PROGRAMS = timeout correlate.exe date2mjd.exe

INSTALL_DIR = $(SCRIPTUTILS_DIR)/bin/

CC = gcc
CFLAGS = -Wall 
FC = g77
FFLAGS = -O3 -ffixed-line-length-none
LDFLAGS = ${CFLAGS} -lm

CSRCS := timeout.c
DSRCS := date2mjd.c
FSRCS := correlate.f

COBJS = $(patsubst %.c, %.o, $(CSRCS))
DOBJS = $(patsubst %.c, %.o, $(DSRCS))
FOBJS = $(patsubst %.f, %.o, $(FSRCS))


all: $(PROGRAMS)

timeout: $(COBJS)
	$(CC) $(CFLAGS) -o $@ $(COBJS) $(LDFLAGS)

correlate.exe: $(FOBJS)
	$(FC) $(FFLAGS) -o $@ $(FOBJS) $(LDFLAGS)
      
date2mjd.exe: $(DOBJS)
	$(CC) $(CFLAGS) -o $@ $(DOBJS) $(LDFLAGS)

install: $(PROGRAMS)
	-mkdir -p $(INSTALL_DIR)
	mv $(PROGRAMS) $(INSTALL_DIR)

clean:
	rm *.o $(PROGRAMS)
      

