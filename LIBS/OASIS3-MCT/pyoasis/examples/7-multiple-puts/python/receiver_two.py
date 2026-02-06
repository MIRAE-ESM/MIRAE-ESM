#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy as np

comp = pyoasis.Component("receiver_two")
print(comp)

n_points = 1
partition = pyoasis.SerialPartition(n_points)

var_1 = pyoasis.Var("FRECVICE_1", partition, OASIS.IN)
print("Recv_two ", var_1)

var_2 = pyoasis.Var("FRECVICE_2", partition, OASIS.IN)
print("Recv_two ", var_2)

comp.enddef()

inter_two = comp.get_intercomm("sender-serial")
print("Recv_two inter_two: rank = {} of {}".format(inter_two.rank,
      inter_two.size))

field = pyoasis.asarray(np.zeros(n_points, dtype=np.float64))

print("Recv_two: coupling frequencies for {} = ".format(var_1.name),
      var_1.cpl_freqs)
print("Recv_two: coupling frequencies for {} = ".format(var_2.name),
      var_2.cpl_freqs)

for date in range(43200):
    if any([date % freq == 0 for freq in var_1.cpl_freqs]):
        var_1.get(date, field)
        if abs((field - date).sum()) < 1.e-8:
            print("Recv_two: field 1 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_two at time {} got {} instead of {}".format(date,
                  field[0], date))

    if any([date % freq == 0 for freq in var_2.cpl_freqs]):
        var_2.get(date, field)
        if np.abs(field + date).sum() < 1.e-8:
            print("Recv_two: field 2 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_two at time {} got {} instead of {}".format(date,
                  field[0], date))

del comp
