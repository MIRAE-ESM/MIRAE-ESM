#!/bin/bash

mkdir -p work

srcdir=`pwd`

#exe1=sender-box
exe1=sender-box.py
exe2=receiver
exe3=xios
exe4=nonactive

n1=4
n2=1
n3=2
n4=3

make || exit

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.
cp -f $srcdir/$exe2 $rundir/.
cp -f $srcdir/$exe3 $rundir/.
cp -f $srcdir/$exe4 $rundir/.

cp -f $srcdir/namcouple $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 python3 ./$exe1 : -np $n4 ./$exe4 : -np $n2  ./$exe2 : -np $n3 ./$exe3
