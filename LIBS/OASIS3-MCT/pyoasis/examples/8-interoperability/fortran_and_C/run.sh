#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=sender-apple
exe2=sendrecv-orange
exe3=receiver-serial

n1=4
n2=4
n3=1

make || exit

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.
cp -f $srcdir/$exe2 $rundir/.
cp -f $srcdir/$exe3 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 ./$exe1 : -np $n3 ./$exe3 : -np $n2 ./$exe2
