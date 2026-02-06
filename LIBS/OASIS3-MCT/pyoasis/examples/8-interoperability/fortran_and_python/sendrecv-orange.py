#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy

from mpi4py import MPI

# Test case for the most advanced partition and put/get options.
# Credits: Eric Maisonnave

comm = MPI.COMM_WORLD

component_name = "sendrecv"

comp = pyoasis.Component(component_name, True, comm)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

if comm_rank == 0:
    print("Component name: {} = Component ID: {}".format(component_name,
                                                         comp._id))

n_points = 16

# Parameters for incoming partition

local_lons = (n_points // 2) // comm_size
offsets = [comm_rank * local_lons,
           comm_rank * local_lons + (n_points // 2)]
extents = [local_lons,
           local_lons]

# Parameters for outgoing partition: notice that the boxes extents
# do not sum up to n_points, hence the usually optional global_size
# argument of part_out __init__ is in this case mandatory

global_offsets = [0, 2, 4, 6]
extents_x = [0, 2, 0, 2]
extents_y = [0, 2, 0, 2]

# Use optional argument name of partitions __init__ for the case
# depicted in Oasis user guide as
# mandatory if oasis def partition is called either for a grid
# decomposed not across all the processes of a component or if
# the related oasis def partition are not called in the same
# order on the different component processes

if comm_rank % 2 != 0:
    part_in = pyoasis.OrangePartition(offsets, extents, name="part_in")

    part_out = pyoasis.BoxPartition(global_offsets[comm_rank],
                                    extents_x[comm_rank],
                                    extents_y[comm_rank],
                                    (n_points // 2),
                                    global_size=n_points,
                                    name="part_out")
else:
    part_out = pyoasis.BoxPartition(global_offsets[comm_rank],
                                    extents_x[comm_rank],
                                    extents_y[comm_rank],
                                    (n_points // 2),
                                    global_size=n_points,
                                    name="part_out")

    part_in = pyoasis.OrangePartition(offsets, extents, name="part_in")

if comm_rank == 0:
    print("{}: part_in  id: {}".format(component_name, part_in._id))
    print("{}: part_out id: {}".format(component_name, part_out._id))

variable = pyoasis.Var("FRECVATM", part_in, OASIS.IN, bundle_size=2)
if comm_rank == 0:
    print("{}: var_name: FRECVATM = var_id: {}".format(component_name,
                                                       variable._id))

var_out = pyoasis.Var("FSENDATM", part_out, OASIS.OUT)
if comm_rank == 0:
    print("{}: var_name: FSENDATM = var_id: {}".format(component_name, var_out._id))

comp.enddef()

date = int(0)
bundle = pyoasis.asarray(numpy.zeros((local_lons, 2, 2),
                                     dtype=numpy.float64))

variable.get(date, bundle)

expected_bundle = pyoasis.asarray(numpy.zeros((local_lons, 2, 2),
                                              dtype=numpy.float64))
for i in range(2):
    expected_bundle[:, :, i] = i + 1
for i in range(local_lons):
    expected_bundle[i, :, :] += (i + 1 + comm_rank * local_lons) * 100
for i in range(2):
    expected_bundle[:, i, :] += (i + 1) * 10

epsilon = 1e-8
error = numpy.abs(bundle - expected_bundle).sum()
if error < epsilon:
    print("{}: On rank {} data received successfully".format(component_name,
                                                             comm_rank))

for i in range(2):
    print("{}: On rank {} Bundle {} is".format(component_name, comm_rank,
                                               i + 1))
    print(bundle[:, 0, i])
    print(bundle[:, 1, i])

if comm_rank % 2 != 0:
    field = pyoasis.asarray(bundle[:, :, 1], dtype=numpy.float32)
    date = int(0)
    var_out.put(date, field)

del comp
