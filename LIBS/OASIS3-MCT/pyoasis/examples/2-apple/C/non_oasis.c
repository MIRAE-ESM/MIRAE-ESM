#include <stdio.h>
#include "mpi.h"

int main(int argc, char *argv[])
{
  fprintf(stdout,"Extra process not in OASIS commworld\n");
  fflush(stdout);

  int mpierr;
  mpierr = MPI_Init(&argc, &argv);
  
  MPI_Comm nullcomm;
  mpierr = MPI_Comm_split(MPI_COMM_WORLD, MPI_UNDEFINED, 0, &nullcomm);

  mpierr = MPI_Finalize();
}
