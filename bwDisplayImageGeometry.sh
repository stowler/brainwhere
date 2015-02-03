#!/bin/sh
#
# LOCATION: 	   <location including filename>
# USAGE:          (see fxnPrintUsage() function below)
#
# CREATED:	      ???????? by stowler@gmail.com
# LAST UPDATED:	20140807 by stowler@gmail.com
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
#
# TBD:
# - create selftest to test against gold-standard output (images in $bwDir ? FEEDS data?)

# ------------------------- START: fxn definitions ------------------------- #

fxnPrintUsage() {
   #EDITME: customize for each script:
	echo >&2 "$0 - a script to do something"
	echo >&2 "Usage: scriptname [-r|-n] -v file {file2 ...}"
	echo >&2 "  -r   print data rows only (no column names)"
	echo >&2 "  -n   pring column names ONLY (no data rows)"
	echo >&2 "  -v   be verbose"
}


fxnSetTempDir(){
   # ${tempParent}: parent dir of ${tempDir}(s) where temp files will be stored
   # e.g. tempParent="${blindParent}/tempProcessing"
   # (If tempParent or tempDir needs to include blind, remember to assign value to $blind before calling!)
   # EDITME: $tempParent is something that might change on a per-system, per-script, or per-experiment basis:
   hostname=`hostname -s`
   kernel=`uname -s`
   if [ $hostname = "stowler-mbp" ]; then
      tempParent="/Users/stowler/temp"
   elif [ $kernel = "Linux" ] && [ -d /tmp ] && [ -w /tmp ]; then
      tempParent="/tmp"
   elif [ $kernel = "Darwin" ] && [ -d /tmp ] && [ -w /tmp ]; then
      tempParent="/tmp"
   else
      echo "Cannot find a suitable temp directory. Edit script's tempParent variable. Exiting."
      exit 1
   fi
   # e.g. tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   mkdir $tempDir
   if [ $? -ne 0 ] ; then
      echo ""
      echo "ERROR: unable to create temporary directory $tempDir"
      echo "Exiting."
      echo ""
      exit 1
   fi
}


fxnValidateInputImages() {
   invalidInputList=""
   for image in $@; do
      # is file a readable image?
      3dinfo $image &>/dev/null
      if [ "$?" -ne "0" ]; then
         invalidInputList="`echo ${invalidInputList} ${image}`"
      fi
   done
   if [ ! -z "${invalidInputList}" ]; then
      echo ""
      echo "ERROR: these input files do not exist or are not valid 3d/4d images per AFNI's 3dinfo. Exiting:"
      echo ""
      echo "${invalidInputList}"
      echo ""
      exit 1
   fi
}


# fxnCalc is also something I include in my .bash_profile:
# calc(){ awk "BEGIN{ print $* }" ;}
# use quotes if parens are included in your function call:
# calc "((3+(2^3)) * 34^2 / 9)-75.89"
fxnCalc() {
   awk "BEGIN{ print $* }" ;
}

# deprecated: TBD: rewrite using fxnCalc
#fxnPercentDiff ()
#{
#        sum=`/home/leonardlab/scripts/ucr/scriptbc -p 6 $1 + $2`
#        diff=`/home/leonardlab/scripts/ucr/scriptbc -p 6 $1 - $2`
#        avg=`/home/leonardlab/scripts/ucr/scriptbc -p 6 $sum / 2`
#        percentDiff=`/home/leonardlab/scripts/ucr/scriptbc -p 6 $diff / $avg`
#        percentDiff=`/home/leonardlab/scripts/ucr/scriptbc -p 2 $percentDiff \* 100`
#        echo "${percentDiff}"
#}

# ------------------------- FINISHED: fxn definitions ------------------------- #


# ------------------------- START: definitions and constants ------------------------- #

# first: anything related to command-line arguments:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# e.g. firstArgumentValue="$1"


