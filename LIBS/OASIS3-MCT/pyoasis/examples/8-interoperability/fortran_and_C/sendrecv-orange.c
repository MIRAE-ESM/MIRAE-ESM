#include <stdio.h>
#include <math.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sendrecv";
  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout,"Component name: %s = Component ID: %d\n", comp_name, comp_id);
  fflush(stdout);

  MPI_Comm local_comm;
  int comm_size, comm_rank;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&local_comm));
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(local_comm, &comm_size));
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(local_comm, &comm_rank));

  const int n_points = 16;

  /* Parameters for incoming partition */

  int local_lons = (n_points / 2) / comm_size;
  int offsets[2] = {comm_rank * local_lons, comm_rank * local_lons + (n_points / 2)};
  int extents[2] = {local_lons, local_lons};

  /* Parameters for outgoing partition: notice that the boxes extents
     do not sum up to n_points, hence the usually optional global_size
     argument of def_partition is in this case mandatory */

  int global_offsets[4] = {0, 2, 4, 6};
  int extents_x[4] = {0, 2, 0, 2};
  int extents_y[4] = {0, 2, 0, 2};

  /* Use optional argument name of def_partition for the case
     depicted in Oasis user guide as
     mandatory if oasis def partition is called either for a grid
     decomposed not across all the processes of a component or if
     the related oasis def partition are not called in the same
     order on the different component processes */

  int part_in, part_out;
  int n_segments = 2;

  int i, j, k;
  if ( comm_rank % 2 != 0 ) {
    {
      int part_params[OASIS_Orange_Params(n_segments)];
      part_params[OASIS_Strategy] = OASIS_Orange;
      part_params[OASIS_Segments] = n_segments;
      for (i = 0; i<n_segments ; i++) {
	part_params[OASIS_Segments + 2*i + 1] = offsets[i];
	part_params[OASIS_Segments + 2*i + 2] = extents[i];
      }
      OASIS_CHECK_ERR(oasis_c_def_partition(&part_in, OASIS_Orange_Params(n_segments),
					    part_params, OASIS_No_Gsize,
					    "part_in"));
    }

    {
      int part_params[OASIS_Box_Params];
      part_params[OASIS_Strategy] = OASIS_Box;
      part_params[OASIS_Offset]   = global_offsets[comm_rank];
      part_params[OASIS_SizeX]    = extents_x[comm_rank];
      part_params[OASIS_SizeY]    = extents_y[comm_rank];
      part_params[OASIS_LdX]      = (n_points / 2);
      OASIS_CHECK_ERR(oasis_c_def_partition(&part_out, OASIS_Box_Params,
					    part_params, n_points,
					    "part_out"));
    }

  } else {

    {
      int part_params[OASIS_Box_Params];
      part_params[OASIS_Strategy] = OASIS_Box;
      part_params[OASIS_Offset]   = global_offsets[comm_rank];
      part_params[OASIS_SizeX]    = extents_x[comm_rank];
      part_params[OASIS_SizeY]    = extents_y[comm_rank];
      part_params[OASIS_LdX]      = (n_points / 2);
      OASIS_CHECK_ERR(oasis_c_def_partition(&part_out, OASIS_Box_Params,
					    part_params, n_points,
					    "part_out"));
    }

    {
      int part_params[OASIS_Orange_Params(n_segments)];
      part_params[OASIS_Strategy] = OASIS_Orange;
      part_params[OASIS_Segments] = n_segments;
      for (i = 0; i<n_segments ; i++) {
	part_params[OASIS_Segments + 2*i + 1] = offsets[i];
	part_params[OASIS_Segments + 2*i + 2] = extents[i];
      }
      OASIS_CHECK_ERR(oasis_c_def_partition(&part_in, OASIS_Orange_Params(n_segments),
					    part_params, OASIS_No_Gsize,
					    "part_in"));
    }

  }

  if ( comm_rank == 0 ) {
    fprintf(stdout,"%s: part_in  id: %d\n",comp_name, part_in);
    fprintf(stdout,"%s: part_out id: %d\n",comp_name, part_out);
    fflush(stdout);
  }

  int bundle_size;
  int variable;
  bundle_size = 2;
  OASIS_CHECK_ERR(oasis_c_def_var(&variable, "FRECVATM", part_in, bundle_size,
				  OASIS_IN, OASIS_DOUBLE));
  if ( comm_rank == 0 ) {
    fprintf(stdout,"%s: var_name: FRECVATM = var_id: %d\n",comp_name, variable);
    fflush(stdout);
  }

  int var_out;
  bundle_size = 1;
  OASIS_CHECK_ERR(oasis_c_def_var(&var_out, "FSENDATM", part_out, bundle_size,
				  OASIS_OUT, OASIS_REAL));
  if ( comm_rank == 0 ) {
    fprintf(stdout,"%s: var_name: FSENDATM = var_id: %d\n",comp_name, var_out);
    fflush(stdout);
  }

  OASIS_CHECK_ERR(oasis_c_enddef());

  int date=0;
  double bundle[local_lons][2][2];
  for (i=0; i<local_lons; i++) {
    for (j=0; j<2; j++) {
      for (k=0; k<2; k++) {
	bundle[i][j][k] = 0.;
      }
    }
  }

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_get(variable, date, local_lons, 2, 2, OASIS_DOUBLE, OASIS_ROW_MAJOR, bundle, &kinfo));

  double expected_bundle[local_lons][2][2];
  for (k=0; k<2; k++) {
    for (i=0; i<local_lons; i++) {
      for (j=0; j<2; j++) {
	expected_bundle[i][j][k] = (float) (k+1);
      }
    }
  }
  for (i=0; i<local_lons; i++) {
    for (j=0; j<2; j++) {
      for (k=0; k<2; k++) {
	expected_bundle[i][j][k] += (float) ((i + 1 + comm_rank * local_lons) * 100);
      }
    }
  }
  for (j=0; j<2; j++) {
    for (i=0; i<local_lons; i++) {
      for (k=0; k<2; k++) {
	expected_bundle[i][j][k] += (float) ((j + 1) * 10);
      }
    }
  }

  double epsilon = 1.e-8;
  double error = 0.;
  for (i=0; i<local_lons; i++) {
    for (j=0; j<2; j++) {
      for (k=0; k<2; k++) {
	error += fabs(bundle[i][j][k] - expected_bundle[i][j][k]);
      }
    }
  }
  if (error < epsilon) {
    fprintf(stdout, "%s: On rank %d data received successfully\n", comp_name, comm_rank);
    fflush(stdout);
  }

  for (k=0; k<2; k++) {
    char buffout[256];
    sprintf(buffout, "%s: On rank %d Bundle %d is\n[", comp_name, comm_rank, k+1);
    for (i=0; i<local_lons; i++) {
      sprintf(buffout, "%s %.0f.", buffout, bundle[i][0][k]);
    }
    sprintf(buffout, "%s]\n[", buffout);
    for (i=0; i<local_lons; i++) {
      sprintf(buffout, "%s %.0f.", buffout, bundle[i][1][k]);
    }
    fprintf(stdout,"%s]\n",buffout);
    fflush(stdout);
  }

  if ( comm_rank % 2 != 0 ) {
    float field[2][local_lons];
    for (i=0; i<local_lons; i++) {
      for (j=0; j<2; j++) {
	field[j][i] = (float) bundle[i][j][1];
      }
    }

    OASIS_CHECK_ERR(oasis_c_put(var_out, date, local_lons, 2, 1, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));

  }

  OASIS_CHECK_ERR(oasis_c_terminate());

}
