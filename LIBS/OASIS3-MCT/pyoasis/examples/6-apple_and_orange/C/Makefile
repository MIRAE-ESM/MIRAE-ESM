include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver-orange

sender-apple: sender-apple.c
	${CC} sender-apple.c ${CFLAGS} -o sender-apple -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

receiver-orange: receiver-orange.c
	${CC} receiver-orange.c ${CFLAGS} -o receiver-orange -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

clean:
	rm -f sender-apple receiver-orange
	rm -f *~
	rm -fr work
