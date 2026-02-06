#!/usr/bin/env python3

import numpy
import pyoasis
from pyoasis import OASIS
from mpi4py import MPI

component_name = "receiver"

commworld = MPI.COMM_WORLD.Split(1)
comp = pyoasis.Component(component_name, communicator = commworld)
print(comp)

n_points = 1600

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FRECVATM", partition, OASIS.IN)
print(variable)

comp.enddef()

date = int(0)
field = pyoasis.asarray(numpy.zeros(n_points))

variable.get(date, field)

expected_field = pyoasis.asarray(numpy.arange(n_points, dtype=numpy.float64))
epsilon = 1e-8
error = numpy.abs(field - expected_field).sum()
if error < epsilon:
    print("Data received successfully")

del comp
