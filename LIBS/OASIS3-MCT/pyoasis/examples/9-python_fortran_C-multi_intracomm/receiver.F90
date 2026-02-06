program receiver
   use mod_oasis
   use mpi
   implicit none
   integer :: i, kinfo, il_x, root
   integer :: comp_id
   integer :: local_comm, comm_size, comm_rank
   character(len=8) :: comp_name = "receiver"
   character(len=10), dimension(3) :: cnames
   integer, dimension(3) :: root_ranks
   integer :: intra_comm, intra_rank, intra_size

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
   print '(A,I0,A,I0)', "Receiver: rank = ",comm_rank, " of ",comm_size

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   cnames(:) = ''
   cnames(1) = 'xios'
   cnames(2) = comp_name
   cnames(3) = 'sender-box'

   call oasis_get_multi_intracomm(intra_comm,cnames,root_ranks,kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intracomm: ", rcode=kinfo)

   call mpi_comm_size(intra_comm, intra_size, kinfo)
   call mpi_comm_rank(intra_comm, intra_rank, kinfo)
   print '(A,I0,A,I0,A,I0)', "Receiver rank(",comm_rank,") intra_comm: rank = ",intra_rank, " of ",intra_size

   if ( comm_rank == 0 ) then
      do i = 1, size(cnames)
         print '(3A,I0)', "Receiver: component ",trim(cnames(i))," starts at rank ",root_ranks(i)
      end do
   end if

   if ( comm_rank == 0 ) then
      do i = 1, size(cnames)
         if (trim(cnames(i)) == 'xios') then
            root = root_ranks(i)
            exit
         end if
      end do
   end if
   call mpi_bcast(il_x, 1, MPI_INTEGER, root, intra_comm, kinfo)
   if (il_x == 222) then
      print '(A,I0,A,I0)', "Receiver rank(",comm_rank,") successfully got broadcasted il_x = ",il_x
   else
      print '(A,I0,A,I0)', "Receiver rank(",comm_rank,") got broadcasted il_x = ",il_x
   end if

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program receiver
