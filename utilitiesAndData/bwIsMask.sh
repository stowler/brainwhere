#!/bin/sh

# bwIsMask.sh - make a good guess about whether input volume is a mask. Provide
# a little info about the mask values if appropriate.

# TBD: check whether input volume is a valid image
# TBD: check whether input volume contains only a single 3D volume
#inputImage=$1
inputImage=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz

# Find the max intensity:
max=`3dBrickStat -slow -max $inputImage`
# TBD: if non-integer, isMask_notLikely

# Calculate number of bins.
nbins=${max}
# ...allowing for a bin at intensity==0:
#nbins=$((max + 1))


# Create a list of non-zero intensities present in the image:
# NB: works because number of bins is equal to 1..maxIntensity
# NB: the awk '$2 != "0"' removes any intensities that have zero voxels in the 3dhostog histogram:
nzInt=`3dhistog \
-notitle \
-nbin ${nbins} \
-min 1 \
-max ${max} \
${inputImage} \
| awk '$2 != "0"' \
| awk '{print $1}'` 
#| sed ':a;N;$!ba;s/\n/ /g'

nzInt=`echo ${nzInt} | sed 's/\ /+/g'`

echo "isMask_multipleNZintensities${nzInt}"

