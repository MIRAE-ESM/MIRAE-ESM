#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-points"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

n_points = 16

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

local_size = int(n_points/comm_size)
offset = comm_rank*local_size

indices = []
for i in range(local_size):
    indices.append(offset + i)

partition = pyoasis.PointsPartition(indices)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, OASIS.OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.asarray(indices)

variable.put(date, field)

del comp
