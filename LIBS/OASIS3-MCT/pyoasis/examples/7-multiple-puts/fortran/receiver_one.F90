program receiver_one
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id(2)
   integer, parameter :: n_points = 1
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=12) :: comp_name = "receiver_one"
   character(len=10), dimension(2) :: var_name = ["FRECVATM_1","FRECVATM_2"]
   real(kind=8) :: field(n_points), error
   real(kind=8) :: epsilon = 1.e-8
   integer :: ncpl
   integer, dimension(:), allocatable :: cpl_freqs_1
   integer, dimension(:), allocatable :: cpl_freqs_2
   integer :: intra_one, intra_rank, intra_size

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) &
      & call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]

   do  i = 1,2
      print '(2A)', "Recv_one: defining var: ", var_name(i)
      call oasis_def_var(var_id(i), var_name(i), part_id, var_nodims, OASIS_IN, &
         &               [1], OASIS_REAL, kinfo)
      if(kinfo<0 .or. var_id(i)<0) &
         & call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_def_var: "//trim(var_name(i)), rcode=kinfo)
   end do

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   call oasis_get_intracomm(intra_one, "sender-serial", kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intracomm: ", rcode=kinfo)

   call mpi_comm_size(intra_one, intra_size, kinfo)
   call mpi_comm_rank(intra_one, intra_rank, kinfo)
   print '(A,I0,A,I0)', "Recv_one intra_one: rank = ",intra_rank, " of ",intra_size

   call oasis_get_ncpl(var_id(1), ncpl, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_ncpl: ", rcode=kinfo)

   allocate(cpl_freqs_1(ncpl))
   call oasis_get_freqs(var_id(1), OASIS_IN, ncpl, cpl_freqs_1, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_freqs: ", rcode=kinfo)

   call oasis_get_ncpl(var_id(2), ncpl, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_ncpl: ", rcode=kinfo)

   allocate(cpl_freqs_2(ncpl))
   call oasis_get_freqs(var_id(2), OASIS_IN, ncpl, cpl_freqs_2, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_freqs: ", rcode=kinfo)

   do date = 0, 43199

      if (any(mod(date,cpl_freqs_1) == 0)) then
         field(:) = 0
         call oasis_get(var_id(1), date, field, kinfo)
         if(kinfo<0) &
            & call oasis_abort(comp_id, comp_name, &
            & "Error in oasis_get: "//trim(var_name(1)), rcode=kinfo)

         error = sum(abs(field(:)-date))
         if(error<epsilon) then
            print '(A,I0)', &
               & "Recv_one: field 1 received successfully at time ",date
         else
            print '(A,I0,A,F6.0,A,F6.0)', &
               & "Warning: Recv_one at time ",date," got ",field(1)," instead of ",1.*date
         endif
      end if

      if (any(mod(date,cpl_freqs_2) == 0)) then
         field(:) = 0
         call oasis_get(var_id(2), date, field, kinfo)
         if(kinfo<0) &
            & call oasis_abort(comp_id, comp_name, &
            & "Error in oasis_get: "//trim(var_name(1)), rcode=kinfo)

         error = sum(abs(field(:)+date))
         if(error<epsilon) then
            print '(A,I0)', &
               & "Recv_one: field 2 received successfully at time ",date
         else
            print '(A,I0,A,F6.0,A,F6.0)', &
               & "Warning: Recv_one at time ",date," got ",field(1)," instead of ",-1.*date
         endif
      end if

   end do

   deallocate(cpl_freqs_1, cpl_freqs_2)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program receiver_one
