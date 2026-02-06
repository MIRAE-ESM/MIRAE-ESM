include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-serial receiver_one receiver_two

sender-serial: sender-serial.c
	${CC} sender-serial.c ${CFLAGS} -o sender-serial -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

receiver_one: receiver_one.c
	${CC} receiver_one.c ${CFLAGS} -o receiver_one -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

receiver_two: receiver_two.c
	${CC} receiver_two.c ${CFLAGS} -o receiver_two -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

clean:
	rm -f sender-serial receiver_one receiver_two
	rm -f *~
	rm -fr work
