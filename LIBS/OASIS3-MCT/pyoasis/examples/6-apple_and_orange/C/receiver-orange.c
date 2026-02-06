#include <stdio.h>
#include <math.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "receiver";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Receiver: Component ID: %d\n", comp_id);
  fflush(stdout);

  MPI_Comm local_comm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&local_comm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(local_comm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(local_comm, &comm_rank));
  fprintf(stdout,"Receiver: local_comm_rank = %d of %d\n",comm_rank,comm_size);
  fflush(stdout);

  const int n_points = 16;
  if ( ( n_points % comm_size ) != 0 ) {
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name,
				  "Receiver: comm_size has to divide n_points exactly",
				  __FILE__, __LINE__));
  }

  int  local_size = n_points/comm_size;
  int  offset = comm_rank*local_size;

  int n_segments = 1;
  int part_id;
  int i;
  {
    int part_params[OASIS_Orange_Params(n_segments)];
    part_params[OASIS_Strategy] = OASIS_Orange;
    part_params[OASIS_Segments] = n_segments;
    for (i = 0; i<n_segments ; i++) {
      part_params[OASIS_Segments + 2*i + 1] = offset;
      part_params[OASIS_Segments + 2*i + 2] = local_size;
    }
    OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Orange_Params(n_segments),
					  part_params, OASIS_No_Gsize,
					  OASIS_No_Name));
    fprintf(stdout, "Receiver rank(%d): part_id: %d\n", comm_rank, part_id);
    fflush(stdout);
  }

  char *var_name  = "FRECVATM";
  fprintf(stdout, "Receiver rank(%d): var_name %s\n", comm_rank, var_name);
  int bundle_size = 1;
  int var_id;

  OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, bundle_size, OASIS_IN, OASIS_REAL));
  fprintf(stdout, "Receiver rank(%d): var_id %d\n", comm_rank, var_id);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  float field[local_size];
  for (i = 0; i<local_size; i++) {
    field[i] = 0.;
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_get(var_id, date, local_size, 1, bundle_size, OASIS_REAL, OASIS_COL_MAJOR, field, &kinfo));
  fprintf(stdout, "Receiver rank(%d): oasis_c_get returned kinfo = %d\n", comm_rank, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

  float epsilon = 1.e-8;
  float error = 0.;

  for (i = 0; i<local_size; i++) {
    error += fabs(field[i] - (float) (i+offset));
  }
  if (error < epsilon) {
    fprintf(stdout, "Receiver rank(%d): Data received successfully\n", comm_rank);
    fflush(stdout);
  } else {
    fprintf(stdout, "Receiver rank(%d): Got first four elements\n",comm_rank);
    for (i = 0; i<4 ; i++ ) {
      fprintf(stdout, "[rank %d] Element %d contains %f instead of %f\n",
	      comm_rank, i, field[i], (float) i);
    }
    fflush(stdout);
  }
}
