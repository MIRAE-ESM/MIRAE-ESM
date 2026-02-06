include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-serial receiver_one receiver_two

sender-serial: sender-serial.F90
	${F90} sender-serial.F90 ${FLAGS} -o sender-serial -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver_one: receiver_one.F90
	${F90} receiver_one.F90 ${FLAGS} -o receiver_one -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver_two: receiver_two.F90
	${F90} receiver_two.F90 ${FLAGS} -o receiver_two -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f sender-serial receiver_one receiver_two
