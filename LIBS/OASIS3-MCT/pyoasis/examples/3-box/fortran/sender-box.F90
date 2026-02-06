program sender_box
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   INTEGER :: comp_id, part_id, var_id, var_id2
   integer :: n_points = 16
   integer :: part_params(OASIS_Box_Params), offsets(4)
   integer :: local_comm, local_size, comm_size, comm_rank
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-box"
   character(len=8) :: var_name = "FSENDOCN"
   character(len=8) :: var_name2 = "NOTANAME"
   real, allocatable :: field(:)
   integer :: intra_comm, intra_rank, intra_size
   integer :: inter_comm, inter_rank, inter_size, inter_rsize

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Sender: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Sender: rank = ",comm_rank, " of ",comm_size

   if ( comm_size /= 4) call oasis_abort(comp_id, comp_name, &
      & "Sender: comm_size has to be 4 for this example", rcode=kinfo)

   local_size = n_points/comm_size

   offsets=[0, 2, 8, 10]

   part_params(OASIS_Strategy) = OASIS_Box
   part_params(OASIS_Offset)   = offsets(comm_rank+1)
   part_params(OASIS_SizeX)    = 2
   part_params(OASIS_SizeY)    = 2
   part_params(OASIS_LdX)      = 4
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

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", var_name2
   call oasis_def_var(var_id2, var_name2, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_REAL, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   if(var_id2<0) then
      print '(A,I0,A,I0,A)', "Sender rank(",comm_rank,"): var_id: ", var_id2, " is not active"
   else
      print '(A,I0,A,I0)', "Sender rank(",comm_rank,"): var_id: ", var_id2     
   end if
   
   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   call oasis_get_intracomm(intra_comm,"receiver",kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intracomm: ", rcode=kinfo)

   call mpi_comm_size(intra_comm, intra_size, kinfo)
   call mpi_comm_rank(intra_comm, intra_rank, kinfo)
   print '(A,I0,A,I0)', "Sender intra_comm: rank = ",intra_rank, " of ",intra_size

   call oasis_get_intercomm(inter_comm,"receiver",kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intercomm: ", rcode=kinfo)

   call mpi_comm_size(inter_comm, inter_size, kinfo)
   call mpi_comm_rank(inter_comm, inter_rank, kinfo)
   call mpi_comm_remote_size(inter_comm, inter_rsize, kinfo)
   print '(A,I0,A,I0,A,I0)', "Sender inter_comm: rank = ",inter_rank, " of ",inter_size, &
      & " Remote size = ",inter_rsize

   allocate(field(local_size))
   field=[offsets(comm_rank+1)+1, offsets(comm_rank+1)+2,&
      &   offsets(comm_rank+1)+5, offsets(comm_rank+1)+6]

   date=0

   call oasis_put(var_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_box
