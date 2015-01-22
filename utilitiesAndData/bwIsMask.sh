#!/bin/sh

# bwIsMask.sh - make a good guess about whether input volume is a mask. Provide
# a little info about the mask values if appropriate.

###################################################################
# Input image to test:
###################################################################
#inputImage=$1
#
# ...or, this is a good mask test image for char-formatted niftis:
#inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
# ...or, this is good mask test image for float-formatted niftis:
#inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz
# ...or, this is a good non-mask INT16 test image:
#inputImage=$FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz
# ...or, this is a good non-mask UINT8 test image:
inputImage=$FSLDIR/data/standard/MNI152_T1_2mm_LR-masked.nii.gz

# TBD: check whether input volume is a valid image

# TBD: use afni check whether input volume contains only a single 3D volume, or
# was provided as an index to a single volume in a 4D file


###################################################################
# List unique intensities:
###################################################################

# The following 3dmaskdump solution (and similar 3dmaskave -dump) is slower
# than 3dhistog, but it isn't broken by float-formatted niftis as 3dhistog is:
# 
nzIntensitiesColumn=`3dmaskdump -quiet -noijk -nozero ${inputImage} 2>/dev/null | sort -n | uniq`
# ...which has line breaks:
#echo "${nzIntensities}"
# ...replaced by commas here:
nzIntensitiesCsv=`echo ${nzIntensitiesColumn} | sed 's/\ /,/g'`
echo "nzIntensitiesCsv == ${nzIntensitiesCsv}"
# ...replaced by spaces here:
nzIntensitiesTsv=`echo ${nzIntensitiesCsv} | sed 's/\,/\ /g'`
echo "nzIntensitiesTsv == ${nzIntensitiesTsv}"



###################################################################
# Test: Is the image free of non-integer intensities?
###################################################################
# isMask_notLikely

# Characteristics of integer-only mask volumes
# - fast but maybe not sensitive: are min, max, median whole numbers?
# - slower: do any of the dumped values contain a "." or "," ?
# - slower?: arithemtic check to see whether each value is an integer (bash test?) , i.e,:
#          if ! [ "$intensity" -eq "$intensity" ] 2> /dev/null
#          then
#              echo ""
#          fi
#     ...per http://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html and http://unix.stackexchange.com/questions/151654/checking-if-an-input-number-is-an-integer


###################################################################
# Test: Do we have 255 or more unique nz intensities? Probably not a mask.
###################################################################
# TBD: test



###################################################################
# Test: Is max intensity > 255? If so, could be a mask but will need to warn in output:
###################################################################
# TBD: test




###################################################################
# Now that we've rulled out non-integer and too-large intensities, create a
# list of non-zero intensities present in the image:
###################################################################

# TBD: test to see whether the number of nz intensities is 1 or > 1

# output some indicator of the intensities present and their quantity:
nzIntensitiesFileNameFriendly=`echo ${nzIntensitiesColumn} | sed 's/\ /+/g'`
echo "isMask_multipleNZintensities${nzIntensitiesFileNameFriendly}"







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

