#!/usr/bin/env python3

from mpi4py import MPI

print("Extra process not in OASIS commworld", flush=True)

nullcomm = MPI.COMM_WORLD.Split(MPI.UNDEFINED)
