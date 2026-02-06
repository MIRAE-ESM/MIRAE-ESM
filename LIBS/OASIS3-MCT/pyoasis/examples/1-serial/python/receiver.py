#!/usr/bin/env python3

import pyoasis
import numpy

from mpi4py import MPI
import time

stt = time.time()
comm = MPI.COMM_WORLD
print('Receiver: Time for comm = {} s.'.format(time.time() - stt), flush=True)

component_name = "receiver"

stt = time.time()
comp = pyoasis.Component(component_name, True, comm)
print(comp)
print('Receiver: Time for Component = {} s.'.format(time.time() - stt),
      flush=True)

n_points = 1600

stt = time.time()
partition = pyoasis.SerialPartition(n_points)
print(partition)
print('Receiver: Time for partition = {} s.'.format(time.time() - stt),
      flush=True)

stt = time.time()
variable = pyoasis.Var("FRECVATM", partition,
                       pyoasis.OasisParameters.OASIS_IN)
print('Receiver: Time for Var = {} s.'.format(time.time() - stt), flush=True)
print(variable)

comp.enddef()

date = int(0)
stt = time.time()
field = pyoasis.asarray(numpy.zeros(n_points))
print('Receiver: Time for Array = {} s.'.format(time.time() - stt),
      flush=True)

stt = time.time()
variable.get(date, field)
print('Receiver: Time for get = {} s.'.format(time.time() - stt),
      flush=True)

expected_field = pyoasis.asarray(numpy.arange(n_points, dtype=numpy.float64))
epsilon = 1e-8
error = numpy.abs(field - expected_field).sum()
if error < epsilon:
    print("Data received successfully", flush=True)

del comp
