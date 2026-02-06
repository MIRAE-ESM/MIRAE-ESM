#include <stdio.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-points";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Sender: Component ID: %d\n", comp_id);
  fflush(stdout);

  MPI_Comm local_comm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&local_comm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(local_comm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(local_comm, &comm_rank));
  fprintf(stdout,"Sender: rank = %d of %d\n",comm_rank,comm_size);
  fflush(stdout);

  if ( comm_size != 4) {
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name,
				  "Sender: comm_size has to be 4 for this example",
				  __FILE__, __LINE__));
  }

  const int n_points = 16;
  int local_size = n_points/comm_size;
  int offset = comm_rank*local_size;
  int part_id;
  int i;
  {
    int part_params[OASIS_Points_Params(local_size)];
    part_params[OASIS_Strategy] = OASIS_Points;
    part_params[OASIS_Npoints]  = local_size;
    for (i = 0; i<local_size ; i++) {
      part_params[OASIS_Npoints + i + 1] = i + offset;
    }
    OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Points_Params(local_size),
					  part_params, OASIS_No_Gsize,
					  OASIS_No_Name));
    fprintf(stdout, "Sender rank(%d): part_id: %d\n", comm_rank, part_id);
    fflush(stdout);
  }

  char *var_name  = "FSENDOCN";
  fprintf(stdout, "Sender rank(%d): var_name %s\n", comm_rank, var_name);
  int bundle_size = 1;
  int var_id;

  OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, bundle_size, OASIS_OUT, OASIS_REAL));
  fprintf(stdout, "Sender rank(%d): var_id %d\n", comm_rank, var_id);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  float field[local_size];
  for (i = 0; i<local_size; i++) {
    field[i] = i + offset;
  }

  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(var_id, date, local_size, 1, bundle_size, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put returned kinfo = %d\n", comm_rank, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