# second: basic system resources:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
scriptName=`basename $0`		      # ...assign a constant here if not calling from a script
scriptPID="$$"				            # ...assign a constant here if not calling from a script
#scriptDir=""				            # ...used to get to other scripts in same directory
scriptUser=`whoami`			         # ...used in file and dir names
startDate=`date +%Y%m%d` 		      # ...used in file and dir names
startDateTime=`date +%Y%m%d%H%M%S`	# ...used in file and dir names
#cdMountPoint


# third: variables for filesystem locations, filenames, long arguments, etc.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# intensity="t1bfc0"			         # ...to be used in file and folder names
# orientation="radOrig"			      # ...ditto


# set image directories:

# ${blindParent}:
# parent dir where each subject's $blindDir reside (e.g. parent of blind1, blind2, etc.)
# e.g. blindParent="/home/leonardlab/images/ucr"
# e.g. allows mkdir ${blindParent}/importedSemiautoLatvens ${blindParent}/blind1

# ${blindDir}: 
# dir for each subject's images and image directories:
# e.g. blindDir="/home/leonardlab/images/ucr/${blind}"
# e.g. blindDir="${blindParent}/${blind}"

# ${origDir}: 
# dir or parent dir where original images will be stored (or are already stored if formatted)
# e.g. origDir="${blindDir}/acqVolumes"

# ${anatRoot}}:
# where the groomed images directory, among others, will live:
# e.g. anatRoot="${blindDir}/anat-${intensity}-${orientation}"

# ...source directories for input images:
# (script should copy images from these [probably poorly organized] source directories
# to $origDir
# e.g. sourceT1acqDir="/Users/Shared/cepRedux/acqVolumes"
# e.g. sourceLatvenDir="/Users/Shared/cepRedux/semiautoLatvens"
# e.g. sourceBrainDir="/Users/Shared/cepRedux/semiautoExtractedBrains"
# e.g. sourceFlairDir="/Users/Shared/libon-final/origOrientImageJ" 
# e.g. sourceWMHImaskDir="/Users/Shared/libon-final/masksOrientImageJ"  



# ...brainsuite09 paths and definitions:
#BSTPATH="/data/pricelab/scripts/sdt/brainsuite09/brainsuite09.x86_64-redhat-linux-gnu"
#BSTPATH="/Users/stowler/Downloads/brainsuite09.i386-apple-darwin9.0"
#export BSTPATH
#bstBin="${BSTPATH}/bin/"
#export bstBin
#ATLAS="${BSTPATH}/atlas/brainsuite.icbm452.lpi.v08a.img"
#export ATLAS
#ATLASLABELS="${BSTPATH}/atlas/brainsuite.icbm452.lpi.v09e3.label.img"
#export ATLASLABELS
#ATLASES="--atlas ${ATLAS} --atlaslabels ${ATLASLABELS}"
#export ATLASES

# ...FSL variables
# FSLDIR=""
# export FSLDIR
# FSLOUTPUTTYPEorig="${FSLOUTPUTTYPE}"
# export FSLOUTPUTTYPE=NIFTI_GZ


# ------------------------- FINISHED: definitions and constants ------------------------- #


# ------------------------- START: invocation ------------------------- #

# initialize any variables that may receive values during argument processing:
headingsoff=0
headingsonly=0

# argument processing with getopt:
set -- `getopt rn "$@"`
[ $# -lt 1 ] && exit 1	# getopt failed
while [ $# -gt 0 ]
do
    case "$1" in
      	   -r) headingsoff=1  ;;
	   -n) headingsonly=1 ;;
	   --)	shift; break  ;;
	   -*) echo >&2 "usage: $0 [-r for data row only or -n for column names only] image ..."; exit 1 ;;
	    *)	break ;; # terminate while loop
    esac
    shift
done
# now all command line switches have been processed, and "$@" contains all file names

