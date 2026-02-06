program nonactive
   use mod_oasis
   use mpi
   implicit none
   integer :: i, kinfo, root
   integer :: comp_id
   character(len=10) :: comp_name = "nonactive"
   integer :: local_comm, local_size, comm_size, comm_rank
   character(len=10), dimension(3) :: cnames
   integer :: intra_comm, intra_rank, intra_size

!AP   logical, parameter :: lp_coupled = .false.
   logical, parameter :: lp_coupled = .true.

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo, coupled=lp_coupled)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Nonactive: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Nonactive: rank = ",comm_rank, " of ",comm_size

   if (lp_coupled) then

      call oasis_enddef(kinfo)
      if(kinfo<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_enddef: ", rcode=kinfo)

      call oasis_terminate(kinfo)
      if(kinfo<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_terminate: ", rcode=kinfo)

   end if

end program nonactive
