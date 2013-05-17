#!/bin/bash
#
# LOCATION:	    ${bwDir}/bwCompareAcrossLevelsOfOneFactor.sh
# USAGE:	    see the fxnPrintUsage() function below 
#
# CREATED:          20130516 by stowler@gmail.com
# LAST UPDATED:     20130516 by stowler@gmail.com
#
# DESCRIPTION:
# A very general tool. Loops across levels of one factor. Each loop iteration
# runs one script and produces one file containing one vector of results per
# level. Level-wise vectors are then catenated into a formatted text file for
# external comparison across levels. 
# 
# SYSTEM REQUIREMENTS:
#
# INPUT FILES AND PERMISSIONS FOR OUTPUT:
#
# INPUT:
# - argument factorName (to be used in filenaming)
# - argument levelNameList (a vector of factorLevels)
# - argument levelScript (a script to run for each level; accepts argument factorLevel)
#	- script should put all data into a subdir called "levelOutputRaw"
#	- script should create a level-wise 
#
# OTHER ASSUMPTIONS:
# - levelScript should accept as an argument a single factorLevel extracted
#   from this script's vector of factorLevels and use it to perform internal
#   functions
# - output of levelScript should only be two objects:
#	1) a subdirectory called levelOutputRaw
#	2) a sibling text file called levelOutputVectorForComparisonAcrossLevels.txt
# - TBD: would be helpful to have a template levelScript to aid consistancy 
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
cat <<EOF
$0 - a general tool for running an external script across multiple levels of a single factor
Usage: $0 \ 
  -f   [your factorName, which will just be used in output filenames.]
  -l   [your levelNames for levels of the factor: a comma-separated list WITH NO SPACES]
  -s   [your levelwise script, to be executed for each level of the factor]

When executed, your levelwise script is called once for each of the levels you
provided in the csv -l list. Each time through the loop, one of your levelNames
is provided as an argument to your levelwise script.

E.g., $0 -f mySystemFolders -l etc,var,tmp -s calculateFolderSize.sh 

The output of this script is a single new output directory containing per-level
subdirectories and a structured text file containing one row of data per factor
level, and a header row at the top. 

For this to work, your levelwise script (-s scriptName) needs to produce output
in this loose format:

1) All output files from a single run of your levelwise script should be in a
   folder called "levelOutputRaw"
2) The only thing outside of levelOutputRaw should be a sibling text file
   called singleLevelOutputVectorForComparisonAcrossLevels.txt . This text file
   contains a comma-separated list of summary values that you want analyzed across
   levels. It will have two lines: a field header line containing comma-separated
   field labels, and a data line containing the corresponding levelwise data that
   you are passing into analysis acrosss all factor levels.

This script catenates those level-wise text files to produce a single
factor-wise textfile in the root called (TBD)

Calling this script without any arguments will create a template levelwise
script for you, as well calculat sample output from that script.

EOF
# TBD: will the exit value of the script be the filepath of the matrix?
}


fxnProcessInvocation() {

# # always: check for number of arguments, even if expecting zero:
# if [ "${scriptArgsCount}" -ne "3" ] ; then
#    echo ""
#    echo "ERROR: this script is expecting exactly three arguments. You provided $scriptArgsCount arguments."
#    echo ""
#    fxnPrintUsage
#    echo ""
#    exit 1
# fi


# process commandline arguments with getopt:
# (recalling it can't handle arguments with spaces in them)

# STEP 1/3: initialize any variables that receive values during argument processing:
factorName=''
levelNameList=''
levelScript=''
# STEP 2/3: set the getopt string:
# echo "DEBUG getopt: Values before set -- getopt ... :"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"
set -- `getopt f:l:s: "${scriptArgsVector}"`
# echo "DEBUG getopt: Values after set -- getopt ... :"
# echo "DEBUG getopt: (notice that getopt changes \$@ and \$\, not \$script* :)"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"
# STEP 3/3: process command line switches in  a loop:
[ $# -lt 1 ] && exit 1	# getopt failed
while [ $# -gt 0 ]; do
    # echo "DEBUG getopt: \$\# == $# is still greater than 0"
    # echo "DEBUG getopt: \$\# == ${scriptArgsVector} "
    case "$1" in
      -f)   factorName="${2}"; shift ;;
      -s)   levelScript="${2}"; shift ;;
      -l)   levelNameList="${2}"; shift ;;
      --)   shift; break ;;
      -*)   echo >&2 "usage: $0 -f factorLabel -l factorLevelList -s levelScript" exit 1 ;;
       *)   break ;;		# terminate while loop
    esac
    shift
done
# ...and now all command line switches have been processed.
# echo "DEBUG getopt: Values after the getopt while loop :"
# echo "DEBUG getopt: (notice that getopt changes \$@ and \$\, not \$script* :)"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"


# check for incompatible invocation options:
# if [ "$headingsoff" != "0" ] && [ "$headingsonly" != "0" ] ; then
#    echo ""
#    echo "ERROR: cannot specify both -r and -n:"
#    echo ""
#    fxnPrintUsage
#    echo ""
#    exit 1
# fi

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
   fxnSetTempDir
   deleteTempDirAtEndOfScript=0

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
  # Tests the full function of the script. Begins by calling fxnSelftestBaic() , and then...
  # <EDITME: description of tests and validating data>
  fxnSelftestBasic
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

   # Is $tempParent already defined as a writable directory? If not, try to define a reasonable one here:
   tempParentPrevouslySetToWritableDir=''
   hostname=`hostname -s`
   kernel=`uname -s`
   #echo "DEBUG: \$tempParent is currently set to ${tempParent}"
   if [ ! -z ${tempParent} ] && [ -d ${tempParent} ] && [ -w ${tempParent} ]; then
      tempParentPreviouslySetToWritableDir=1
      #echo "DEBUG: tempParentPreviouslySetToWritableDir=1"
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
#   echo "DEBUG"
#   echo "DEBUG: \${tempParent} is ${tempParent}"
#   echo "DEBUG:"

   # Now that writable ${tempParent} has been confirmed, create ${tempDir}:
   # e.g., tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   # does this $tempDir already exit? if so, don't try to make it again:
   if [ -d "${tempDir}" ] && [ -w "${tempDir}" ]; then
      echo ""
      # echo "DEBUG: ${tempDir} already exists as a writable directory. Exiting fxnSetTempDir"
   else 
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
   fi
}


fxnSetSomeFancyConstants() {


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

scriptArgsVector="${@}"
listOfBasicConstants="\$scriptArgsVector ${listOfBasicConstants}"

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
deleteTempDirAtEndOfScript=0  # <- set to 1 to delete ${tempDir} or 0 to leave it. See end of script.


fxnProcessInvocation          
echo ""
echo "(DEBUG) \${factorName}=${factorName}"
echo "(DEBUG) \${levelNameList}=${levelNameList}"
echo "(DEBUG) \${levelScript}=${levelScript}"
echo ""

#fxnSetSomeFancyConstants
# ...and then edit its function definition for your specific needs.


fxnSelftestBasic
#...the script will exit after completing the self-test, ignoring all lines below.

# turn csv levelNameList commas into spaces



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


#TBD: call fxnSelftestBasic if nothing happened earlier in the script

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
   ls -l ${tempDir}
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

