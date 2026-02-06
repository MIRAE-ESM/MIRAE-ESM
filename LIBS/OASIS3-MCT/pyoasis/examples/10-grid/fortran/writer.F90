program writer
   use mod_oasis
   use netcdf
   implicit none


   integer :: i, j, kinfo
   integer :: comp_id, part_id
   integer :: part_params(5)
   character(len=13) :: comp_name = "writer"
   integer :: local_comm, comm_size, comm_rank
   integer :: nx_loc = 18, ny_loc = 18
   integer :: nx_global, ny_global
   integer :: ncrn = 4
   real(kind=8), allocatable :: lon(:,:), lat(:,:)
   integer, allocatable :: imsk(:,:)
   real(kind=8), allocatable :: frac(:,:), area(:,:), angle(:,:)
   real(kind=8), allocatable :: clo(:,:,:), cla(:,:,:)
   real(kind=8) :: dx, dy
   real(kind=8) :: dp_conv

   integer :: ncid, varid, status
   real(kind=8), parameter :: epsilon = 1.e-4
   real(kind=8) :: dist

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Writer: rank = ",comm_rank, " of ",comm_size

   nx_global = comm_size*nx_loc
   ny_global = ny_loc
   part_params=[2, comm_rank*nx_loc, nx_loc, ny_loc, nx_global]
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   call oasis_start_grids_writing(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_start_grids_writing: ", rcode=kinfo)

   dx = 360.0/nx_global
   dy = 180.0/ny_global

   allocate(lon(nx_loc,ny_loc))
   allocate(lat(nx_loc,ny_loc))
   do j = 1, ny_loc
      lon(:,j) = [(-180.0 + comm_rank*nx_loc*dx + real(i)*dx - dx/2, i=1,nx_loc)]
   end do
   do i = 1, nx_loc
      lat(i,:) = [(-90.0 + real(j)*dy - dy/2, j=1,ny_loc)]
   end do
   call oasis_write_grid('pyoa', nx_global, ny_global, lon, lat, part_id)

   allocate(clo(nx_loc,ny_loc,ncrn))
   allocate(cla(nx_loc,ny_loc,ncrn))
   do j = 1, ny_loc
      clo(:,j,1) = [(-180.0 + comm_rank*nx_loc*dx + real(i-1)*dx, i=1,nx_loc)]
      clo(:,j,2) = [(-180.0 + comm_rank*nx_loc*dx + real(i)*dx, i=1,nx_loc)]
      clo(:,j,3) = clo(:,j,2)
      clo(:,j,4) = clo(:,j,1)
   end do
   do i = 1, nx_loc
      cla(i,:,1) = [(-90.0 + real(j-1)*dy, j=1,ny_loc)]
      cla(i,:,2) = cla(i,:,1)
      cla(i,:,3) = [(-90.0 + real(j)*dy, j=1,ny_loc)]
      cla(i,:,4) = cla(i,:,3)
   end do
   call oasis_write_corner('pyoa', nx_global, ny_global, ncrn, clo, cla, part_id)

   allocate(imsk(nx_loc,ny_loc))
   imsk(:,:) = 0
   select case(comm_rank)
   case(0)
      imsk(5:6,3:16) = 1
      imsk(7:11,[9,10,15,16]) = 1
      imsk(12,[9,10,11,14,15,16]) = 1
      imsk(13,10:15) = 1
      imsk(14,11:14) = 1
   case(1)
      imsk([4,15],15:16) = 1
      imsk([5,14],13:16) = 1
      imsk([6,13],12:15) = 1
      imsk([7,12],11:13) = 1
      imsk([8,11],10:12) = 1
      imsk(9:10,3:11) = 1
   case(2)
      imsk([5,14],5:14) = 1
      imsk([6,13],4:15) = 1
      imsk([7,12],3:5) = 1
      imsk([7,12],14:16) = 1
      imsk(8:11,3:4) = 1
      imsk(8:11,15:16) = 1
   end select
   call oasis_write_mask('pyoa', nx_global, ny_global, imsk, part_id, companion='STFC')

   allocate(frac(nx_loc,ny_loc))
   frac(:,:) = 1.
   where(imsk == 1) frac = 0.
   call oasis_write_frac('pyoa', nx_global, ny_global, frac, part_id, companion='STFC')

   allocate(area(nx_loc,ny_loc))
   dp_conv = ATAN(1.)/45.
   area(:,:) = dp_conv * abs(sin(cla(:,:,3)*dp_conv)-sin(cla(:,:,1)*dp_conv)) * &
      & abs(clo(:,:,2)-clo(:,:,1))
   call oasis_write_area('pyoa', nx_global, ny_global, area, part_id)

   allocate(angle(nx_loc,ny_loc))
   angle(:,:) = 0.
   call oasis_write_angle('pyoa', nx_global, ny_global, angle, part_id)

   deallocate(lon, lat)
   deallocate(clo, cla)
   deallocate(imsk)
   deallocate(frac, area, angle)

   if ( comm_rank == 0 ) then
      nx_global = 180
      ny_global = 90

      dx = 360.0/nx_global
      dy = 180.0/ny_global

      allocate(lon(nx_global,ny_global))
      allocate(lat(nx_global,ny_global))
      do j = 1, ny_global
         lon(:,j) = [(real(i)*dx - dx/2, i=1,nx_global)]
      end do
      do i = 1, nx_global
         lat(i,:) = [(-90.0 + real(j)*dy - dy/2, j=1,ny_global)]
      end do
      call oasis_write_grid('mono', nx_global, ny_global, lon, lat)

      allocate(clo(nx_global,ny_global,ncrn))
      allocate(cla(nx_global,ny_global,ncrn))
      do j = 1, ny_global
         clo(:,j,1) = [(real(i-1)*dx, i=1,nx_global)]
         clo(:,j,2) = [(real(i)*dx, i=1,nx_global)]
         clo(:,j,3) = clo(:,j,2)
         clo(:,j,4) = clo(:,j,1)
      end do
      do i = 1, nx_global
         cla(i,:,1) = [(-90.0 + real(j-1)*dy, j=1,ny_global)]
         cla(i,:,2) = cla(i,:,1)
         cla(i,:,3) = [(-90.0 + real(j)*dy, j=1,ny_global)]
         cla(i,:,4) = cla(i,:,3)
      end do
      call oasis_write_corner('mono', nx_global, ny_global, ncrn, clo, cla)

      allocate(imsk(nx_global,ny_global))
      imsk(:,:) = 0
      where((lon-180)*(lon-180)+lat*lat < 900.) imsk = 1
      call oasis_write_mask('mono', nx_global, ny_global, imsk)

      allocate(frac(nx_global,ny_global))
      frac(:,:) = 1.
      where(imsk == 1) frac = 0.
      call oasis_write_frac('mono', nx_global, ny_global, frac)

      allocate(area(nx_global,ny_global))
      dp_conv = atan(1.)/45.
      area(:,:) = dp_conv * abs(sin(cla(:,:,3)*dp_conv)-sin(cla(:,:,1)*dp_conv)) * &
         & abs(clo(:,:,2)-clo(:,:,1))
      call oasis_write_area('mono', nx_global, ny_global, area)

      allocate(angle(nx_global,ny_global))
      angle(:,:) = 0.
      call oasis_write_angle('mono', nx_global, ny_global, angle)

      deallocate(lon, lat)
      deallocate(clo, cla)
      deallocate(imsk)
      deallocate(frac, area, angle)
   end if

   call oasis_terminate_grids_writing()

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   if ( comm_rank == 0 ) then

      ! Open grids.nc check for min and max of lat and lon
      status = nf90_open(path = "grids.nc", mode = nf90_nowrite, ncid = ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in opening grids.nc", rcode=-1)
      allocate(lon(comm_size*nx_loc,ny_loc))
      allocate(lat(comm_size*nx_loc,ny_loc))
      status = nf90_inq_varid(ncid, "pyoa.lat", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.lat id", rcode=-1)
      status = nf90_get_var(ncid, varid, lat)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.lat values", rcode=-1)
      if (.not. maxval(lat) <= 90.) call oasis_abort(comp_id, comp_name, &
         & "Error in pyoa.lat max value", rcode=-1)
      if (.not. minval(lat) >= -90.) call oasis_abort(comp_id, comp_name, &
         & "Error in pyoa.lat min value", rcode=-1)
      status = nf90_inq_varid(ncid, "pyoa.lon", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.lon id", rcode=-1)
      status = nf90_get_var(ncid, varid, lon)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.lon values", rcode=-1)
      if (.not. maxval(lon) <= 180.) call oasis_abort(comp_id, comp_name, &
         & "Error in pyoa.lon max value", rcode=-1)
      if (.not. minval(lon) >= -180.) call oasis_abort(comp_id, comp_name, &
         & "Error in pyoa.lon min value", rcode=-1)
      deallocate(lon)
      deallocate(lat)

      allocate(lon(nx_global,ny_global))
      allocate(lat(nx_global,ny_global))
      status = nf90_inq_varid(ncid, "mono.lat", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.lat id", rcode=-1)
      status = nf90_get_var(ncid, varid, lat)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.lat values", rcode=-1)
      if (.not. maxval(lat) <= 90.) call oasis_abort(comp_id, comp_name, &
         & "Error in mono.lat max value", rcode=-1)
      if (.not. minval(lat) >= -90.) call oasis_abort(comp_id, comp_name, &
         & "Error in mono.lat min value", rcode=-1)
      status = nf90_inq_varid(ncid, "mono.lon", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.lon id", rcode=-1)
      status = nf90_get_var(ncid, varid, lon)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.lon values", rcode=-1)
      if (.not. maxval(lon) <= 360.) call oasis_abort(comp_id, comp_name, &
         & "Error in mono.lon max value", rcode=-1)
      if (.not. minval(lon) >= 0.) call oasis_abort(comp_id, comp_name, &
         & "Error in mono.lon min value", rcode=-1)
      deallocate(lon)
      deallocate(lat)
      status = nf90_close(ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in closing grids.nc", rcode=-1)

      ! Open masks.nc and check for the hole in mono.msk
      status = nf90_open(path = "masks.nc", mode = nf90_nowrite, ncid = ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in opening masks.nc", rcode=-1)
      allocate(imsk(nx_global,ny_global))
      imsk(:,:) = 0
      status = nf90_inq_varid(ncid, "mono.msk", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.msk id", rcode=-1)
      status = nf90_get_var(ncid, varid, imsk)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting mono.msk values", rcode=-1)
      do j = 1, ny_global
         do i = 1, nx_global
            dist = sqrt(dble((i-1)-nx_global/2)**2 + &
               &        dble((j-1)-ny_global/2)**2)
            if ( dist < 14 ) then
               if (imsk(i,j) /= 1)  call oasis_abort(comp_id, comp_name, &
                  & "Error in mono.msk values", rcode=-1)
            elseif ( dist > 16 ) then
               if (imsk(i,j) /= 0)  call oasis_abort(comp_id, comp_name, &
                  & "Error in mono.msk values", rcode=-1)
            end if
         end do
      end do

      status = nf90_close(ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in closing masks.nc", rcode=-1)

      ! Open areas.nc and check for the area on the sphere
      status = nf90_open(path = "areas.nc", mode = nf90_nowrite, ncid = ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in opening areas.nc", rcode=-1)
      allocate(area(comm_size*nx_loc,ny_loc))
      area(:,:) = 0.
      status = nf90_inq_varid(ncid, "pyoa.srf", varid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.srf id", rcode=-1)
      status = nf90_get_var(ncid, varid, area)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in getting pyoa.srf values", rcode=-1)

      dp_conv = atan(1.)/45.
      do j = 1, ny_loc
         do i = 1, comm_size*nx_loc
            if ((abs(area(i,j) - dp_conv * &
               & abs(sin((-90.+real(j)  *180./ny_loc)*dp_conv) - &
               &     sin((-90.+real(j-1)*180./ny_loc)*dp_conv)) &
               & * abs(360./(comm_size*nx_loc)))) > epsilon) then
               call oasis_abort(comp_id, comp_name, &
                  & "Error in pyoa.srf values", rcode=-1)
            end if
         end do
      end do

      status = nf90_close(ncid)
      if (status /= nf90_noerr) call oasis_abort(comp_id, comp_name, &
         & "Error in closing areas.nc", rcode=-1)

      ! Write out the successfully message if everything went well
      print '(A)', "Writer:  successfully ended writing grids"

   end if

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)


end program writer
