#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy
from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "receiver"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16
extent = int(n_points/comm_size)
offset = comm_rank*extent

offsets = [offset]
extents = [extent]

partition = pyoasis.OrangePartition(offsets, extents)
print(partition)

variable = pyoasis.Var("FRECVATM", partition, OASIS.IN)
print(variable)

comp.enddef()

date = int(0)
field = pyoasis.asarray(numpy.zeros(extent))

variable.get(date, field)

expected_field = pyoasis.asarray(numpy.zeros(extent))
for i in range(extent):
    expected_field[i] = offset + i

epsilon = 1e-8
error = numpy.abs(field-expected_field).sum()
if error < epsilon:
    print("Data received successfully")

del comp
