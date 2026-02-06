#include <stdio.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-apple";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Sender: Component ID: %d\n", comp_id);
  fflush(stdout);

  MPI_Comm local_comm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&local_comm));
  int local_comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(local_comm, &local_comm_size));
  int local_comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(local_comm, &local_comm_rank));
  fprintf(stdout,"Sender: local_comm_rank = %d of %d\n",local_comm_rank,local_comm_size);
  fflush(stdout);

  int icpl = 1;
  if (local_comm_size > 3) {
      if (local_comm_rank >= local_comm_size - 2) icpl = 0;
  }

  MPI_Comm coupl_comm;
  OASIS_CHECK_MPI_ERR(MPI_Comm_split(local_comm, icpl, local_comm_rank, &coupl_comm));

  if ( icpl == 0 ) coupl_comm = MPI_COMM_NULL;

  OASIS_CHECK_ERR(oasis_c_set_couplcomm(coupl_comm));

  const int n_points = 16;
  int comm_rank;
  int local_size;
  int offset;
  int part_id;
  int bundle_size = 1;
  int var_id;

  if ( icpl == 1 ) {
    int comm_size;
    OASIS_CHECK_MPI_ERR(MPI_Comm_size(coupl_comm, &comm_size));
    OASIS_CHECK_MPI_ERR(MPI_Comm_rank(coupl_comm, &comm_rank));
    fprintf(stdout,"Sender: comm_rank = %d of %d\n",comm_rank,comm_size);
    fflush(stdout);

    if ( ( n_points % comm_size ) != 0 ) {
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name,
				    "Sender: comm_size has to divide n_points exactly",
				    __FILE__, __LINE__));
    }

    local_size = n_points/comm_size;
    offset = comm_rank*local_size;

    int part_params[OASIS_Apple_Params];
    part_params[OASIS_Strategy] = OASIS_Apple;
    part_params[OASIS_Offset] = offset;
    part_params[OASIS_Length] = local_size;

    OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Apple_Params,
					  part_params, OASIS_No_Gsize,
					  OASIS_No_Name));
    fprintf(stdout, "Sender rank(%d): part_id: %d\n", comm_rank, part_id);
    fflush(stdout);

    char *var_name  = "FSENDOCN";
    fprintf(stdout, "Sender rank(%d): var_name %s\n", comm_rank, var_name);

    OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, bundle_size, OASIS_OUT, OASIS_REAL));
    fprintf(stdout, "Sender rank(%d): var_id %d\n", comm_rank, var_id);
    fflush(stdout);
  }

  OASIS_CHECK_ERR(oasis_c_enddef());

  if ( icpl == 1 ) {
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
  }

  OASIS_CHECK_ERR(oasis_c_terminate());

}
