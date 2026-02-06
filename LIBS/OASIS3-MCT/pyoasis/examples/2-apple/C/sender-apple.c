#include <stdio.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-apple";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  OASIS_CHECK_MPI_ERR(MPI_Init(&argc, &argv));

  MPI_Comm commworld;
  OASIS_CHECK_MPI_ERR(MPI_Comm_split(MPI_COMM_WORLD, 1, 0, &commworld));

  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp_with_comm(&comp_id, comp_name, OASIS_COUPLED, commworld));
  fprintf(stdout, "Sender: Component ID: %d\n", comp_id);
  fflush(stdout);

  MPI_Comm localcomm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&localcomm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(localcomm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(localcomm, &comm_rank));
  fprintf(stdout,"Sender: rank = %d of %d\n",comm_rank,comm_size);
  fflush(stdout);

  const int n_points = 16;
  int local_size = n_points/comm_size;
  int offset = comm_rank*local_size;
  if ( comm_rank == comm_size - 1 ) {
    local_size = n_points - offset;
  }


  int part_params[OASIS_Apple_Params];
  part_params[OASIS_Strategy] = OASIS_Apple;
  part_params[OASIS_Offset] = offset;
  part_params[OASIS_Length] = local_size;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Apple_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));
  fprintf(stdout, "Sender rank(%d): part_id: %d\n", comm_rank, part_id);
  fflush(stdout);


  char *var_name  = "FSENDOCN";
  fprintf(stdout, "Sender rank(%d): var_name %s\n", comm_rank, var_name);
  int bundle_size = 1;
  int var_id;

  OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, bundle_size, OASIS_OUT, OASIS_REAL));
  fprintf(stdout, "Sender rank(%d): var_id %d\n", comm_rank, var_id);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  float field[local_size];
  int i;
  for (i = 0; i<local_size; i++) {
    field[i] = (float) offset+i;
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(var_id, date, local_size, 1, bundle_size, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put returned kinfo = %d\n", comm_rank, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

  OASIS_CHECK_MPI_ERR(MPI_Finalize());

}
