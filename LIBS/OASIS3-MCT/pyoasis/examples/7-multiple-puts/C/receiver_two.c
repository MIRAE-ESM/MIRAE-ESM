#include <stdio.h>
#include <math.h>
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "receiver_two";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Recv_two: Component ID: %d\n", comp_id);
  fflush(stdout);

  const int n_points = 1;
  int part_params[OASIS_Serial_Params];
  part_params[OASIS_Strategy] = OASIS_Serial;
  part_params[OASIS_Length] = n_points;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));
  fprintf(stdout, "Recv_two: part_id: %d\n", part_id);
  fflush(stdout);

  char *var_name[2]  = {"FRECVICE_1","FRECVICE_2"};
  int bundle_size = 1;
  int var_id[2];

  int i;
  for (i = 0; i<2; i++) {
    fprintf(stdout, "Recv_two: var_name %s\n", var_name[i]);
    OASIS_CHECK_ERR(oasis_c_def_var(&var_id[i], var_name[i], part_id, bundle_size,
				    OASIS_IN, OASIS_REAL));
    fprintf(stdout, "Recv_two: var_id %d\n", var_id[i]);
    fflush(stdout);
  }

  OASIS_CHECK_ERR(oasis_c_enddef());

  MPI_Comm inter_two;
  int inter_size, inter_rank;
  OASIS_CHECK_ERR(oasis_c_get_intercomm(&inter_two, "sender-serial"));
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(inter_two, &inter_size));
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(inter_two, &inter_rank));
  fprintf(stdout,"Recv_two inter_two: rank = %d of %d\n",inter_rank,inter_size);
  fflush(stdout);

  int ncpl;
  OASIS_CHECK_ERR(oasis_c_get_ncpl(var_id[0], &ncpl));
  int cpl_freqs_0[ncpl];
  OASIS_CHECK_ERR(oasis_c_get_freqs(var_id[0], OASIS_IN, ncpl, cpl_freqs_0));

  OASIS_CHECK_ERR(oasis_c_get_ncpl(var_id[1], &ncpl));
  int cpl_freqs_1[ncpl];
  OASIS_CHECK_ERR(oasis_c_get_freqs(var_id[1], OASIS_IN, ncpl, cpl_freqs_1));

  float field[n_points];
  bool do_send;
  float epsilon = 1.e-8;
  float error;
  int kinfo;

  int date;
  for (date = 0; date < 43200; date++) {

    do_send = 0;
    for (i = 0; i < ncpl ; i++ ) do_send = do_send || (date % cpl_freqs_0[i]) == 0;
    if ( do_send ) {
      for (i = 0; i < n_points; i++ ) field[i] = 0.0;
      OASIS_CHECK_ERR(oasis_c_get(var_id[0], date, n_points, 1, bundle_size,
				  OASIS_REAL, OASIS_COL_MAJOR, field, &kinfo));
      error = 0.;
      for (i = 0; i < n_points; i++ ) error += fabs(field[i] - (float) date);
      if (error < epsilon) {
	fprintf(stdout, "Recv_two: field 1 received successfully at time %d\n", date);
      } else {
	fprintf(stdout, "Warning: Recv_two at time %d got %.0f instead of %.0f\n",
		date, field[0], (float) date);
      }
      fflush(stdout);
    }

    do_send = 0;
    for (i = 0; i < ncpl ; i++ ) do_send = do_send || (date % cpl_freqs_1[i]) == 0;
    if ( do_send ) {
      for (i = 0; i < n_points; i++ ) field[i] = 0.0;
      OASIS_CHECK_ERR(oasis_c_get(var_id[1], date, n_points, 1, bundle_size,
				  OASIS_REAL, OASIS_COL_MAJOR, field, &kinfo));
      error = 0.;
      for (i = 0; i < n_points; i++ ) error += fabs(field[i] + (float) date);
      if (error < epsilon) {
	fprintf(stdout, "Recv_two: field 2 received successfully at time %d\n", date);
      } else {
	fprintf(stdout, "Warning: Recv_two at time %d got %.0f instead of %.0f\n",
		date, field[0], -1.0 * (float) date);
      }
      fflush(stdout);

    }

  }

  OASIS_CHECK_ERR(oasis_c_terminate());

}
