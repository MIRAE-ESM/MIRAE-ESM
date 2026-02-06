program sender_apple
   use mod_oasis
   implicit none
   integer :: i, lat, kinfo, date
   integer :: comp_id, part_id, var_id
   integer :: n_points = 16
   integer :: part_params(3), offset, local_size
   integer :: local_comm, comm_size, comm_rank
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-apple"
   character(len=8) :: var_name = "FSENDOCN"
   real(kind=8), allocatable, dimension(:,:,:) :: bundle

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)

   if ( comm_rank == 0 ) &
      & print '(3A,I0)', "Component name: ", trim(comp_name), &
      & " = Component ID: ", comp_id

   local_size=n_points/comm_size
   offset=comm_rank*local_size
   if (comm_rank == comm_size - 1) &
      & local_size = n_points - offset

   part_params=[1, offset, local_size]
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)
   if ( comm_rank == 0 ) &
      & print '(2A,I0)', trim(comp_name),": part_id: ", part_id

   var_nodims=[2, 2]

   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_REAL, kinfo)
   if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   if ( comm_rank == 0 ) &
      & print '(4A,I0)', trim(comp_name),": var_name: ", trim(var_name), &
      & " = var_id: ", var_id

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   allocate(bundle(local_size,1,2))
   lat = int(comm_rank/2)+1
   do i = 1, 2
      bundle(:,:,i)=i
   end do
   do i=1, local_size
      bundle(i,:,:)=bundle(i,:,:)+(i+offset-(lat-1)*2*local_size)*100
   end do
   bundle(:,:,:)=bundle(:,:,:)+lat*10

   print '(A,I2,A)', "On sender side rank", comm_rank, ": bundle(1)"
   print '(4F6.0)', bundle(:,:,1)
   print '(A,I2,A)', "On sender side rank", comm_rank, ": bundle(2)"
   print '(4F6.0)', bundle(:,:,2)

   date=0

   call oasis_put(var_id, date, bundle, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   deallocate(bundle)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_apple

