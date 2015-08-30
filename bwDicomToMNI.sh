#!/bin/bash

# Take a folder full of dicom images and convert them to FSL-oriented NIFTI images via bxh files.
# Leaves he bxh files as output in the event that you would like to run FBIRN QC.
#
# TBD: test to make sure only one DICOM series in the folder. And nothing else.

# input folder full of DICOMS from a single series:
# e.g.,  /data/project/participant/AX_FLAIR
# (the basename of this folder will be used to name output NIFIT and BXH files)
inputFolder=$1

# participant and session identifier to be pre-pended to the names of output NIFITS and BXH files
# e.g., pMH0001s01
prefix=$2

# an exisitng directory into which we can write the NIFTI and BXH output:
outputParent=$3


#################
# parse arguments
################
# get series name from the name of the input folder
# e.g., AX_FLAIR from the DICOM folder /data/project/participant/AX_FLAIR/

seriesName=`basename ${inputFolder}`
outputName="${prefix}-${seriesName}"


#################
# parse arguments
################
#   1) count the number of DICOM files for your manual verification (command: ls -1 | wc -l)
#   2) create a .bxh file containing the series' metadata (command: dicom2bxh)
#   3) create a 4D nifti file (command: bxh2analyze --nii)
#   4) reorient that 4D nifti file into gross alignment with the MNI 152 template (command: fslreorient2std)


echo ""
echo ""
echo "############### DICOMs from series ${outputName} : ###############"
echo "LOCATION  : ${inputFolder}"
echo -n "FILE COUNT: "
ls -1 ${inputFolder} | wc -l
# should you want an interative mode: 
# echo "If that's the expected DICOM count for the series, hit "
# echo -n "Enter to continue. (or CTRL-C to quit)"
# read
echo "Creating .bxh metafile for series ${outputName}..."
echo ""
dicom2bxh ${inputFolder}/* ${outputParent}/${outputName}.bxh
echo ""
echo "...done."
echo ""
echo "Creating nifti volume for series ${outputName}..."
echo ""
bxh2analyze --nii -b -s ${outputParent}/${outputName}.bxh ${outputParent}/${outputName}
echo ""
echo "...done."
echo ""
echo "Reorienting series ${seriesName} nifti volume to match FSL's MNI 152 template..."
echo ""
fslreorient2std ${outputParent}/${outputName} ${outputParent}/${outputName}_MNI
echo ""
echo ""
echo "...done."
echo ""

ls -ltr ${outputParent}
echo ""


