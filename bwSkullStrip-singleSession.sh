#!/bin/bash

# skull-strip a single session

# example dir structure:
#
# /data/panolocal/processedOnPano-hackney/derivedData/omt001s01/omt001s01.anat.nii.gz
# /data/panolocal/processedOnPano-hackney/derivedData/omt001s01/omt001s01-manualCOG.txt
#
# /data/panolocal/processedOnPano-nocera/derivedData/cda001pre/cda001pre.anat.nii.gz
# /data/panolocal/processedOnPano-nocera/derivedData/cda001pre/cda001pre-manualCOG.txt
# 

#sessionDir=/data/tmpHackney/acqfiles-nifti/${sessionName}
sessionDir=$1
sessionName=`basename $1`

echo ""
#du -sh ${sessionDir}/${sessionName}.anat.nii.gz
#du -sh ${sessionDir}/${sessionName}-manualCOG.txt
cog=`cat ${sessionDir}/${sessionName}-manualCOG.txt`
echo "manually-specified center-of-gravity for bet is $cog"
betInput=${sessionDir}/${sessionName}.anat.nii.gz
#du -sh $betInput
betOutput=${sessionDir}/${sessionName}.anat_brain.nii.gz
betOptions="-f .3 -c ${cog} -B -v"

bet ${betInput} ${betOutput} ${betOptions}