# check for number of arguments
if [ $# -lt 1 ] ; then
   echo ""
	echo "ERROR: no files specified"
   echo ""
	fxnPrintUsage
   echo ""
	exit 1
fi

# check for incompatible invocation options:
if [ "$headingsoff" != "0" ] && [ "$headingsonly" != "0" ] ; then
   echo ""
	echo "ERROR: cannot specify both -r and -n:"
   echo ""
	fxnPrintUsage
   echo ""
	exit 1
fi

# ------------------------- FINISHED: invocation ------------------------- #



# ------------------------- START: body of program ------------------------- #

fxnSetTempDir                 # setup and create $tempDir if necessary
fxnValidateInputImages $@     # verify that all input images are actually images
# TBD: Verify that destination directories exist and are user-writable:

if [ ${headingsoff} -ne 1 ]; then 
   echo ""
   echo "4D ORIENTATION TILT VoxRL VoxAP VoxIS VoxSizeRL VoxSizeAP VoxSizeSI FILE" >> ${tempDir}/unformatted.txt
   echo "4D ORIENTATION TILT VoxRL VoxAP VoxIS VoxSizeRL VoxSizeAP VoxSizeSI FILE" >> ${tempDir}/unformatted_withFullPath.txt
fi

if [ ${headingsonly} -ne 1 ]; then
   for image in $@; do 
      #volsQty=`3dinfo "${image}" 2>/dev/null | grep "values stored at each pixel" | awk '{print $NF}'`
      volsQty=`3dAttribute -name DATASET_RANK "${image}" 2>/dev/null | awk '{print $4}'`
      orientation=`3dinfo "${image}" 2>/dev/null | grep "\[\-orient " | sed 's/^.*orient//' | sed 's/\]$//'`
      tilt=`3dinfo "${image}" 2>/dev/null | grep "Data Axes Tilt" | awk '{print $4}'`
      voxRL=`3dinfo "${image}" 2>/dev/null | grep R-to-L | sed 's/^.*mm//' | sed 's/^.*\[//' | sed 's/voxels\]$//'`
      voxAP=`3dinfo "${image}" 2>/dev/null | grep A-to-P | sed 's/^.*mm//' | sed 's/^.*\[//' | sed 's/voxels\]$//'`
      voxIS=`3dinfo "${image}" 2>/dev/null | grep I-to-S | sed 's/^.*mm//' | sed 's/^.*\[//' | sed 's/voxels\]$//'`
      pixdimRL=`3dinfo "${image}" 2>/dev/null | grep R-to-L | awk '{print $9 $10}'`
      pixdimAP=`3dinfo "${image}" 2>/dev/null | grep A-to-P | awk '{print $9 $10}'`
      pixdimIS=`3dinfo "${image}" 2>/dev/null | grep I-to-S | awk '{print $9 $10}'`
      imageShortName=`basename "${image}" 2>/dev/null`
      # would be nice to include COG (need to know that axes are relatively similar)
      echo "$volsQty $orientation $tilt $voxRL $voxAP $voxIS $pixdimRL $pixdimAP $pixdimIS ${imageShortName}" >> ${tempDir}/unformatted.txt 
      echo "$volsQty $orientation $tilt $voxRL $voxAP $voxIS $pixdimRL $pixdimAP $pixdimIS ${imageShortName}" >> ${tempDir}/unformatted_withFullPath.txt 
   done
fi

cat ${tempDir}/unformatted.txt | column -t

# ------------------------- FINISHED: body of program ------------------------- #


# ------------------------- START: say bye and restore environment ------------------------- #
rm -fr ${tempDir}
# echo ""
# echo "#################################################################"
# echo "FINISHED: \"${scriptName} ${1}\""
#       date
# echo "#################################################################"
# echo ""
# echo ""
# echo ""
# export FSLOUTPUTTYPE=${FSLOUTPUTTYPEorig}
# ------------------------- END: say bye and restore environment ------------------------- #
