#!/bin/sh

# bwSkullStrip-parallelSessions.sh

# This is a simple wrapper for bwSkullStrip-singleSession.sh , where there is
# much more information.

# TBD: lots. Especially documentation of file tree to which this applies.


# niftiDirProject=/data/panolocal/processedOnPano-hackney/derivedData
# niftiDirProject=/data/panolocal/processedOnPano-nocera/derivedData
niftiDirProject=$1
parallelSkullstrips=$2

ls -d ${niftiDirProject}/* | parallel --jobs ${parallelSkullstrips} --tag --line-buffer bwSkullStrip-singleSession.sh {}
