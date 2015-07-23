#!/bin/sh

# bwMaskInfo.sh

# INPUT:
# A single 3D NIFTI mask.
#
# OUTPUT:
# If input image is a mask, print to stdout the number of mask intensities and a
# space-separated list of intensities.
# 
# If input image is not a mask, print to std out a message about why it isn't a
# mask (decimal intensities, or too many integer intensities).
#
# TBD: allow arguments:
#
# (no arguments)  : print to stdout: number of unique mask intensities, or message about it not being a mask
# -q              : quiet: count 3D mask's intensities, output value between 0 (not a mask) and 255 (number of unique mask intensities)
# -v              : list mask values found in image (space-seperated)
# -4              : perform above for every 3D volume in 4D input image, output one row per 3D volume
#


# TBD: check whether input volume is a valid nifti image

# TBD: allow AFNI BRIK/HEAD as input

# TBD: use afni to check whether input volume contains only a single 3D volume, or
# was provided as an index to a single volume in a 4D image.



fxnParseNzIntensities(){
   ###################################################################
   # Identify and summarize unique intensities:
   ###################################################################

   # Create a sorted column of unique nonzero intensities present in the image:
   nzIntensitiesColumn=`3dmaskdump -quiet -noijk -nozero ${inputImage} 2>/dev/null | sort -n | uniq`

   # ...replacing line breaks with commas:
   nzIntensitiesCsv=`echo ${nzIntensitiesColumn} | sed 's/\ /,/g'`
   #echo "nzIntensitiesCsv == ${nzIntensitiesCsv}"

   # ...replacing commas with spaces:
   nzIntensitiesSsv=`echo ${nzIntensitiesCsv} | sed 's/\,/\ /g'`
   #echo "nzIntensitiesSsv == ${nzIntensitiesSsv}"

   # Count total number of unique nz intensities:
   nzIntensitiesCount=`echo "${nzIntensitiesColumn}" | wc -l | sed 's/[ ^I]//g'`
   #echo "nzIntensitiesCount == ${nzIntensitiesCount}"

   # NB: the above 3dmaskdump solution (and similar 3dmaskave -dump) is slower
   # than 3dhistog, but it tolerates float-formatted niftis (unlike 3dhistog)
   # see comment at bottom of script for deprecated 3dhistog solution


   ###################################################################
   # Count the number of non-integer intensities present in the image
   ###################################################################
   #
   # Curently using a bash-ism to check whether each intensity is an integer, i.e,:
   #          if ! [ "$intensity" -eq "$intensity" ] 2> /dev/null
   #          then
   #              echo "not an integer"
   #          fi
   #     ...per http://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html 
   #        and http://unix.stackexchange.com/questions/151654/checking-if-an-input-number-is-an-integer


   decimalIntensitiesCount=0
   for intensity in $nzIntensitiesSsv; do 
      if ! [ "$intensity" -eq "$intensity" ] 2> /dev/null; then
         let "decimalIntensitiesCount++"
      fi
   done
   #echo "decimalIntensitiesCount == ${decimalIntensitiesCount}"

   # TBD: calcuate min, max (other?)
}



fxnMaskOrNot(){
   # assume image is mask, then test for condtions that might suggest otherwise:
   isMask=1
   maskMessage="" 
   # Does the input image contain decimal intensities?
   if [ $decimalIntensitiesCount -gt 0 ]; then
      maskMessage="\n- Input image contains decimal intensities (counted $decimalIntensitiesCount). "
      isMask=0
   fi
   # Does the input image contain more than 250 non-zero intensities?
   if [ $nzIntensitiesCount -gt 250 ]; then
      maskMessage="${maskMessage}\n- Input image contains more than 250 unique intensities (counted $nzIntensitiesCount). "
      isMask=0
   fi
   # TBD: Does input image contain intensities > 255 ?

   if [ $isMask -ne 1  ]; then
      #maskMessage="Input image probably isn't a mask for the following reason(s): ${maskMessage}"
      maskMessage="----- NOT MASK: -----\nInput image contains ${nzIntensitiesCount} unique intensities, and probably is NOT a mask because: ${maskMessage}"
   else
      #maskMessage="Input image appears to be a mask with ${nzIntensitiesCount} unique intensities."
      maskMessage="----- MASK: -----\nInput image contains ${nzIntensitiesCount} unique intensities, and DOES appear to be a mask\n(i.e., a reasonable number of integer intensities, and no decimal intensities)."
   fi
}



