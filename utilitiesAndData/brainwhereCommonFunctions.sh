#!/bin/sh
#
# LOCATION: 	  stowlerIncludesForMRI.sh 
# USAGE:          (see fxnPrintUsage() function below)
#
# CREATED:	      	<date> by <whom>
# LAST UPDATED:		<date> by <whom>
#
# DESCRIPTION:
# <description of what the script does>
# 
# STYSTEM REQUIREMENTS:
#  - awk must be installed for fxnCalc
#   <list or describe others>
#
# INPUT FILES AND PERMISSIONS:
# <list or describe>
#
# OTHER ASSUMPTIONS:
# <list or describe>



# ------------------------- START: fxn definitions ------------------------- #

# fxnSetTempDir() {
#    # ${tempParent}: parent dir of ${tempDir}(s) where temp files will be stored
#    # e.g. tempParent="${blindParent}/tempProcessing"
#    # (If tempParent or tempDir needs to include blind, remember to assign value to $blind before calling!)
#    # EDITME: $tempParent is something that might change on a per-system, per-script, or per-experiment basis:
#    startDateTime=`date +%Y%m%d%H%M%S`      # ...used in file and dir names
#    hostname=`hostname -s`
#    kernel=`uname -s`
#    if [ $hostname = "stowler-mbp" ]; then
#       tempParent="/Users/stowler/temp"
#    elif [ $kernel = "Linux" ]; then
#       tempParent="${HOME}/temp"
#       mkdir ${tempParent} &>/dev/null                     #because not everyone will have a ~/temp to begin
#    elif [ $kernel = "Darwin" ] && [ -d /tmp ] && [ -w /tmp ]; then
#       tempParent="/tmp"
#    else
#       echo "Cannot find a suitable temp directory. Edit script's tempParent variable. Exiting."
#       exit 1
#    fi
#    # e.g. tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
#    tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
#    mkdir $tempDir
#    if [ $? -ne 0 ] ; then
#       echo ""
#       echo "ERROR: unable to create temporary directory $tempDir"
#       echo "Exiting."
#       echo ""
#       exit 1
#    fi
# }


fxnValidateImages() {
   # exists stats 1 if finds invalid or DNE images
   invalidImagesList=""
   for image in $@; do
      # is file a readable image?
      3dinfo $image &>/dev/null
      if [ "$?" -ne "0" ]; then
         invalidImagesList="`echo ${invalidImagesList} ${image}`"
      fi
   done
   if [ ! -z "${invalidImagesList}" ]; then
      echo ""
      echo "ERROR: these input files do not exist or are not valid 3d/4d images. Exiting:"
      echo ""
      echo "${invalidImagesList}"
      echo ""
      exit 1
   fi
}


fxnCalc() {
   # fxnCalc is also something I include in my .bash_profile:
   # calc(){ awk "BEGIN{ print $* }" ;}
   # use quotes if parens are included in your function call:
   # calc "((3+(2^3)) * 34^2 / 9)-75.89"
   awk "BEGIN{ print $* }" ;
}



# ------------------------- FINISHED: fxn definitions ------------------------- #



