program sender_apple
   use mpi
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id
   integer :: n_points = 16
   integer :: part_params(OASIS_Apple_Params), offset, local_size
   integer :: local_comm, comm_size, comm_rank, commworld
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-apple"
   character(len=8) :: var_name = "FSENDOCN"
   real, allocatable :: field(:)

   print '(2A)', "Component name: ", comp_name

   call MPI_Init(kinfo)
   call MPI_Comm_Split(MPI_COMM_WORLD, 1, 0, commworld, kinfo)
   call oasis_init_comp(comp_id, comp_name, kinfo, commworld = commworld)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Sender: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Sender: rank = ",comm_rank, " of ",comm_size

   local_size=n_points/comm_size
   offset=comm_rank*local_size
   if (comm_rank == comm_size - 1) &
      & local_size = n_points - offset

   part_params(OASIS_Strategy) = OASIS_Apple
   part_params(OASIS_Offset)   = offset
   part_params(OASIS_Length)   = local_size
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)
   print '(A,I0,A,I0)', "Sender rank(",comm_rank,"): part_id: ", part_id

   var_nodims=[1, 1]
   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", var_name
   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_REAL, kinfo)
   if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   print '(A,I0,A,I0)', "Sender rank(",comm_rank,"): var_id: ", var_id

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   allocate(field(local_size))
   field(:) = [(offset+i, i=1, local_size)]

   date=0

   call oasis_put(var_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

   call MPI_Finalize(kinfo)

end program sender_apple
