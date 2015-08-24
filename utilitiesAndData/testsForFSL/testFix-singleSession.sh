#!/bin/bash

# Applying FIX to a single melodic output directory should take fewer than 10 minutes on most modern hardware:

############# arguments: ############
#...structured to allow this script to be easly called by external parllel
# processor such as GNU parallel or ppss
#
# TBD: test passed values

# the melodic output directory that we'll copy for fix i/o
# example: /tmp/melFromFeeds-noFIX/melFromFeeds-structBBR-mni2mmNonlinear.ica
melodicOut=$1

# the existing trained-weights file that will be used to classify components
# example: /opt/fix/training_files/Standard.RData
fixWeightsFile=$2

# the fix threshold
# example: 20
fixThresh=$3

# how this script is being executed. just affects output naming.
# example: serial, parallel.gnu, parallel.ppss, parallel.tmux
execution=$4

# get basenames so that they can be used to label output:
fixInName="`basename ${melodicOut}`"
fixWeightsName=`basename ${fixWeightsFile} | sed 's/\.RData//'`

# create parent directory where we'll put the .ica dir to be used for fix input/output:
fixOutParent=/tmp/melFromFeeds-fixOut-${execution}-thresh${fixThresh}-weights${fixWeightsName}
rm -fr ${fixOutParent}
mkdir ${fixOutParent}

# Create a copy of the original non-fix melodic .ica output. Will use the copy for fix input/output:
cp -a ${melodicOut} ${fixOutParent}/
fixOut="${fixOutParent}/${fixInName}"

# run fix:
echo ""
echo "######################################"
date
echo "Launching FIX:"
echo "MELODIC dir:      ${fixInName}"
echo "trained-weights:  ${fixWeightsName}"
echo "FIX threshold:    ${fixThresh}"
echo -n "FIX version:      "
which fix | xargs dirname | xargs ls -l
echo "######################################"
echo ""
/usr/bin/time fix ${fixOut} ${fixWeightsFile} ${fixThresh} -m
echo ""
date
echo "FIX complete for thresh ${fixThresh} of ${fixInName}."
du -sh ${fixOut}
echo ""
