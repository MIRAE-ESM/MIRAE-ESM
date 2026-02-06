include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-orange receiver

sender-orange: sender-orange.c
	${CC} sender-orange.c ${CFLAGS} -o sender-orange -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

receiver: receiver.c
	${CC} receiver.c ${CFLAGS} -o receiver -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

clean:
	rm -f sender-orange receiver
	rm -f *~
	rm -fr work
