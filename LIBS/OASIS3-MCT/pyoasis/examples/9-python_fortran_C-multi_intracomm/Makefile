include ../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: receiver xios nonactive

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

xios: xios.c
	${CC} xios.c ${CFLAGS} -o xios -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

nonactive: nonactive.F90
	${F90} nonactive.F90 ${FLAGS} -o nonactive -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f receiver xios nonactive
	rm -f *~
	rm -fr work
