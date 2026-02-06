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

  const int n_points = 1600;
  int part_params[OASIS_Serial_Params];
  part_params[OASIS_Strategy] = OASIS_Serial;
  part_params[OASIS_Length] = n_points;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));
  fprintf(stdout, "Sender: part_id: %d\n", part_id);
  fflush(stdout);

  char *var_name  = "FSENDOCN";
  fprintf(stdout, "Sender: var_name %s\n", var_name);
  int bundle_size = 1;
  int var_id;

  OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, bundle_size, OASIS_OUT, OASIS_REAL));
  fprintf(stdout, "Sender: var_id %d\n", var_id);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  float field[n_points];
  int i;
  for (i = 0; i<n_points; i++) {
    field[i] = (float) i;
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(var_id, date, n_points, 1, bundle_size, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender: oasis_c_put returned kinfo = %d\n", kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
