#!/bin/bash
#
# created: 20130724 by stowler@gmail.com
# edited:  20140731 by stowler@gmail.com
#
# This is a short script to illustrate quality control (qc) and conversion of
# Hackney OMT NIFTI data.  
# - It is currently designed for FMRI runs from a single session of scanning
#   (i.e., one trip to the scanner, or one "study"). 
# - It is not written to accept commandline arguments. Instead, make a copy of
#   the script and edit the information specific to your particpant, session, and
#   sequences.
# !!!!!!!!!!!!!!!!!!!
# - NB: very quickly adapted from original form, which was designed to receive
# DICOM inputs, to this form, which handles NIFTI inputs. You'll notice that I
# didn't bother to change the DICOM nomenclature, as this was a quick and dirty
# adaptation.
# !!!!!!!!!!!!!!!!!!!

clear

#############################################################################
# STEP 0: Assign values to variables that will be used in output file names:
# e.g., 
#   participant=CDA100
#   session=pre
#   sequences=fmriCategoryMemberGen
#
projectName=FBIRNTEST
participant=FT
session=afniTest
sequences=task


#############################################################################
# STEP 1: Create the variable ${tempDir} , and assign to it the full path of a
# temporary output directory in which we'll inspect output
#
# Details: We'll start by deleting any existing version of this directory, and
# the recreating it. That avoids accidentally mixing old aborted data with your
# current QC data.
#
# e.g., tempDir=/tmp/qc-nocera-CDA100-pre-namingruns
#
tempDir=/tmp/qcOMT-${participant}-${session}-${sequences}
rm -fr ${tempDir}
mkdir ${tempDir}


#############################################################################
# STEP 2: Create the variable ${dicomParentDir}
#
# Details: Create the variable ${dicomParentDir} and assign to it the full path
# of the parent folder that contains DICOM folders for each of the series in
# this session:
#
# e.g., dicomParentDir=/data/birc/Atlanta/DICOMreceivers/DICOMSTORE_viaRamaOnly/CDA100/MR/20130624/084914.000000/1
#
dicomParentDir=$bwDir/utilitiesAndData/imagesFromAFNI


#############################################################################
# STEP 3: Create the variable ${fmriSeriesList}, and assign its value: a
# space-separated list of the FMRI series you are about to QC.  
#
# Details: Per the configuration of our dicom store, DICOMs for individual
# series are stored in folders named according to series number.
# For example, the DICOM files of a hypothetical series number 3 (the third
# series eported from the MRI console), are contained in a folder named "3",
# which is a child of ${dicomParentDir}, which you defined in the previous
# step. 
#
# Note: The scanner console creates this numbering when it exports the data, so
# this is different numbering than, for example, the list "1 2 3 4 5 6" which
# codes what you will later call run1-run6.
#
# e.g., fmriSeriesList="4 5 6 7 8 9"
#

fmriSeriesList="FT_epi_r1 FT_epi_r2 FT_epi_r3"


#############################################################################
# STEP 4: For each FMRI series, do four things:
#
#   1) count the number of DICOM files for your manual verification (command: ls -1 | wc -l)
#   2) create a .bxh file containing the series' metadata (command: dicom2bxh)
#   3) create a 4D nifti file (command: bxh2analyze --nii)
#   4) reorient that 4D nifti file into gross alignment with the MNI 152 template (command: fslreorient2std)
#

echo ""
echo ""
echo ""
for seriesNumber in ${fmriSeriesList}; do
      echo ""
      echo "Creating .bxh metafile for series ${dicomParentDir}/${seriesNumber}..."
      echo ""
      analyze2bxh ${dicomParentDir}/${seriesNumber}.nii.gz ${tempDir}/fmriSeries.${seriesNumber}.bxh
      echo ""
      echo "...done."
      echo ""
      echo "Creating nifti volume for series ${seriesNumber}..."
      echo ""
      bxh2analyze --nii -b -s ${tempDir}/fmriSeries.${seriesNumber}.bxh ${tempDir}/fmriSeries.${seriesNumber}
      echo ""
      echo "...done."
      echo ""
      echo "Reorienting series ${seriesNumber} nifti volume to match FSL's MNI 152 template..."
      echo ""
      fslreorient2std ${tempDir}/fmriSeries.${seriesNumber}.nii ${tempDir}/fmriSeries.${seriesNumber}_MNI
      echo ""
      echo "...done."
      echo ""
done

ls -lh ${tempDir}
echo ""


#############################################################################
# STEP 5: Inspect 4D images using FSLVIEW before moving on to generating the
# intensity QC reports.
#
echo ""
echo "Now opening fslview to confirm that each reoriented _MNI volume has"
echo "orientation consistent with the MNI152 template..."
fslview ${tempDir}/*_MNI* &

echo ""
echo "If you are happy with what you seen in fslview, hit "
echo -n "Enter to continue. (or CTRL-C to quit)"
read


#############################################################################
# STEP 6: Execute FBIRN's fmriqa_generate.pl to generate the QC report for these
# runs:
#
echo ""
echo "Creating QC report for series ${fmriSeriesList}:"
echo ""
# ...first we make a list of bxh files ordered according to their appearance in the ${fmriSeriesList} defined above:
orderedListBXH=''
for seriesNumber in ${fmriSeriesList}; do
        orderedListBXH="${orderedListBXH} ${tempDir}/fmriSeries.${seriesNumber}.bxh "
done
# ...and then we execute the command that creates qc report:
qcReportOutDir=${tempDir}/qcReport-FBIRN
# ...don't mkdir: the fmriqa_generate.pl command will create it.
fmriqa_generate.pl ${orderedListBXH} ${qcReportOutDir}
echo ""
echo "...done."
echo ""


#############################################################################
# STEP 7: cleaning up
#
echo "To inspect the QC report just point your web browser at file://${qcReportOutDir}/index.html"
echo ""
echo "If you are happy with the conversion and QC results, copy the output files"
echo "from the temporary ${tempDir} to your project folder. "
echo "Something like:"
echo ""

echo "mkdir -p /data/birc/Atlanta/${projectName}/06.acqfiles/${participant}/${session}/${sequences}"
echo "mkdir -p /data/birc/Atlanta/${projectName}/08.QC/${participant}/${session}/${sequences}"
echo "cp ${tempDir}/*.nii* /data/birc/Atlanta/${projectName}/06.acqfiles/${participant}/${session}/${sequences}"
echo "cp ${tempDir}/*.bxh  /data/birc/Atlanta/${projectName}/06.acqfiles/${participant}/${session}/${sequences}"
echo "cp -r ${qcReportOutDir} /data/birc/Atlanta/${projectName}/08.QC/${participant}/${session}/${sequences}"
echo ""
echo "...then the last step is for you to delete your temporary directory ${tempDir} ."
echo ""
du -sh ${tempDir}
#tree -L 1 ${tempDir}
echo ""
echo ""
                       
