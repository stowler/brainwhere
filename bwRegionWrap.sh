#!/bin/bash
#
# LOCATION:	      ${bwDir}/bwRegionWrap.sh
# USAGE:	         see the fxnPrintUsage() function below 
#
# CREATED:	      20130508 by stowler@gmail.com
# LAST UPDATED:	20130516 by stowler@gmail.com
#
# DESCRIPTION:
#
# Elaborates a single region-of-interest mask without referencing any other
# images (atlas, etc.). This produces an output directory containing
# consistently-named assets that can be used for visualization or further
# processing:
# - nifti and surface versions of:
#     - the region itself (in original intensity and bwRegionWrap standard intensity)
#     - a solid box surrounding the region (the six box edges intersect the spatial extrema of the ROI and stop there)
#     - a hollow box surrounding the region
#     - a sphere at the CoG that is ___ % of the __est box dimension
#     - planes extending the sides of the box (individual and together)
#     - a fusion image for debugging
# 
# 
# SYSTEM REQUIREMENTS:
#  - awk must be installed for fxnCalc
#   <EDITME: list or describe others>
#
# INPUT FILES AND PERMISSIONS FOR OUTPUT:
# <EDITME: list or describe>
#
# OTHER ASSUMPTIONS:
# <EDITME: list or describe>
#
#
# READING AND CODING NOTES:
# 
# This script contains a few first-level sections, each starting with one of these headings:
# ------------------------- START: define functions ------------------------- #
# ------------------------- START: define basic script constants ------------------------- #
# ------------------------- START: greet user/logs ------------------------- #
# ------------------------- START: body of script ------------------------- #
# ------------------------- START: restore environment and say bye to user/logs ------------------------- #
#
# Searchable keywords that mark areas of code:
# EDITME :  areas that should be edited on a per-system/script/experiment/whatever basis
# TBD :     areas where I have work to do, decisions to make, etc.
# DEBUG :   areas that I only intend to uncomment and execute duing debugging
#
# Lines starting with "###" (three hash marks) are marked as training material
# so they can be stripped out automatically
#
#



# ------------------------- START: define functions ------------------------- #



fxnPrintUsage() {
   # EDITME: customize for each script:
   echo >&2 "$0 - a script to do something. Example of a usage note:"
   echo >&2 "Usage: scriptname [-r|-n] -v file {file2 ...}"
   echo >&2 "  -r   print data rows only (no column names)"
   echo >&2 "  -n   pring column names ONLY (no data rows)"
   echo >&2 "  -v   be verbose"
}


fxnProcessInvocation() {

# always: check for number of arguments, even if expecting zero:
if [ "${scriptArgsCount}" -eq "0" ] ; then
   echo ""
   echo "No arguments provided...running self-test using sample data:"
   echo ""
   runSelftest=1
   echo ""
   #exit 1
fi


# when needed, process commandline arguments with getopt by removing
# COMMENTBLOCK wrapper and editing:

: <<'COMMENTBLOCK'
# STEP 1/3: initialize any variables that receive values during argument processing:
headingsoff=0
headingsonly=0
# STEP 2/3: set the getopt string:
set -- `getopt rn: "$@"`
# STEP 3/3: process command line switches in  a loop:
[ $# -lt 1 ] && exit 1	# getopt failed
while [ $# -gt 0 ]
do
    case "$1" in
      -r)   headingsoff=1
            ;;
      -n)	headingsonly=1
            ;;
      --)	shift; break
            ;;
      -*)
            echo >&2 "usage: $0 [-r for data row only or -n for column names only] image ..."
             exit 1
             ;;
       *)	break
            ;;		# terminate while loop
    esac
    shift
done
# now all command line switches have been processed, and "$@" contains all file names
# check for incompatible invocation options:
if [ "$headingsoff" != "0" ] && [ "$headingsonly" != "0" ] ; then
   echo ""
   echo "ERROR: cannot specify both -r and -n:"
   echo ""
   fxnPrintUsage
   echo ""
   exit 1
fi
COMMENTBLOCK
}


