#!/bin/bash

# Launches fslview with three image layers in MNI1521mm space:
#
#  top (atlas) layer:      translucent Harvard-Oxford MNI atlas: either cortical or sucortical
#  middle layer:           MNI152 T1 skull-stripped (greyscale), or user-provided image
#  bottom layer:           MNI152 T1 not skull-stripped (light green)


fxnLaunchFslview(){

   du -h $atlasLayer
   du -h $middleLayer
   du -h $bottomLayer

   fslview -m ortho \
   ${bottomLayer} -l Green -t 0.3 \
   ${middleLayer} -l Greyscale \
   ${atlasLayer} -l ${atlasLUT} -t 0.5 &
}


fxnSetAtlasLayer(){
   # specify atlas and matching color look-up-table:
   case "$atlas" in 
      hoCortical)
         atlasLUT="MGH-Cortical"
         atlasLayer="$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz"
         ;;
      hoSubcortical)
         atlasLUT="MGH-Subcortical"
         atlasLayer="$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz"
         ;;
      *) break ;;
   esac
}


fxnSetMiddleLayer(){
   # If there wasn't a user-provided image then use the skull-stripped MNI152 1mm brain:
   middleLayer=$FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz #TBD: fail gracefully if doesn't exist
   # Else, if the user provided an image first check it for:
   # 1) whether it is a valid, readable image
   # 2) whether it is geometrically identical FSL's MNI image
}


fxnSetLayers(){
   # set the atlas layer:
   fxnSetAtlasLayer

   # set the middle layer:
   fxnSetMiddleLayer

   # set the bottom layer:
   bottomLayer=$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz
}


fxnMain(){
   fxnSetLayers
   fxnLaunchFslview
}

# set value of $atlas (hoCortial by default)
atlas="hoCortical"
#atlas="hoSubcortical"

fxnMain
