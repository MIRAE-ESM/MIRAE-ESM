include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: writer

writer: writer.c
	${CC} writer.c ${CFLAGS} -o writer -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

clean:
	rm -f writer
	rm -f *~
	rm -fr work
