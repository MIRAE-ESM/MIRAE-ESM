#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD

component_name = "sender-box"

comp = pyoasis.Component(component_name)
comm_rank = comp.localcomm.rank

print(comp)
print("Sender: rank = {} of {}".format(comm_rank,
                                       comp.localcomm.size))

comp.enddef()

comp_list = ['receiver', component_name, 'xios']
intra_comm, root_ranks = comp.get_multi_intracomm(comp_list)

print("Sender: rank({}) intra_comm: rank = {} of {}".format(comm_rank,
                                                            intra_comm.rank,
                                                            intra_comm.size))

if comm_rank == 0:
    for comp in root_ranks:
        print("Sender: component {} starts at {}".format(comp, root_ranks[comp]))

    il_x = 111
    intra_comm.Send([np.array([il_x],dtype=np.int32), MPI.INT], dest=root_ranks['xios'], tag=0)
    print("Sender rank({}) sent il_x = {}".format(comm_rank,il_x))

il_x = np.empty(1, dtype=np.int32)
intra_comm.Bcast(il_x, root=root_ranks['xios'])
il_x = il_x[0]
print("Sender rank({}) got broadcasted il_x = {}".format(comm_rank,il_x))
