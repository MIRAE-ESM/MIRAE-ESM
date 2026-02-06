#include <stdio.h>
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-box";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
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

  if ( comm_size != 4) {
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name,
				  "Sender: comm_size has to be 4 for this example",
				  __FILE__, __LINE__));
  }

  const int n_points = 16;
  int local_size = n_points/comm_size;
  int offsets[4];
  offsets[0] = 0;
  offsets[1] = 2;
  offsets[2] = 8;
  offsets[3] = 10;

  int part_params[OASIS_Box_Params];
  part_params[OASIS_Strategy] = OASIS_Box;
  part_params[OASIS_Offset]   = offsets[comm_rank];
  part_params[OASIS_SizeX]    = 2;
  part_params[OASIS_SizeY]    = 2;
  part_params[OASIS_LdX]      = 4;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Box_Params,
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

  char *var_name2  = "NOTANAME";
  fprintf(stdout, "Sender rank(%d): var_name %s\n", comm_rank, var_name2);
  int var_id2;
  OASIS_CHECK_ERR(oasis_c_def_var(&var_id2, var_name2, part_id, bundle_size, OASIS_OUT, OASIS_REAL));
  if (var_id2 < 0) {
    fprintf(stdout, "Sender rank(%d): var_id %d is not active\n", comm_rank, var_id2);
  } else {
    fprintf(stdout, "Sender rank(%d): var_id %d\n", comm_rank, var_id2);
  }    
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_enddef());

  MPI_Comm intra_comm;
  OASIS_CHECK_ERR(oasis_c_get_intracomm(&intra_comm, "receiver"));

  int intra_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(intra_comm, &intra_size));
  int intra_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(intra_comm, &intra_rank));
  fprintf(stdout,"Sender intra_comm: rank = %d of %d\n",intra_rank,intra_size);
  fflush(stdout);

  MPI_Comm inter_comm;
  OASIS_CHECK_ERR(oasis_c_get_intercomm(&inter_comm, "receiver"));

  int inter_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(inter_comm, &inter_size));
  int inter_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(inter_comm, &inter_rank));
  int inter_rsize;
  OASIS_CHECK_MPI_ERR(MPI_Comm_remote_size(inter_comm, &inter_rsize));
  fprintf(stdout,"Sender inter_comm: rank = %d of %d Remote size = %d\n",
	  inter_rank,inter_size,inter_rsize);
  fflush(stdout);

  float field[local_size];
  field[0] = offsets[comm_rank]+0;
  field[1] = offsets[comm_rank]+1;
  field[2] = offsets[comm_rank]+4;
  field[3] = offsets[comm_rank]+5;

  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(var_id, date, local_size, 1, bundle_size, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put returned kinfo = %d\n", comm_rank, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
