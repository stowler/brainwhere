#!/bin/bash

# Launches fslview with two layers for inspecting simple skull-strip:
#
#  top layer:      grayscale user-provided image (skull-stripped image)
#  bottom layer:   light green user-provided image (not skull-stripped)


fxnLaunchFslview(){
   echo ""
   echo "Launching fslview with grey over green..."
   du -h $topLayer
   du -h $bottomLayer

   fslview -m ortho \
   ${bottomLayer} -l Green -t 0.8 \
   ${topLayer} -l Greyscale &
}


# set the top layer
topLayer=$1
# set the bottom layer:
bottomLayer=$2

fxnLaunchFslview
