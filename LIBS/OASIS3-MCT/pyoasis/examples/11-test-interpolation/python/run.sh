#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/../common_data
casename=`basename $srcdir`

exe1=sender-apple.py
exe2=receiver.py
uti=utils.py

n1=4
n2=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

ln -sf $srcdir/$exe1 $rundir/.
ln -sf $srcdir/$exe2 $rundir/.
ln -sf $srcdir/$uti $rundir/.

ln -sf $datadir/grids.nc $rundir/.
ln -sf $datadir/areas.nc $rundir/.

ln -sf $datadir/cartopy $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 python3 $exe1 : -np $n2 python3 $exe2
