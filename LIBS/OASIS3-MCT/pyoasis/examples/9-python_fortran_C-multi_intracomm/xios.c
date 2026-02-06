#include <stdio.h>
#include <string.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "xios";
  int il_x;

  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  bool coupled = 1;
  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, coupled));
  fprintf(stdout, "Xios: Component ID: %d\n", comp_id);
  fflush(stdout);

  MPI_Comm localcomm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&localcomm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(localcomm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(localcomm, &comm_rank));
  fprintf(stdout,"Xios: rank = %d of %d\n",comm_rank,comm_size);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  char *cnames[3] = {"receiver","xios","sender-box"};
  int  root_ranks[3];

  MPI_Comm intra_comm;
  OASIS_CHECK_ERR(oasis_c_get_multi_intracomm(&intra_comm, 3, cnames, root_ranks));
  int intra_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(intra_comm, &intra_size));
  int intra_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(intra_comm, &intra_rank));
  fprintf(stdout,"Xios rank(%d) intra_comm: rank = %d of %d\n",comm_rank, intra_rank, intra_size);
  fflush(stdout);

  int orig;
  int i;
  if ( comm_rank == 0) {
    fflush(stdout);
    for (i = 0; i<3 ; i++) {
      fprintf(stdout,"Xios: component %s starts at rank %d\n",cnames[i],root_ranks[i]);
      fflush(stdout);
      if ( strcmp(cnames[i], "sender-box") == 0 ) orig = root_ranks[i];
    }
    il_x = 0;
    MPI_Status status;
    OASIS_CHECK_MPI_ERR(MPI_Recv(&il_x, 1, MPI_INT, orig, 0, intra_comm, &status));
    fprintf(stdout,"Xios rank(%d) received il_x = %d\n",comm_rank,il_x);
  }

  il_x = 0;
  if ( comm_rank == 0) il_x = 222;

  int root;
  for (i = 0; i<3 ; i++) {
    if ( strcmp(cnames[i],comp_name) == 0 ) root = root_ranks[i];
  }
  OASIS_CHECK_MPI_ERR(MPI_Bcast(&il_x, 1, MPI_INT, root, intra_comm));
  fprintf(stdout,"Xios rank(%d) got broadcasted il_x = %d\n",comm_rank,il_x);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