fxnSelftestBasic() {
   # Tests the basic funcions and variables of the template on which this
   # script is based. Valid output may appear as comment text at the bottom
   # of this script (TBD). This can be used to confirm that the basic functions
   # of the script are working on a particular system, or that they haven't
   # been broken by recent edits.

   echo "Running internal function fxnSelftestBasic :"
   echo ""

   # expose the basic constants defined in the script:
   echo "Some basic constants have been defined in this script."
   echo "Their names are listed in variable \${listOfBasicConstants} : "
   echo "${listOfBasicConstants}"
   echo ""
   #echo "...and here are their values:"
   #for scriptConstantName in ${listOfBasicConstants}; do
   #   scriptConstantValue="`echo ${scriptConstantName}`"
   #   echo "${scriptConstantName} == ${scriptConstantValue}"
   #done

   # test internal function fxnSetTempDir:
   if [ -z "${tempDir}" ]; then
      fxnSetTempDir
      deleteTempDirAtEndOfScript=0
   fi

   # Strip out all comments that are marked as training. This will create a
   # slimmer, more readable version of the script :
   trainingMarker='###'       # trainingMarker must be sed-friendly. See below:
   cp ${scriptDir}/${scriptName} ${tempDir}/script-orig.sh
   sed "/^${trainingMarker}/ d" ${tempDir}/script-orig.sh > ${tempDir}/script-withoutTrainingComments.sh
   linecountOrig="`wc -l ${tempDir}/script-orig.sh | awk '{print $1}'`"
   linecountSkinny="`wc -l ${tempDir}/script-withoutTrainingComments.sh | awk '{print $1}'`"
   echo ""
   echo "This script has ${linecountOrig} lines, and the version without training comments has ${linecountSkinny} lines:"
   echo ""
   ls -l ${tempDir}/*
}


fxnSelftestFull() {
  # Tests the full functions of the script.
  
  # first run the basic selftest:
  fxnSelftestBasic

  # set dummy inputs and outputs: then return control to script body for
  # processing per normal:
  atlas=${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
  extractedRegionIntensity=30
  regionInputFake=${tempDir}/fakeInputRegion_int${extractedRegionIntensity}
  fslmaths ${atlas} -uthr ${extractedRegionIntensity} -thr ${extractedRegionIntensity} ${regionInputFake} -odt char 
  regionInput=${regionInputFake}

  deleteTempDirAtEndOfScript=0

}


fxnCalc() {
   # fxnCalc is also something I include in my .bash_profile:
   # e.g., calc(){ awk "BEGIN{ print $* }" ;}
   # use quotes if parens are included in the function call:
   # e.g., calc "((3+(2^3)) * 34^2 / 9)-75.89"
   awk "BEGIN{ print $* }" ;
}


fxnSetTempDir() {
   # Attempt to create a temporary directory ${tempDir} .  It will be a child
   # of directory ${tempParent}, which may be set prior to calling this fxn, or
   # will be set to something sensible by this function.
   #
   # NB: ${tempParent} might need to change on a per-system, per-script, or per-experiment, basis
   #    If tempParent or tempDir needs to include identifying information from the script,
   #    remember to assign values before calling fxnSetTempDir !
   #    e.g., tempParent=${participantDirectory}/manyTempProcessingDirsForThisParticipant && fxnSetTempDir()

   # Is $tempParent already defined as a writable directory? If not, try to define a reasonable one:
   tempParentPrevouslySetToWritableDir=''
   hostname=`hostname -s`
   kernel=`uname -s`
   if [ -n "${tempParent}"] && [ -d "${tempParent}" ] && [ -w "${tempParent}" ]; then
      tempParentPreviouslySetToWritableDir=1
   elif [ $hostname = "stowler-mba" ]; then
      tempParent="/Users/stowler/temp"
   elif [ $kernel = "Linux" ] && [ -d /tmp ] && [ -w /tmp ]; then
      tempParent="/tmp"
   elif [ $kernel = "Darwin" ] && [ -d /tmp ] && [ -w /tmp ]; then
      tempParent="/tmp"
   else
      echo "fxnSetTempDir cannot find a suitable parent directory in which to \
	    create a new temporary directory. Edit script's $tempParent variable. Exiting."
      exit 1
   fi
   # echo "DEBUG"
   # echo "DEBUG: \${tempParent} is ${tempParent}"
   # echo "DEBUG:"

   # Now that writable ${tempParent} has been confirmed, create ${tempDir}:
   # e.g., tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   mkdir ${tempDir}
   if [ $? -ne 0 ] ; then
      echo ""
      echo "ERROR: fxnSetTempDir was unable to create temporary directory ${tempDir}."
      echo 'You may want to confirm the location and permissions of ${tempParent}, which is understood as:'
      echo "${tempParent}"
      echo ""
      echo "Exiting."
      echo ""
      exit 1
   fi
}


fxnSetMeaningfulConstants() {

# ${outParent} should be an existing directory, which will receive uniquely
# named new dir bwRegionFestooned-*:
# ${outDir} will be created in ${outParent} and populated with the new nifti images:
# outParent=
# outDir=

regionName=NoName
regionVer=NoVersion
# (or noName, NoVersion)

# define nifti files:
regionOrig=${tempDir}/${regionName}-ver${regionVer}-orig
region=${tempDir}/${regionName}-ver${regionVer}-roi
regionBox=${tempDir}/${regionName}-ver${regionVer}-box
regionPlanes=${tempDir}/${regionName}-ver${regionVer}-planes
regionEdge=${tempDir}/${regionName}-ver${regionVer}-edge
regionCenter=${tempDir}/${regionName}-ver${regionVer}-center

# …and these are the standard intensities that will be assigned to each of those masks:
# (staying > 50 to avoid interference with typical label values)
regionInt=100
regionBoxInt=75
regionPlanesInt=70
regionEdgeInt=60
regionCenterInt=65



	: <<'COMMENTBLOCK'
	   intensity="t1bfc0"			         # ...to be used in file and folder names
	   orientation="radOrig"			      # ...ditto

	   # set image directories:

	   # ${blindParent}:
	   # parent dir where each subject's $blindDir reside (e.g. parent of blind1, blind2, etc.)
	   # e.g., blindParent="/home/leonardlab/images/ucr"
	   # e.g., allows mkdir ${blindParent}/importedSemiautoLatvens ${blindParent}/blind1

	   # ${blindDir}: 
	   # dir for each subject's images and image directories:
	   # e.g., blindDir="/home/leonardlab/images/ucr/${blind}"
	   # e.g., blindDir="${blindParent}/${blind}"

	   # ${origDir}: 
	   # dir or parent dir where original images will be stored (or are already stored if formatted)
	   # e.g., origDir="${blindDir}/acqVolumes"

	   # ${anatRoot}}:
	   # where the groomed images directory, among others, will live:
	   # e.g., anatRoot="${blindDir}/anat-${intensity}-${orientation}"

	   # ...source directories for input images:
	   # (script should copy images from these [probably poorly organized] source directories
	   # to $origDir
	   # e.g., sourceT1acqDir="/Users/Shared/cepRedux/acqVolumes"
	   # e.g., sourceLatvenDir="/Users/Shared/cepRedux/semiautoLatvens"
	   # e.g., sourceBrainDir="/Users/Shared/cepRedux/semiautoExtractedBrains"
	   # e.g., sourceFlairDir="/Users/Shared/libon-final/origOrientImageJ" 
	   # e.g., sourceWMHImaskDir="/Users/Shared/libon-final/masksOrientImageJ"  

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
COMMENTBLOCK
}

# ------------------------- FINISHED: define functions ------------------------- #


# ------------------------- START: define basic script constants ------------------------- #


# NB: these are per-script constants, so it's safer to define them here rather
# than in an internal function.

listOfBasicConstants=''	

scriptName="`basename $0`"
listOfBasicConstants="\$scriptName ${listOfBasicConstants}"

scriptDir="`dirname $0`"
listOfBasicConstants="\$scriptDir ${listOfBasicConstants}"

scriptPID="$$"
listOfBasicConstants="\$scriptPID ${listOfBasicConstants}"

scriptArgsCount=$#
listOfBasicConstants="\$scriptArgsCount ${listOfBasicConstants}"

scriptUser="`whoami`"
listOfBasicConstants="\$scriptUser ${listOfBasicConstants}"

startDate="`date +%Y%m%d`"
listOfBasicConstants="\$startDate ${listOfBasicConstants}"

startDateTime="`date +%Y%m%d%H%M%S`"
listOfBasicConstants="\$startDateTime ${listOfBasicConstants}"

# echo "DEBUG: \${listOfBasicConstants} is:"
# echo "${listOfBasicConstants}"


# ------------------------- FINISH: define basic script constants ------------------------- #


# ------------------------- START: greet user/logs ------------------------- #
echo ""
echo ""
echo "#################################################################"
echo "START: \"${scriptName}\""
      date
echo "#################################################################"
echo ""
echo ""
# ------------------------- FINISHED: greet user/logs------------------------- #


# ------------------------- START: body of script ------------------------- #

fxnSetTempDir                 # <- use internal function to create ${tempDir}
deleteTempDirAtEndOfScript=1  # <- set to 1 to delete ${tempDir} or 0 to leave it. See end of script.
fxnProcessInvocation          # <- manage command-line arguments

# If this is a self-test (per invocation), run internal fxnSelftestFull, which
# sets dummy i/o values and then returns control to script body for execution
# per normal:
if  [ $runSelftest = 1 ]; then fxnSelftestFull; fi

fxnSetMeaningfulConstants

# confirm that the input file has just two values: zero and a single mask intensity:
# (doing this first so intensity can be used in fire/directory naming below)
regionOrigIntensity=`fslstats ${regionInput} -M | sed 's/\..*$//g'`


# cp input region to ${regionOrig}:
imcp ${regionInput} ${regionOrig}
imtest ${regionOrig}
 
# create ${region} from input, with new mask value ${regionInt}:
fslmaths ${regionOrig} -bin -mul ${regionInt} ${region} -odt char
fslstats ${region} -M | sed 's/\..*$//g'

 # parse the fslstats voxel-based description of $region bounding box:
 # i.e., -w           : output smallest ROI <xmin> <xsize> <ymin> <ysize> <zmin> <zsize> <tmin> <tsize> containing nonzero voxels
 # xmin, ymin, and zmin are inclusive and indexed from zero, per visual inspection in fslview
 # corresponding coordinate for xmax = xmin + xsize -1
 boundingBoxFSLdesc=`fslstats ${region} -w`
 # echo "DEBUG $boundingBoxFSLdesc"
 # Parse the fslstats output of the spatial extrema:
 xmin=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 1`
 ymin=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 3`
 zmin=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 5`
 xsize=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 2`
 ysize=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 4`
 zsize=`echo ${boundingBoxFSLdesc} | cut -d ' ' -f 6`
 #…then calculate xmax, ymax, and zmax:
 xmax=`echo $xmin + $xsize -1 | bc`
 ymax=`echo $ymin + $ysize -1 | bc`
 zmax=`echo $zmin + $zsize -1 | bc`



# Create $regionBox from $region, with new mask value $regionBoxInt 
# 
# Edges of the box should match the R/L, A/P, and S/I extrema of the ${region} .
# Using fslmaths, which accepts a box roi description in the same way that "fslstats -w" provided it:
# "-roi <xmin> <xsize> <ymin> <ysize> <zmin> <zsize> <tmin> <tsize> : zero outside roi (using voxel coordinates).
#  Inputting -1 for a size will set it to the full image extent for that dimension. "
fslmaths ${region} -mul 0 -add ${regionBoxInt} -roi ${boundingBoxFSLdesc} ${regionBox} -odt char
fslstats ${regionBox} -M | sed 's/\..*$//g'

# create $regionPlanes from $region, with new mask value $regionPlanesInt :
#
# step 1/3: these are the filenames to store the temporary planes:
planeXmin=${tempDir}/plane_xmin
planeYmin=${tempDir}/plane_ymin
planeZmin=${tempDir}/plane_zmin
planeXmax=${tempDir}/plane_xmax
planeYmax=${tempDir}/plane_ymax
planeZmax=${tempDir}/plane_zmax
# step 2/3: and now create those planes:
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi ${xmin} 1 0 -1 0 -1 0 1 ${planeXmin} -odt char
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi ${xmax} 1 0 -1 0 -1 0 1 ${planeXmax} -odt char
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi 0 -1 ${ymin} 1 0 -1 0 1 ${planeYmin} -odt char
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi 0 -1 ${ymax} 1 0 -1 0 1 ${planeYmax} -odt char
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi 0 -1 0 -1 ${zmin} 1 0 1 ${planeZmin} -odt char
fslmaths ${region} -mul 0 -add ${regionPlanesInt} -roi 0 -1 0 -1 ${zmax} 1 0 1 ${planeZmax} -odt char
# step 3/3: create a ${regionPlanes} plane-only image:
fslmaths  ${planeXmin} -max ${planeYmin} -max ${planeZmin} -max ${planeXmax} -max ${planeYmax} -max ${planeZmax} ${regionPlanes} -odt char
fslstats ${regionPlanes} -M | sed 's/\..*$//g'

# create sphere $regionCenter from $region, with new mask value $regionCenterInt :
# …first define location and size:
sphereRadiusMM=3
cogCoordVoxelsUnrounded="89 89 101"
cogCoordVoxelsRounded="89 89 101"
cogCoordVoxelsX=`echo ${cogCoordVoxelsRounded} | cut -d ' ' -f 1`
cogCoordVoxelsY=`echo ${cogCoordVoxelsRounded} | cut -d ' ' -f 2`
cogCoordVoxelsZ=`echo ${cogCoordVoxelsRounded} | cut -d ' ' -f 3`
echo "DEBUG: cogCoordVoxelsX=${cogCoordVoxelsX} , cogCoordVoxelsY=${cogCoordVoxelsY} , cogCoordVoxelsZ=${cogCoordVoxelsZ} "
# …then create a point at the cog:
fslmaths ${region} -mul 0 -add 1 -roi ${cogCoordVoxelsX} 1 ${cogCoordVoxelsY} 1 ${cogCoordVoxelsZ} 1 0 1 ${tempDir}/cogPoint -odt float
# …then convolve:
fslmaths ${tempDir}/cogPoint -kernel sphere ${sphereRadiusMM} -fmean -bin -mul ${regionCenterInt} ${tempDir}/sphere -odt char


# ...and optionally multiply that by something decorative like a grid. Via fslmaths:
# -grid <value> <spacing> : add a 3D grid of intensity <value> with grid spacing <spacing>
# gridValue=1
# gridSpacing=3
# gridFile=${tempDir}/grid_value${gridValue}_spacing${gridSpacing}
# regionPlanesGrid=${outDir}/${regionName}-ver${regionVer}-planesGrid
# fslmaths ${region} -mul 0 -grid ${gridValue} ${gridSpacing} ${gridFile} -odt char 
# fslmaths ${regionPlanes} -mul ${gridFile} ${regionPlanesGrid} -odt char 

# DEBUG: create an image for checking result:
debugFakeFusionImage=~/temp/debugFakeFusionImage
fslmaths ${region} -max ${regionBox} -max ${regionPlanes}  $debugFakeFusionImage -odt char
fslview $debugFakeFusionImage -l Random-Rainbow


: <<'COMMENTBLOCK'
echo ""
echo ""
echo "================================================================="
echo "START: do some stuff EDITME"
echo "(should take about EDITME minutes)"
      date
echo "================================================================="
echo ""
echo ""

echo "(EDITME) If this line weren't just a placeholder in the template I'd be executing some useful commmands here."

echo ""
echo ""
echo "================================================================="
echo "FINISHED: did some stuff EDITME "
      date
echo "================================================================="
echo ""
echo ""
COMMENTBLOCK


# move output to $outDir, but only if this wasn't a selftest:
# (selftest output will just stay in tempDir)

# ------------------------- FINISHED: body of script ------------------------- #


# ------------------------- START: restore environment and say bye to user/logs ------------------------- #
#
# Output some final status info to the user/log and clean-up any resources.

# If a ${tempDir} was defined, remind the user about it and (optionally) delete it:
if [ -n "${tempDir}" ]; then 
	tempDirSize=`du -sh | cut -d ' ' -f 1`
	tempDirFileCount=`find ${tempDir} | wc -l`
	echo ""
	echo ""
	echo "This script's temporary directory is ${tempDir}"
	echo "...and it contains: ${tempDirFileCount} files and folders taking up total disk space of ${tempDirSize}"
	ls -ld ${tempDir}
	echo ""
	# if previously indicated, delete $tempDir
	if [ ${deleteTempDirAtEndOfScript} = "1" ]; then
		echo -n "...which I am now removing..."
		rm -fr ${tempDir}
		echo "done." 
      echo "Proof of removal per \"ls -ld \${tempDir}\" :"
		ls -ld ${tempDir}
	fi
	echo ""
	echo ""
fi

# Did we change any environmental variables? It would be polite to set them to their original values:
# export FSLOUTPUTTYPE=${FSLOUTPUTTYPEorig}

echo ""
echo ""
echo "#################################################################"
echo "FINISHED: \"${scriptName}\""
      date
echo "#################################################################"
echo ""
echo ""
# ------------------------- FINISHED: restore environment and say bye to user/logs ------------------------- #



: <<'COMMENTBLOCK'
Design notes:

- interactive mode: display results in GUI
- debug mode: create multiple versions of everything (i.e. *-FSL *-AFNI . Can help test installed software)
- consistant intensity value / LUT entry for each volume/surface generated
- each output generated should have a volume and surface version


bwRegionReporter calls bwRegionWrap if input region isn't already regionWrapped
bwRegionReporter calls bwRegionIntsersectWithMset over a standard set of atlas to aid reporting
(should bwRegionWrap also call bwRegionIntersectWithMset so that some minimal context is present in the regionWrapped output even if bwRegionReporter is never called?)


Add to bw documentation: 
- fxns (scripts?) and corresponding output directories: 
     fxn_bwRegionIntersectWithMset           and its output directory regionIntersectedWithMset-${regionName}-${msetName}
               - account for: noOutDir, noNameRegion, noNameMset
                    fxn_bwRegionWrap                              and its output directory regionWrapped-${regionName}


COMMENTBLOCK
