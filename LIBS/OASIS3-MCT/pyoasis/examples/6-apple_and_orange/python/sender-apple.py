#!/usr/bin/env python3

import numpy
import pyoasis
from pyoasis import OASIS
from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-apple"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

local_comm_rank = comp.localcomm.rank
local_comm_size = comp.localcomm.size

icpl = 1
if local_comm_size > 3:
    if local_comm_rank >= local_comm_size - 2:
        icpl = 0

couplcomm = comp.localcomm.Split(icpl, local_comm_rank)
if icpl == 0:
    couplcomm = MPI.COMM_NULL

comp.set_couplcomm(couplcomm)

if icpl == 1:

    n_points = 16

    comm_rank = comp.couplcomm.rank
    comm_size = comp.couplcomm.size

    local_size = int(n_points/comm_size)
    offset = comm_rank*local_size
    if comm_rank == comm_size - 1:
        local_size = n_points - offset

    partition = pyoasis.ApplePartition(offset, local_size)
    print(partition)

    variable = pyoasis.Var("FSENDOCN", partition, OASIS.OUT)
    print(variable)

comp.enddef()

if icpl == 1:

    date = int(0)

    field = pyoasis.asarray(numpy.zeros(local_size))

    for i in range(local_size):
        field[i] = offset + i

    print("Sent data: "+str(field))

    variable.put(date, field)

del comp
