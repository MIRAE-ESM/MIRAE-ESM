include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-orange receiver

sender-orange: sender-orange.F90
	${F90} sender-orange.F90 ${FLAGS} -o sender-orange -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f sender-orange receiver
