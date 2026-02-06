include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver non_oasis

sender-apple: sender-apple.F90
	${F90} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

non_oasis: non_oasis.F90
	${F90} non_oasis.F90 ${FLAGS} -o non_oasis

clean:
	rm -f sender-apple receiver non_oasis
	rm -f *~
	rm -fr work
