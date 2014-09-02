#!/bin/sh
#
# LOCATION: 	  brainwhereCommonFunctions.sh
# USAGE:         source brainwhereCommonFunctions.sh
#
# CREATED:	      	???????? by stowler@gmail.com
# LAST UPDATED:		20140902 by stowler@gmail.com
#
# DESCRIPTION:
# Common functions relied upon by brainwhere scripts.
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



