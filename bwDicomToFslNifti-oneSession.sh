#! /bin/bash

# bwDicomToFslNifti-oneSession.sh
#
# Can be called by itself from the command line, but it is also
# designed be the middle loop of three scripts that can work together:
#
#        bwDicomToFslNifti-oneProject.sh can make serial calls to:
#        bwDicomToFslNifti-oneSession.sh , which can make serial or parallel calls to:
#        bwDicomToFslNifti-oneSeriesDir.sh

# execute bwDicomToFslNifti-oneSeriesDir.sh for every directory of DICOM images in some parent dir:
# dicomDirSession
#    - dicomDir01
#    - dicomDir02
#    - dicomDir03

#
# $dicomDirProjectUngroomed
# $dicomDirProjectGroomed
#    $dicomDirSession
#       $dicomDirSeries
#           (individual DICOM files)
#
# NB: Above, "groomed" just means that each sessiondir has been named with a consistently
# formatted participantSessionID (e.g., p0000s01)


############  INPUT: DICOMS ############
# (see hierarchy described above)
dicomDirSession=$1


############  OUTPUT: NIFTIs ############
# participant/session identifier to be pre-pended to the names of output NIFITS and BXH files
# e.g., p0003s01
# (this is just going to get passed to bwDicomToFslNifti-oneSeries.sh)
participantSessionID=$2


# a directory into which we can write the NIFTI and BXH output:
# (this is just going to get passed to bwDicomToFslNifti-oneSeries.sh)
niftiDirSession=$3

# how many dicomdirs should be processed in parallel?
# example from running one of Joe's sessions on aref mbp:
# 1:      209.37 real       206.75 user         3.09 sys
# 2:      106.77 real       210.66 user         3.12 sys
# 3:       76.27 real       217.87 user         3.23 sys
# 4:       67.12 real       226.45 user         3.44 sys
# 5:       61.46 real       248.73 user         3.86 sys
# 6:       62.21 real       260.12 user         4.13 sys
# 7:       63.40 real       277.40 user         4.33 sys
# 8:       65.56 real       304.71 user         4.78 sys
# 0:       68.94 real       317.18 user         5.38 sys
# 0:       68.68 real       318.16 user         4.98 sys
parallelDicomDirs=$4

echo ""
echo ""
echo "###############################################################"
echo "START: creating MNI-oriented NIFTIs from all individual DICOM dirs"
echo "inside of this parent dir:"
tree -L 1 "${dicomDirSession}"
echo "(processing ${parallelDicomDirs} DICOM dirs in parallel via GNU parallel"
echo "###############################################################"

# because it's going to be recreated by bwDicomToFslNifti-oneSeries.sh
# TBD: is this really a good idea?
rm -fr ${niftiDirSession}

ls -d ${dicomDirSession}/* | parallel --jobs ${parallelDicomDirs} --tag --line-buffer bwDicomToFslNifti-oneSeries.sh {} ${participantSessionID} ${niftiDirSession}

mkdir ${niftiDirSession}/bxh+orig
mv ${niftiDirSession}/*ortOrig* ${niftiDirSession}/bxh+orig/

echo ""
echo ""
echo ""
ls -altrh ${niftiDirSession}/${participantSessionID}*
echo ""
echo ""
echo "###############################################################"
echo "DONE: created MNI-oriented NIFTIs from all individual DICOM dirs"
echo "inside of this parent dir:"
tree -L 1 "${dicomDirSession}"
echo "Size of output dir:"
du -sh ${niftiDirSession}
echo "###############################################################"

