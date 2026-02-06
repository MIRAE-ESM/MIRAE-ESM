#include <stdio.h>
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-serial";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Sender: Component ID: %d\n", comp_id);
  fflush(stdout);

  const int n_points = 1;
  int part_params[OASIS_Serial_Params];
  part_params[OASIS_Strategy] = OASIS_Serial;
  part_params[OASIS_Length] = n_points;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));
  fprintf(stdout, "Sender: part_id: %d\n", part_id);
  fflush(stdout);

  char *var_name[2]  = {"FSENDOCN_1","FSENDOCN_2"};
  int bundle_size = 1;
  int var_id[2];

  int i;
  for (i = 0; i<2; i++) {
    fprintf(stdout, "Sender: var_name %s\n", var_name[i]);
    OASIS_CHECK_ERR(oasis_c_def_var(&var_id[i], var_name[i], part_id, bundle_size, OASIS_OUT, OASIS_REAL));
    fprintf(stdout, "Sender: var_id %d\n", var_id[i]);
    fflush(stdout);
  }

  OASIS_CHECK_ERR(oasis_c_enddef());

  MPI_Comm intra_one;
  int intra_size, intra_rank;
  OASIS_CHECK_ERR(oasis_c_get_intracomm(&intra_one, "receiver_one"));
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(intra_one, &intra_size));
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(intra_one, &intra_rank));
  fprintf(stdout,"Sender intra_one: rank = %d of %d\n",intra_rank,intra_size);
  fflush(stdout);

  MPI_Comm inter_two;
  int inter_size, inter_rank;
  OASIS_CHECK_ERR(oasis_c_get_intercomm(&inter_two, "receiver_two"));
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(inter_two, &inter_size));
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(inter_two, &inter_rank));
  fprintf(stdout,"Sender inter_two: rank = %d of %d\n",inter_rank,inter_size);
  fflush(stdout);

  int ncpl;
  OASIS_CHECK_ERR(oasis_c_get_ncpl(var_id[1], &ncpl));
  int cpl_freqs[ncpl];
  OASIS_CHECK_ERR(oasis_c_get_freqs(var_id[1], OASIS_OUT, ncpl, cpl_freqs));

  char outbuff[256];
  sprintf(outbuff,"Sender: coupling frequencies for %s are",var_name[1]);
  for (i = 0; i<ncpl; i++) sprintf(outbuff,"%s %d",outbuff, cpl_freqs[i]);
  fprintf(stdout,"%s\n",outbuff);
  fflush(stdout);

  float field[n_points];
  int date;
  for (date = 0; date < 43200; date++) {

    int kinfo;
    OASIS_CHECK_ERR(oasis_c_put_inquire(var_id[1], date, &kinfo));

    if ( kinfo == OASIS_Sent ) {
      for (i = 0; i < n_points; i++ ) field[i] = (float) date;
      OASIS_CHECK_ERR(oasis_c_put(var_id[0], date, n_points, 1, bundle_size,
				  OASIS_REAL, OASIS_COL_MAJOR, field,
				  OASIS_No_Restart, &kinfo));
    }

    bool do_send = 0;
    for (i = 0; i < ncpl ; i++ ) do_send = do_send || (date % cpl_freqs[i]) == 0;
    if ( do_send ) {
      OASIS_CHECK_ERR(oasis_c_set_debug(2));
      for (i = 0; i < n_points; i++ ) field[i] = -1.0 * (float) date;
      bool ll_rst = date % 10800 == 0;
      OASIS_CHECK_ERR(oasis_c_put(var_id[1], date, n_points, 1, bundle_size,
				  OASIS_REAL, OASIS_COL_MAJOR, field,
				  ll_rst, &kinfo));
      OASIS_CHECK_ERR(oasis_c_set_debug(0));
    }

  }

  OASIS_CHECK_ERR(oasis_c_terminate());

}
