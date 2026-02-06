include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver-serial

sender-apple: sender-apple.F90
	${F90} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver-serial: receiver-serial.F90
	${F90} receiver-serial.F90 ${FLAGS} -o receiver-serial -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f sender-apple receiver-serial
	rm -f *~
	rm -fr work
