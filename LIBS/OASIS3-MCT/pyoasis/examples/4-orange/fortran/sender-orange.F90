program sender_orange
   use mod_oasis
   use mpi
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id
   integer :: n_points = 16
   integer :: offset, local_size, n_segments
   integer, allocatable, dimension(:) :: part_params
   integer :: local_comm, local_comm_size, local_comm_rank
   integer :: icpl, coupl_comm, comm_size, comm_rank
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-orange"
   character(len=8) :: var_name = "FSENDOCN"
   real, allocatable :: field(:)

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Sender: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, local_comm_size, kinfo)
   call mpi_comm_rank(local_comm, local_comm_rank, kinfo)
   print '(A,I0,A,I0)', "Sender: local_comm_rank = ",local_comm_rank, &
      &                 " of ",local_comm_size

   icpl = 1
   if (local_comm_size > 3) then
      if (local_comm_rank .ge. local_comm_size - 2) icpl = MPI_UNDEFINED
   end if

   call oasis_create_couplcomm(icpl, local_comm, coupl_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_create_couplcomm: ", rcode=kinfo)

   if (icpl == 1) then

      call mpi_comm_size(coupl_comm, comm_size, kinfo)
      call mpi_comm_rank(coupl_comm, comm_rank, kinfo)
      print '(A,I0,A,I0)', "Sender: comm_rank = ",comm_rank, " of ",comm_size

      if ( mod(n_points,comm_size) /= 0) &
         &  call oasis_abort(comp_id, comp_name, &
         & "Sender: comm_size has to divide n_points exactly", rcode=kinfo)

      local_size=n_points/comm_size
      offset=comm_rank*local_size

      n_segments = 1
      allocate(part_params(OASIS_Orange_Params(n_segments)))
      part_params(OASIS_Strategy) = OASIS_Orange
      part_params(OASIS_Segments) = n_segments
      do i = 0, n_segments-1
         part_params(OASIS_Segments + 2*i + 1) = offset
         part_params(OASIS_Segments + 2*i + 2) = local_size
      end do

      call oasis_def_partition(part_id, part_params, kinfo)
      if(kinfo<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_def_partition: ", rcode=kinfo)
      print '(A,I0,A,I0)', "Sender rank(",comm_rank,"): part_id: ", part_id
      deallocate(part_params)

      var_nodims=[1, 1]
      print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", var_name
      call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
         &               [1], OASIS_REAL, kinfo)
      if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_def_var: ", rcode=kinfo)
      print '(A,I0,A,I0)', "Sender rank(",comm_rank,"): var_id: ", var_id
   end if

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   if (icpl == 1) then

      allocate(field(local_size))
      field(:) = [(i+offset, i=1,local_size)]

      date=0

      call oasis_put(var_id, date, field, kinfo)
      if(kinfo<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_put: ", rcode=kinfo)

   end if

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_orange
