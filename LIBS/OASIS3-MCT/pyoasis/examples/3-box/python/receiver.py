#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy
from mpi4py import MPI


component_name = "receiver"

comp = pyoasis.Component(component_name)
print(comp)

n_points = 16

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FRECVATM", partition, OASIS.IN)
print(variable)

comp.enddef()

intracomm = comp.get_intracomm("sender-box")
intercomm = comp.get_intercomm("sender-box")

print("Receiver intra_comm: rank = {} of {}".format(intracomm.rank,
                                                    intracomm.size))
print("Receiver inter_comm: rank = {} of {} Remote size = {}".format(intercomm.rank,
                                                                     intercomm.size,
                                                                     intercomm.remote_size))

date = int(0)
field = pyoasis.asarray(numpy.zeros(n_points))

print(variable.get(date, field))

expected_field = pyoasis.asarray(range(n_points))
epsilon = 1e-8
error = numpy.abs(field-expected_field).sum()
if error < epsilon:
    print("Data received successfully")

del comp
