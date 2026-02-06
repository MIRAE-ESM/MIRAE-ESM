#include <stdio.h>
#include <math.h>
#include "mpi.h"
#include "netcdf.h"
#include "oasis_c.h"

double maxval(int m, int n, double a[m][n]) {
  int c, d;
  double maximum = a[0][0];

  for (c = 0; c < m; c++)
    for (d = 0; d < n; d++)
      if (a[c][d] > maximum)
        maximum = a[c][d];
  return maximum;
}

double minval(int m, int n, double a[m][n]) {
  int c, d;
  double minimum = a[0][0];

  for (c = 0; c < m; c++)
    for (d = 0; d < n; d++)
      if (a[c][d] < minimum)
        minimum = a[c][d];
  return minimum;
}

int main(int argc, char *argv[])
{
  char *comp_name = "writer";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);
  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));

  MPI_Comm localcomm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&localcomm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(localcomm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(localcomm, &comm_rank));
  fprintf(stdout,"Writer: rank = %d of %d\n",comm_rank,comm_size);
  fflush(stdout);

  const int nx_loc = 18;
  const int ny_loc = 18;
  const int n_crn  =  4;
  int nx_global, ny_global;
  double dx,dy;
  int i, j;
  const double dp_conv = atan(1.)/45.0;

  int part_params[OASIS_Box_Params];
  part_params[OASIS_Strategy] = OASIS_Box;
  part_params[OASIS_Offset]   = comm_rank * nx_loc;
  part_params[OASIS_SizeX]    = nx_loc;
  part_params[OASIS_SizeY]    = ny_loc;
  part_params[OASIS_LdX]      = comm_size * nx_loc;
  int part_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Box_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));

  OASIS_CHECK_ERR(oasis_c_start_grids_writing());

  {
    /* pyoa */
    nx_global = comm_size * nx_loc;
    ny_global = ny_loc;
    dx = 360.0/(double) nx_global;
    dy = 180.0/(double) ny_global;

    double lon[ny_loc][nx_loc];
    double lat[ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) {
      for ( j = 0; j<ny_loc; j++) {
	lon[j][i] = -180.0 + comm_rank*nx_loc*dx + (double) i * dx + dx/2. ;
	lat[j][i] = -90.0 + (double) j * dy + dy/2.;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_grid("pyoa", nx_global, ny_global,
				       nx_loc, ny_loc, &lon[0][0], &lat[0][0], part_id));

    double clo[n_crn][ny_loc][nx_loc];
    double cla[n_crn][ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) {
      for ( j = 0; j<ny_loc; j++) {
	clo[3][j][i] = clo[0][j][i] = -180.0 + comm_rank*nx_loc*dx + (double) i * dx;
	clo[2][j][i] = clo[1][j][i] = -180.0 + comm_rank*nx_loc*dx + (double) (i+1) * dx;
	cla[1][j][i] = cla[0][j][i] = -90.0 + (double) j * dy;
	cla[3][j][i] = cla[2][j][i] = -90.0 + (double) (j+1) * dy;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_corner("pyoa", nx_global, ny_global, n_crn,
				         nx_loc, ny_loc, &clo[0][0][0], &cla[0][0][0], part_id));

    int imsk[ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) {
      for ( j = 0; j<ny_loc; j++) {
	imsk[j][i] = 0;
      }
    }
    switch (comm_rank) {
    case 0:
      for (i = 4; i<6; i++) for (j = 2; j<16; j++) imsk[j][i] = 1;
      for (i = 6; i<11; i++) imsk[15][i] = imsk[14][i] = imsk[9][i] = imsk[8][i] = 1;
      imsk[15][11] = imsk[14][11] = imsk[13][11] = imsk[10][11] = imsk[9][11] = imsk[8][11] = 1;
      for (j = 9; j<15; j++) imsk[j][12] = 1;
      for (j = 10; j<14; j++) imsk[j][13] = 1;
      break;
    case 1:
      for (j = 14; j<16; j++) imsk[j][3] = imsk[j][14] = 1;
      for (j = 12; j<16; j++) imsk[j][4] = imsk[j][13] = 1;
      for (j = 11; j<15; j++) imsk[j][5] = imsk[j][12] = 1;
      for (j = 10; j<13; j++) imsk[j][6] = imsk[j][11] = 1;
      for (j =  9; j<12; j++) imsk[j][7] = imsk[j][10] = 1;
      for (i =  8; i<10; i++) for (j = 2; j<11; j++) imsk[j][i] = 1;
      break;
    case 2:
      for (j =  4; j<14; j++) imsk[j][4] = imsk[j][13] = 1;
      for (j =  3; j<15; j++) imsk[j][5] = imsk[j][12] = 1;
      for (j =  2; j< 5; j++) imsk[j][6] = imsk[j][11] = 1;
      for (j = 13; j<16; j++) imsk[j][6] = imsk[j][11] = 1;
      for (i =  7; i<11; i++) for (j = 2; j<4; j++) imsk[j][i] = 1;
      for (i =  7; i<11; i++) for (j = 14; j<16; j++) imsk[j][i] = 1;
      break;
    }
    OASIS_CHECK_ERR(oasis_c_write_mask("pyoa", nx_global, ny_global,
				       nx_loc, ny_loc, &imsk[0][0], part_id, "STFC"));

    double frac[ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) {
      for ( j = 0; j<ny_loc; j++) {
	frac[j][i] = 1.0;
	if (imsk[j][i] == 1) frac[j][i] = 0.;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_frac("pyoa", nx_global, ny_global,
				       nx_loc, ny_loc, &frac[0][0], part_id, "STFC"));

    double area[ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) {
      for ( j = 0; j<ny_loc; j++) {
	area[j][i] = dp_conv * fabs(sin(cla[2][j][i]*dp_conv)-sin(cla[0][j][i]*dp_conv)) *
	  fabs(clo[1][j][i]-clo[0][j][i]);
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_area("pyoa", nx_global, ny_global,
				       nx_loc, ny_loc, &area[0][0], part_id));

    double angle[ny_loc][nx_loc];
    for ( i = 0; i<nx_loc; i++) for ( j = 0; j<ny_loc; j++) angle[j][i] = 0.;
    OASIS_CHECK_ERR(oasis_c_write_angle("pyoa", nx_global, ny_global,
					nx_loc, ny_loc, &angle[0][0], part_id));

  }

  {
    /* mono */
    nx_global = 180;
    ny_global = 90;
    dx = 360.0/(double) nx_global;
    dy = 180.0/(double) ny_global;

    double lon[ny_global][nx_global];
    double lat[ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) {
      for ( j = 0; j<ny_global; j++) {
	lon[j][i] = (double) i * dx + dx/2. ;
	lat[j][i] = -90.0 + (double) j * dy + dy/2.;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_grid("mono", nx_global, ny_global,
				       nx_global, ny_global, &lon[0][0], &lat[0][0],
				       OASIS_No_Part));

    double clo[n_crn][ny_global][nx_global];
    double cla[n_crn][ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) {
      for ( j = 0; j<ny_global; j++) {
	clo[3][j][i] = clo[0][j][i] = (double) i * dx;
	clo[2][j][i] = clo[1][j][i] = (double) (i+1) * dx;
	cla[1][j][i] = cla[0][j][i] = -90.0 + (double) j * dy;
	cla[3][j][i] = cla[2][j][i] = -90.0 + (double) (j+1) * dy;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_corner("mono", nx_global, ny_global, n_crn,
				         nx_global, ny_global, &clo[0][0][0], &cla[0][0][0],
					 OASIS_No_Part));

    int imsk[ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) {
      for ( j = 0; j<ny_global; j++) {
	imsk[j][i] = 0;
	if ((lon[j][i]-180.)*(lon[j][i]-180.)+(lat[j][i]*lat[j][i]) < 900.) imsk[j][i] = 1;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_mask("mono", nx_global, ny_global,
				       nx_global, ny_global, &imsk[0][0], OASIS_No_Part,
				       OASIS_No_Companion));
    double frac[ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) {
      for ( j = 0; j<ny_global; j++) {
	frac[j][i] = 1.0;
	if (imsk[j][i] == 1) frac[j][i] = 0.;
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_frac("mono", nx_global, ny_global,
				       nx_global, ny_global, &frac[0][0], OASIS_No_Part,
				       OASIS_No_Companion));

    double area[ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) {
      for ( j = 0; j<ny_global; j++) {
	area[j][i] = dp_conv * fabs(sin(cla[2][j][i]*dp_conv)-sin(cla[0][j][i]*dp_conv)) *
	  fabs(clo[1][j][i]-clo[0][j][i]);
      }
    }
    OASIS_CHECK_ERR(oasis_c_write_area("mono", nx_global, ny_global,
				       nx_global, ny_global, &area[0][0], OASIS_No_Part));

    double angle[ny_global][nx_global];
    for ( i = 0; i<nx_global; i++) for ( j = 0; j<ny_global; j++) angle[j][i] = 0.;
    OASIS_CHECK_ERR(oasis_c_write_angle("mono", nx_global, ny_global,
					nx_global, ny_global, &angle[0][0], OASIS_No_Part));
  }

  OASIS_CHECK_ERR(oasis_c_terminate_grids_writing());

  OASIS_CHECK_ERR(oasis_c_enddef());

  if ( comm_rank == 0 ) {
    int status;
    int ncid, varid;
    nx_global = 180;
    ny_global = 90;


    /* Open grids.nc check for min and max of lat and lon */
    if (nc_open("grids.nc", 0, &ncid) != NC_NOERR)
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in opening grids.nc",
				    __FILE__, __LINE__));

    {
      double lon[ny_loc][comm_size*nx_loc];
      double lat[ny_loc][comm_size*nx_loc];
      if (nc_inq_varid(ncid, "pyoa.lat", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.lat id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &lat[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.lat values",__FILE__, __LINE__));
      if (maxval(ny_loc,comm_size*nx_loc,lat) > 90.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in pyoa.lat max value",__FILE__, __LINE__));
      if (minval(ny_loc,comm_size*nx_loc,lat) < -90.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in pyoa.lat min value",__FILE__, __LINE__));
      if (nc_inq_varid(ncid, "pyoa.lon", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.lat id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &lon[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.lat values",__FILE__, __LINE__));
      if (maxval(ny_loc,comm_size*nx_loc,lon) > 180.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in pyoa.lon max value",__FILE__, __LINE__));
      if (minval(ny_loc,comm_size*nx_loc,lon) < -180.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in pyoa.lon min value",__FILE__, __LINE__));

    }
    {
      double lon[ny_global][nx_global];
      double lat[ny_global][nx_global];
      if (nc_inq_varid(ncid, "mono.lat", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.lat id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &lat[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.lat values",__FILE__, __LINE__));
      if (maxval(ny_global,nx_global,lat) > 90.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.lat max value",__FILE__, __LINE__));
      if (minval(ny_global,nx_global,lat) < -90.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.lat min value",__FILE__, __LINE__));
      if (nc_inq_varid(ncid, "mono.lon", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.lat id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &lon[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.lat values",__FILE__, __LINE__));
      if (maxval(ny_global,nx_global,lon) > 360.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.lon max value",__FILE__, __LINE__));
      if (minval(ny_global,nx_global,lon) < 0.0)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.lon min value",__FILE__, __LINE__));

    }
    if (nc_close(ncid))
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in closing grids.nc",__FILE__, __LINE__));

    /* Open masks.nc and check for the hole in mono.msk */
    if (nc_open("masks.nc", 0, &ncid) != NC_NOERR)
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in opening masks.nc",__FILE__, __LINE__));

    {
      int imsk[ny_global][nx_global];
      for ( i = 0; i<nx_global; i++) for ( j = 0; j<ny_global; j++) imsk[j][i] = 0;
      if (nc_inq_varid(ncid, "mono.msk", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.msk id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &imsk[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting mono.msk values",__FILE__, __LINE__));
      double dist;
      for ( i = 0; i<nx_global; i++)
	for ( j = 0; j<ny_global; j++) {
	  dist = sqrt(pow((double)(i - nx_global/2),2.0) + pow((double) (j - ny_global/2),2.0));
	  if ( dist < 14.0 ) {
	    if ( imsk[j][i] != 1 )
	      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.msk value",__FILE__, __LINE__));
	  } else if ( dist > 16.0 ) {
	    if ( imsk[j][i] != 0 )
	      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in mono.msk value",__FILE__, __LINE__));
	  }
	}
    }
    if (nc_close(ncid))
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in closing masks.nc",__FILE__, __LINE__));

    /* Open areas.nc and check for the area on the sphere */
    if (nc_open("areas.nc", 0, &ncid) != NC_NOERR)
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in opening areas.nc",__FILE__, __LINE__));

    {
      double area[ny_loc][comm_size*nx_loc];
      for ( i = 0; i<comm_size*nx_loc; i++) for ( j = 0; j<ny_loc; j++) area[j][i] = 0.0;
      if (nc_inq_varid(ncid, "pyoa.srf", &varid) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.srf id",__FILE__, __LINE__));
      if (nc_get_var(ncid, varid, &area[0][0]) != NC_NOERR)
	OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in getting pyoa.srf values",__FILE__, __LINE__));

      const double epsilon = 1.e-6;
      for ( i = 0; i<comm_size*nx_loc; i++)
	for ( j = 0; j<ny_loc; j++) {
	  if (fabs(area[j][i] - dp_conv *
		   fabs(sin((-90.+(double)(j+1) * 180./ny_loc)*dp_conv)-
			sin((-90.+(double)(j)   * 180./ny_loc)*dp_conv)) *
		   fabs(360./(double)(comm_size*nx_loc))) > epsilon)
	    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in pyoa.srf value",__FILE__, __LINE__));
	}
    }
    if (nc_close(ncid))
      OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Writer: Error in closing areas.nc",__FILE__, __LINE__));

    /* Write out the successfully message if everything went well */
    fprintf(stdout,"Writer: successfully ended writing grids\n");
    fflush(stdout);
  }

  OASIS_CHECK_ERR(oasis_c_terminate());

}
