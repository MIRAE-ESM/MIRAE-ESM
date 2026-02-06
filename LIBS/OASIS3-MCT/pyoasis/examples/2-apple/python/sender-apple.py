#!/usr/bin/env python3

import numpy
import pyoasis
from pyoasis import OASIS
from mpi4py import MPI

component_name = "sender-apple"

commworld = MPI.COMM_WORLD.Split(1)
comp = pyoasis.Component(component_name, communicator = commworld)
print(comp)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 1600

local_size = int(n_points / comm_size)
offset = comm_rank * local_size
if comm_rank == comm_size - 1:
    local_size = n_points - offset

partition = pyoasis.ApplePartition(offset, local_size)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, OASIS.OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.asarray(numpy.arange(start=offset, stop=offset + local_size,
                        dtype=numpy.float64))

print("Sent data: from {} to {}".format(int(field[0]), int(field[-1])))

variable.put(date, field)

print("Terminating component {}".format(comp.name))
del comp
