#!/bin/bash

# bwDicomToFslNifti-oneSeries.sh
# 
# Can be called by itself from the command line, but it is also
# designed be the inner loop of three scripts that can work together:
#
#        bwDicomToFslNifti-oneProject.sh can make serial calls to
#        bwDicomToFslNifti-oneSession.sh , which can make parallel calls to 
#        bwDicomToFslNifti-oneSeries.sh

# Take a directory full of dicom images and convert them to FSL-oriented NIFTI images via bxh files.
# Leaves the bxh files as output in the event that you would like to run FBIRN QC.
#
# TBD: test to make sure only one DICOM series in the directory. And nothing else.

# Input directory full of DICOMS from a single series:
# e.g.,  /data/project/participant/AX_FLAIR
# (the basename of this directory will be used to name output NIFIT and BXH files)
dicomDirSeries=$1

# participant and session identifier to be pre-pended to the names of output NIFITS and BXH files
# e.g., p0001s01
participantSessionID=$2

# a directory into which we can write the NIFTI and BXH output:
niftiDirSeries=$3


#################
# process the arguments
################
# Get series name from the name of the input directory. 
# e.g., AX_FLAIR from the DICOM directory /data/project/participant/AX_FLAIR/
seriesName=`basename ${dicomDirSeries}`
# We're going to name our output files based on 1) the name of that input
# directory and 2) the user-supplied participantSessionID:
# e.g., pMH001s001.AX_FLAIR
outputName="${participantSessionID}.${seriesName}"
# create the output directory
mkdir -p ${niftiDirSeries}


#################
# parse arguments
################
#   1) count the number of DICOM files for your manual verification (command: ls -1 | wc -l)
#   2) create a .bxh file containing the series' metadata (command: dicom2bxh)
#   3) create a 4D nifti file (command: bxh2analyze --nii)
#   4) reorient that 4D nifti file into gross alignment with the MNI 152 template (command: fslreorient2std)
# TODO: change fslreorient2std to AFNI


echo ""
echo ""
echo "###############################################################"
echo "Converting one series' folder of DICOMs to MNI-oriented NIFTI"
echo "(series ${outputName} )"
echo "###############################################################"
echo ""
echo "INPUT FOLDER CONTAINING DICOMS: ${dicomDirSeries}"
echo -n "FOLDER FILE COUNT: "
ls -1 ${dicomDirSeries} | wc -l
# should you want an interative mode: 
# echo "If that's the expected DICOM count for the series, hit "
# echo -n "Enter to continue. (or CTRL-C to quit)"
# read
echo ""
echo ""
echo "Creating .bxh metafile for series ${outputName}  ..."
dicom2bxh ${dicomDirSeries}/* ${niftiDirSeries}/${outputName}.ortOrig.bxh
ls -lh ${niftiDirSeries}/${outputName}.ortOrig.bxh
echo "...done."

echo ""
echo ""
echo "Creating nifti volume for series ${outputName}  ..."
bxh2analyze --niigz -b -s ${niftiDirSeries}/${outputName}.ortOrig.bxh ${niftiDirSeries}/${outputName}.ortOrig
ls -lh ${niftiDirSeries}/${outputName}.ortOrig.nii.gz
echo "...done."
echo ""
echo ""
echo "Reorienting series ${seriesName} nifti volume to match FSL's MNI 152 template..."
fslreorient2std ${niftiDirSeries}/${outputName}.ortOrig.nii.gz ${niftiDirSeries}/${outputName}.nii.gz
ls -lh ${niftiDirSeries}/${outputName}.nii.gz
echo "...done."

echo ""
echo ""
ls -ltrh ${niftiDirSeries}/${outputName}*
echo ""


