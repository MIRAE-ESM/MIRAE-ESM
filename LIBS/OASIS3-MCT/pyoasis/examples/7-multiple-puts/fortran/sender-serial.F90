program sender_serial
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id(2)
   integer, parameter :: n_points = 1
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-serial"
   character(len=10), dimension(2) :: var_name = ["FSENDOCN_1","FSENDOCN_2"]
   real(kind=8) :: field(n_points)
   integer :: ncpl
   integer, dimension(:), allocatable :: cpl_freqs
   logical :: ll_rst
   integer :: intra_one, intra_rank, intra_size
   integer :: inter_two, inter_rank, inter_size

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]
   do i = 1, 2
      print '(2A)', "Sender: var_name: ", var_name(i)
      call oasis_def_var(var_id(i), var_name(i), part_id, var_nodims, OASIS_OUT, &
         &               [1], OASIS_REAL, kinfo)
      if(kinfo<0 .or. var_id(i)<0) &
         & call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_def_var: "//trim(var_name(i)), rcode=kinfo)
   end do

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_enddef: ", rcode=kinfo)

   call oasis_get_intracomm(intra_one,"receiver_one",kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intracomm: ", rcode=kinfo)

   call mpi_comm_size(intra_one, intra_size, kinfo)
   call mpi_comm_rank(intra_one, intra_rank, kinfo)
   print '(A,I0,A,I0)', "Sender intra_one: rank = ",intra_rank, " of ",intra_size

   call oasis_get_intercomm(inter_two,"receiver_two",kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      &"Error in oasis_get_intercomm: ", rcode=kinfo)

   call mpi_comm_size(inter_two, inter_size, kinfo)
   call mpi_comm_rank(inter_two, inter_rank, kinfo)
   print '(A,I0,A,I0)', "Sender inter_two: rank = ",inter_rank, " of ",inter_size

   call oasis_get_ncpl(var_id(2), ncpl, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_ncpl: ", rcode=kinfo)

   allocate(cpl_freqs(ncpl))

   call oasis_get_freqs(var_id(2), OASIS_OUT, ncpl, cpl_freqs, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_freqs: ", rcode=kinfo)

   print '(3A,2I6)', &
      & "Sender: coupling frequencies for ",trim(var_name(2)), " are ", cpl_freqs(:)

   do date= 0, 43199

      call oasis_put_inquire(var_id(1), date, kinfo)
      if(kinfo<0) call oasis_abort(comp_id, comp_name, &
         & "Error in oasis_put_inquire: ", rcode=kinfo)

      if ( kinfo == OASIS_Sent) then

         field(:) = date

         call oasis_put(var_id(1), date, field, kinfo)
         if(kinfo<0) &
            & call oasis_abort(comp_id, comp_name, &
            & "Error in oasis_put: "//trim(var_name(1)), rcode=kinfo)

      endif

      if (any(mod(date,cpl_freqs) == 0)) then

         call oasis_set_debug(2)

         field(:) = (-1.) * date
         ll_rst = mod(date, 10800) == 0
         call oasis_put(var_id(2), date, field, kinfo, write_restart=ll_rst)
         if(kinfo<0) &
            & call oasis_abort(comp_id, comp_name, &
            & "Error in oasis_put: "//trim(var_name(2)), rcode=kinfo)

         call oasis_set_debug(0)

      end if

   end do

   deallocate(cpl_freqs)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_serial
