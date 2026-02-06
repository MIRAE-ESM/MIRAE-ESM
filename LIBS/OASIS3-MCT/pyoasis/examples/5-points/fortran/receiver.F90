program receiver
   use mod_oasis
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, var_id
   integer, parameter :: n_points = 16
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=8) :: comp_name = "receiver"
   character(len=8) :: var_name = "FRECVATM"
   real(kind=8) :: field(n_points), error, epsilon

   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "Receiver: Component ID: ", comp_id

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)
   print '(A,I0)', "Receiver: part_id: ", part_id

   var_nodims=[1, 1]
   print '(2A)', "Receiver: var_name: ", var_name
   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_REAL, kinfo)
   if(kinfo<0 .or. var_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)
   print '(A,I0)', "Receiver: var_id: ", var_id

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   date=0

   field(:)=0

   call oasis_get(var_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

   epsilon=1e-8
   error=0.
   do i = 1, n_points
      error=error+abs(field(i)-i)
   end do
   if(error<epsilon) print '(A)', "Receiver: Data received successfully" 

end program receiver