fxnSummaryVerbose(){
   echo
   ls -alh $inputImage
   fslinfo $inputImage | grep data_type
   echo "Analyzing intensities...\c"
   fxnParseNzIntensities $inputImage
   fxnMaskOrNot ${inputImage}
   echo "done."
   echo ${maskMessage}  #...value depends on results of fxnMaskOrNot
   #echo "decimalIntensitiesCount == ${decimalIntensitiesCount}"
   #echo "nzIntensitiesCount == $nzIntensitiesCount"
   # Let's truncate output if we have too many values:
   if [ $nzIntensitiesCount -gt 250 ]; then
      nzIntensitiesSsvLow=`echo $nzIntensitiesSsv | cut -d " " -f 1-10`
      nzIntensitiesSsv="$nzIntensitiesSsvLow ...snip..."
   fi
   echo "Non-zero intensities: $nzIntensitiesSsv"
   echo
}



fxnSelfTest(){
   echo
   echo "SELF-TESTS:"
   echo "1. masks (e.g., a few intensities, only integers)"
   echo "2. non-masks with only integer intensities"
   echo "3. non-masks with decimal intensities"
   echo
   echo "###################################################################"
   echo "1 of 3: SELF-TEST OF MASKS:"
   echo "###################################################################"
   echo 

   echo "\nThis 3D UINT8 (char) nifti mask should contain 48 non-zero integer intensities:"
   inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
   fxnSummaryVerbose

   echo "\nThis 3D FLOAT32 nifti mask should contain 21 non-zero integer intensities:"
   inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz
   fxnSummaryVerbose

   echo
   echo "###################################################################"
   echo "2 of 3: SELF-TEST OF NON-MASKS WITH ONLY INTEGER INTENSITIES:"
   echo "###################################################################"
   echo 

   echo "\nThis 3D UINT8 (char) nifti non-mask should contain 255 non-zero integer intensities:"
   inputImage=$FSLDIR/data/standard/MNI152_T1_2mm_LR-masked.nii.gz
   fxnSummaryVerbose

   echo "\nThis 3D INT16 nifti non-mask should contain 6187 non-zero integer intensities:"
   inputImage=$FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz
   fxnSummaryVerbose

   echo 
   echo "###################################################################"
   echo "3 of 3: SELF-TEST OF NON-MASKS THAT INCLUDE DECIMAL INTENSITIES:"
   echo "###################################################################"
   echo 

   echo "\nThis 3D FLOAT32 nifti non-mask should contain 21 non-zero intensities, 14 of which are decimals:"
   fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz -div 3 ${HOME}/testDiv3.nii.gz -odt float
   inputImage=${HOME}/testDiv3.nii.gz
   fxnSummaryVerbose

   echo "\nThis 3D FLOAT32 nifti non-mask should contain 6187 non-zero integer intensities, 4121 of which are decimals:"
   fslmaths $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz -div 3 ${HOME}/testDiv3.nii.gz -odt float
   inputImage=${HOME}/testDiv3.nii.gz
   fxnSummaryVerbose
}



main(){
   fxnSummaryVerbose
}

# uncomment EITHER fxnSelfTest OR inputImage + main:

#fxnSelfTest
inputImage=$1
main


###################################################################
###################################################################
###################################################################
###################################################################
###################################################################
###################################################################
###################################################################
# DEPRECATED: The following 3dhistog solution is fast, but doesn't work for
# float-formatted images due to a 3dhistog bug:
#
# NB: the awk '$2 != "0"' removes any intensities that have zero voxels in the 3dhistog histogram:
#     
#     
#     # Find the max intensity:
#     max=`3dBrickStat -slow -max $inputImage`
#     echo ""
#     echo "max==$max"
#     echo ""
#     
#     # Calculate number of bins.
#     nbins=${max}
#     # ...allowing for a bin at intensity==0:
#     #nbins=$((max + 1))
#     echo ""
#     echo "nbins==$nbins"
#     echo ""
#     
#     nzInt=`3dhistog \
#     -notitle \
#     -nbin ${nbins} \
#     -min 1 \
#     -max ${max} \
#     ${inputImage} \
#     | awk '$2 != "0"' \
#     | awk '{print $1}'` 
#     #| sed ':a;N;$!ba;s/\n/ /g'
#     nzInt=`echo ${nzInt} | sed 's/\ /+/g'`
#     

