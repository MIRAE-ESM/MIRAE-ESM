program receiver
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id
   integer :: local_comm, comm_size, comm_rank
   integer, parameter :: n_points = 16
   integer :: offset, local_size, n_segments
   integer, allocatable, dimension(:) :: part_params
   integer :: var_nodims(2)
   character(len=8) :: comp_name = "receiver"
   character(len=8) :: var_name = "FRECVATM"
   real(kind=8), allocatable :: field(:)
   real(kind=8) :: error, epsilon

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Receiver: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Receiver: local_comm_rank = ",comm_rank, &
      &                 " of ",comm_size

   if ( mod(n_points,comm_size) /= 0) &
      &  call oasis_abort(comp_id, comp_name, &
      & "Receiver: comm_size has to divide n_points exaclty", rcode=kinfo)

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
   print '(A,I0,A,I0)', "Receiver rank(",comm_rank,"): part_id: ", part_id
   deallocate(part_params)

   var_nodims=[1, 1]
   print '(A,I0,2A)', "Receiver rank(",comm_rank,"): var_name: ", var_name
   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_IN, &
      &               [1], OASIS_REAL, kinfo)
   if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   print '(A,I0,A,I0)', "Receiver rank(",comm_rank,"): var_id: ", var_id

   call oasis_enddef(kinfo)
   if(kinfo<0) then
      print *, "Error in oasis_enddef: ", kinfo
      stop
   endif

   date=0

   allocate(field(local_size))
   field(:)=0

   call oasis_get(var_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

   epsilon=1e-8
   error=0
   do i = 1, local_size
      error=error+abs(field(i)-i-offset)
   end do
   if(error<epsilon)  print '(A,I0,A)', "Receiver rank(",comm_rank,"): Data received successfully"

end program receiver
