program non_oasis
   use mpi
   implicit none
   integer :: kinfo
   integer :: nullcomm

   print '(A)', "Extra process not in OASIS commworld"

   call MPI_Init(kinfo)
   call MPI_Comm_Split(MPI_COMM_WORLD, MPI_UNDEFINED, 0, nullcomm, kinfo)

   call MPI_Finalize(kinfo)
   
end program non_oasis
