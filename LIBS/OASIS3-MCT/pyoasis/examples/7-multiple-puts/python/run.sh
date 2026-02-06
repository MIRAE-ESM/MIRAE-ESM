#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=sender-serial.py
exe2=receiver_one.py
exe3=receiver_two.py

n1=1
n2=1
n3=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.
cp -f $srcdir/$exe2 $rundir/.
cp -f $srcdir/$exe3 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 python3 $exe1 : -np $n2 python3 $exe2 : -np $n3 python3 $exe3
