program sender_serial
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id
   integer, parameter :: n_points = 1600
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-serial"
   character(len=8) :: var_name = "FSENDOCN"
   real(kind=8) :: field(n_points)

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Sender: Component ID: ", comp_id

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)
   print '(A,I0)', "Sender: part_id: ", part_id

   var_nodims=[1, 1]
   print '(2A)', "Sender: var_name: ", var_name
   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_REAL, kinfo)
   if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   print '(A,I0)', "Sender: var_id: ", var_id

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   field(:) = [(i, i=1, n_points)]

   date=0

   call oasis_put(var_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_serial
