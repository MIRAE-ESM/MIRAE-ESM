#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=writer

n1=3

make || exit

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 ./$exe1
