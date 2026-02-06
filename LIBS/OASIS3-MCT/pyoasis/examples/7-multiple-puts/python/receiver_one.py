#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy as np

comp = pyoasis.Component("receiver_one")
print(comp)

n_points = 1
partition = pyoasis.SerialPartition(n_points)

var_1 = pyoasis.Var("FRECVATM_1", partition, OASIS.IN)
print("Recv_one ", var_1)

var_2 = pyoasis.Var("FRECVATM_2", partition, OASIS.IN)
print("Recv_one ", var_2)

comp.enddef()

intra_one = comp.get_intracomm("sender-serial")
print("Recv_one intra_one: rank = {} of {}".format(intra_one.rank,
      intra_one.size))

field = pyoasis.asarray(np.zeros(n_points, dtype=np.float64))

print("Recv_one: coupling frequencies for {} = ".format(var_1.name),
      var_1.cpl_freqs)
print("Recv_one: coupling frequencies for {} = ".format(var_2.name),
      var_2.cpl_freqs)

for date in range(43200):
    if any([date % freq == 0 for freq in var_1.cpl_freqs]):
        var_1.get(date, field)
        if abs((field - date).sum()) < 1.e-8:
            print("Recv_one: field 1 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_one at time {} got {} instead of {}".format(
                  date, field[0], date))

    if any([date % freq == 0 for freq in var_2.cpl_freqs]):
        var_2.get(date, field)
        if np.abs(field + date).sum() < 1.e-8:
            print("Recv_one: field 2 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_one at time {} got {} instead of {}".format(date,
                  field[0], date))

del comp
