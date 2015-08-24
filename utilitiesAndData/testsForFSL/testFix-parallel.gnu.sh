#!/bin/bash

# Execute four instances of FIX in parallel by wrapping in GNU parallel.

# Examples of how to use GNU parallel:
# http://www.gnu.org/software/parallel/man.html#EXAMPLE:-Rewriting-a-for-loop-and-a-while-read-loop
# http://www.gnu.org/software/parallel/man.html#EXAMPLE:-Rewriting-nested-for-loops

# For serial operation, just change -j4 to -j1 and change the penultimate line from "parallel.gnu" to "serial.gnu"

parallel -j4 --tag --line-buffer \
./testFix-singleSession.sh \
/tmp/melFromFeeds-noFIX/melFromFeeds-structBBR-mni2mmNonlinear.ica \
/opt/fix/training_files/Standard.RData \
{1} \
serial.gnuNoBash \
::: 20 15 10 5

