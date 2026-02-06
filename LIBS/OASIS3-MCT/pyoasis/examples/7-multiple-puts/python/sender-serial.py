#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy as np

comp = pyoasis.Component("sender-serial")
print(comp)

n_points = 1
partition = pyoasis.SerialPartition(n_points)

var_1 = pyoasis.Var("FSENDOCN_1", partition, OASIS.OUT)
print("Sender ", var_1)
var_2 = pyoasis.Var("FSENDOCN_2", partition, OASIS.OUT)
print("Sender ", var_2)

comp.enddef()

intra_one = comp.get_intracomm("receiver_one")
print("Sender intra_one: rank = {} of {}".format(intra_one.rank,
      intra_one.size))

inter_two = comp.get_intercomm("receiver_two")
print("Sender inter_two: rank = {} of {}".format(inter_two.rank,
      inter_two.size))

print("Sender: coupling frequencies for {} are ".format(var_2.name),
      var_2.cpl_freqs, flush=True)

for date in range(43200):

    if var_1.put_inquire(date) == OASIS.SENT:
        var_1.put(date, pyoasis.asarray([date], dtype=np.float64))

    if any([date % freq == 0 for freq in var_2.cpl_freqs]):
        comp.debug_level = 2
        var_2.put(date, pyoasis.asarray([-1.*date], dtype=np.float64),
                  date % 10800 == 0)
        comp.debug_level = 0
        if date == 0:
            print("PyOasis debug level set to {}".format(comp.debug_level))

del comp
