#!/bin/sh

# bwMaskInfo

# TBD: allow arguments:
#
# (no arguments)  : count 3D mask's intensities, output value between 0 (not a mask) and 254 (number of unique mask intensities)
# -v              : list mask values found in image (space-seperated)
# -4              : perform above for every 3D volume in 4D input file, output one row per 3D volume


###################################################################
# Input image to test:
###################################################################
#inputImage=$1
#
# ...or, this is a good mask test image for char-formatted niftis (UINT8):
#inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
# ...or, this is good mask test image for FLOAT32-formatted niftis:
#inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz
# ...or, this is good non-mask test image for FLOAT32-formatted niftis containing non-integer intensities:
#     (from fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz -div 3 ~/testDiv3.nii.gz -odt float)
inputImage=~/testDiv3.nii.gz
# ...or, this is a good non-mask INT16 test image:
#inputImage=$FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz
# ...or, this is a good non-mask UINT8 test image:
#inputImage=$FSLDIR/data/standard/MNI152_T1_2mm_LR-masked.nii.gz
#

# TBD: check whether input volume is a valid image

# TBD: use afni to check whether input volume contains only a single 3D volume, or
# was provided as an index to a single volume in a 4D file


###################################################################
# Find unique intensities:
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
nzIntensitiesCount=`echo "${nzIntensitiesColumn}" | wc -l`
#echo "nzIntensitiesCount == ${nzIntensitiesCount}"

# NB: the above 3dmaskdump solution (and similar 3dmaskave -dump) is slower
# than 3dhistog, but it tolerates float-formatted niftis (unlike 3dhistog)



###################################################################
# Test: Is the image free of non-integer intensities?
###################################################################

# Curently using a bash-ism to see whether each value is an integer, i.e,:
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

# if decimalIntensitiesCount > 0, output "0" and exit script


###################################################################
# Test: Do we have 255 or more unique nz intensities? Probably not a mask.
###################################################################
# TBD: test



###################################################################
# Test: Is max intensity > 255? If so, could be a mask but will need to warn in output:
###################################################################
# TBD: test





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

