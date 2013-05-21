#!/bin/bash
#
# LOCATION:	    ${bwDir}/bwCompareAcrossLevelsOfOneFactor.sh
# USAGE:	    see the fxnPrintUsage() function below 
#
# CREATED:          20130516 by stowler@gmail.com
# LAST UPDATED:     20130520 by stowler@gmail.com
#
# DESCRIPTION:
# A very general tool. Loops over multiple levels of one factor. Each loop
# iteration runs the user-specified script once and produces one file
# containing one vector of results per level. Level-wise vectors are then
# catenated into a formatted text file for external comparison across levels. 
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
# - the output of levelScript should only be two objects:
#	1) a subdirectory called levelOutputRaw
#	2) a sibling text file called levelOutputVectorForComparisonAcrossLevels.csv
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


$0 - a general tool for running an external script against multiple levels of a single factor
Usage: $0  \\ 
  -f   [your factorName, which will just be used in output filenames.]                   \\
  -l   [your levelNames for levels of the factor: a comma-separated list WITH NO SPACES] \\
  -s   [your levelwise script, to be executed for each level of the factor]

When executed, the -s levelwise script is called once for each of the levels 
provided in the -l csv list. Each time through the loop, one of the levelNames
is provided as an argument in execution of the levelwise script. 

E.g., $0 -f months -l january,february -s countLetterTypes.sh

The output of this script is a single new output directory containing levelwise
subdirectories. Sibling to those subdirectories is a single 
csv file containing one row of data per factor level (plus header row):

\${outputDir}
   └── SINGLEFACTORDIR_months
       ├── FACTORLEVELDIR_january
       ├── FACTORLEVELDIR_february
       └── SINGLEFACTOROUTPUTMATRIX_months.csv

For this to work, the script provided as -s levelwiseScript.sh needs to produce output
in the following loose format, even when run alone:

   ├── levelOutputRaw
   │   ├── vowels.txt
   │   └── consonants.txt
   └── singleLevelOutputVectorForComparisonAcrossLevels.csv

...in other words:

1) All output files from a single execution of the levelwise script should be in a
   folder called "levelOutputRaw"
2) The only thing outside of levelOutputRaw should be a sibling two-line text
   file called singleLevelOutputVectorForComparisonAcrossLevels.csv . This text
   file should contain a comma-separated row of levelwise summary values that you
   will later be analyzing across levels. It should also contain a corresponding
   row of comma-separated field labels.

${scriptName} executes this script for each level and then catenates those
levelwise text files to produce a single factorwise textfile in the root called
SINGLEFACTOROUTPUTMATRIX_\${factorName}.csv 

Calling this script with the -t argument (TBD: --selftest ?) (can be in combination
with the other arguments or alone TBD) will create a exampleLevelwiseScript.sh
, and use it to generate sample output from ${scriptName}.

Its output should be something like this:

\${tempDir}
   └── SINGLEFACTORDIR_systemDirectories
       ├── FACTORLEVELDIR_etc
       │   ├── levelOutputRaw
       │   │   ├── fileCount-raw.txt
       │   │   └── folderSize-raw.txt
       │   └── singleLevelOutputVectorForComparisonAcrossLevels.csv
       ├── FACTORLEVELDIR_tmp
       │   ├── levelOutputRaw
       │   │   ├── fileCount-raw.txt
       │   │   └── folderSize-raw.txt
       │   └── singleLevelOutputVectorForComparisonAcrossLevels.csv
       └── SINGLEFACTOROUTPUTMATRIX_systemDirectories.csv

5 directories, 7 files

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
launchSelftest=''
factorName=''
levelNameList=''
levelScript=''
# debug must not lose its current value:
if [ -n ${debug} ] ; then debug=${debug} ; else debug=''; fi
# STEP 2/3: set the getopt string:
# echo ""
# echo "DEBUG getopt: Values before set -- getopt ... :"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"
# echo ""
eval set -- ${scriptArgsVector}
# echo ""
# echo "DEBUG getopt: Values after trying to set @... :"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"
# echo ""

TEMP=`getopt -- tdf:l:s: "$@"`
if [ $? != 0 ] ; then echo "Terminating...could not set string for getopt" >&2 ; fxnPrintUsage ; exit 1 ; fi

eval set -- "$TEMP"
# echo ""
# echo "DEBUG getopt: Values after set -- getopt ... :"
# echo "DEBUG getopt: (notice that getopt changes \$@ and \$\, not \$script* :)"
# echo "DEBUG getopt: \${scriptArgsVector}=${scriptArgsVector}"
# echo "DEBUG getopt: \${@}=${@}"
# echo "DEBUG getopt: \${scriptArgsCount}=${scriptArgsCount}"
# echo "DEBUG getopt: \${#}=${#}"
# echo ""
# STEP 3/3: process command line switches in  a loop:
# [ $# -lt 1 ] && exit 1	# getopt failed
while true ; do
    # echo "DEBUG getopt: \$\# == $# is still greater than 0"
    # echo "DEBUG getopt: \$\# == ${scriptArgsVector} "
    # echo "DEBUG \$1=${1}"
    case "$1" in
      -t)   launchSelftest="1" ; shift ;;
      -d)   debug="1" ;  shift ;;
      -f)   factorName="${2}" ; shift 2 ;;
      -l)   levelNameList="${2}"; shift 2 ;;
      -s)   levelScript="${2}"; shift 2 ;;
      --)   shift; break ;;
      -*)   echo >&2 "usage: $0 -f factorLabel -l factorLevelList -s levelScript" exit 1 ;;
       *)   echo "Error in arguments to ${scriptName}" ; fxnPrintUsage ; exit 1 ;;		# terminate while loop
    esac
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
echo ""
echo "(DEBUG) \${launchSelftest}=${launchSelftest}"
echo "(DEBUG) \${debug}=${debug}"
echo "(DEBUG) \${factorName}=${factorName}"
echo "(DEBUG) \${levelNameList}=${levelNameList}"
echo "(DEBUG) \${levelScript}=${levelScript}"
echo ""


}

fxnPrintDebug() {
if [ "${debug}" = "1" ]; then 
   echo "/////// DEBUG ///////"
   echo "$@"
   echo "/////////////////////"
fi
}

fxnSelftestBasic() {
   # Tests the basic funcions and variables of the template on which this
   # script is based. Valid output may appear as comment text at the bottom
   # of this script (TBD). This can be used to confirm that the basic functions
   # of the script are working on a particular system, or that they haven't
   # been broken by recent edits.
   fxnPrintDebug "Launching internal fxnSelftestBasic ..."

   # expose the basic constants defined in the script:
   echo "Some basic constants have been defined in this script,"
   echo "and their names are listed in variable \${listOfBasicConstants} : "
   echo "${listOfBasicConstants}"
   echo ""
   #echo "...and here are their values: (TBD: make this work)"
   #for scriptConstantName in ${listOfBasicConstants}; do
   #   scriptConstantValue="`echo ${scriptConstantName}`"
   #   echo "${scriptConstantName} == ${scriptConstantValue}"
   #done

   # test internal function fxnSetTempDir:
   echo "(DEBUG)"
   echo "(DEBUG) Launching internal fxnSetTempDir..."
   echo "(DEBUG)"
   fxnSetTempDir
   deleteTempDirAtEndOfScript=0
   echo "(DEBUG)"
   echo "(DEBUG)...done testing internal fxnSetTempDir ."
   echo "(DEBUG)"
   echo "The temporary directory \${tempDir} has been created as:"
   ls -dlh ${tempDir}
   echo "...with its final destiny set by \${deleteTempDirAtEndOfScript} == ${deleteTempDirAtEndOfScript}"
   echo ""

   # Strip out all comments that are marked as training. This will create a
   # slimmer, more readable version of the script :
   trainingMarker='###'       # trainingMarker must be sed-friendly. See below:
   fxnPrintDebug "Removing training comments from the current script (lines prepended with '${trainingMarker}' ...)"
   cp ${scriptDir}/${scriptName} ${tempDir}/script-orig.sh
   sed "/^${trainingMarker}/ d" ${tempDir}/script-orig.sh > ${tempDir}/script-withoutTrainingComments.sh
   linecountOrig="`wc -l ${tempDir}/script-orig.sh | awk '{print $1}'`"
   linecountSkinny="`wc -l ${tempDir}/script-withoutTrainingComments.sh | awk '{print $1}'`"
   fxnPrintDebug "...done removing training comments."
   echo "The current script (${scriptName}) has ${linecountOrig} lines, and I have generated a version"
   echo "without training comments that has ${linecountSkinny} lines:"
   ls -l ${tempDir}/*
   fxnPrintDebug "Completed internal fxnSelftestBasic"
}


fxnSelftestFull() {
  # Tests the full function of the script. Begins by calling fxnSelftestBaic() , and then...
  # <EDITME: description of tests and validating data>
  echo "(DEBUG)"
  echo "(DEBUG) Launching internal fxnSelftestFull , starting with internal fxnSelftestBasic ..."
  echo "(DEBUG)"
  fxnSelftestBasic
  echo "(DEBUG)"
  echo "(DEBUG) ...fxnSelftestBasic completed. For the rest of fxnSelftestFull,"
  echo "(DEBUG) creating exampleLevelwiseScript.sh and an output directory..."
  echo "(DEBUG)"

echo ""
echo "(DEBUG) \${launchSelftest}=${launchSelftest}"
echo "(DEBUG) \${debug}=${debug}"
echo "(DEBUG) \${factorName}=${factorName}"
echo "(DEBUG) \${levelNameList}=${levelNameList}"
echo "(DEBUG) \${levelScript}=${levelScript}"
echo ""

  # create a sample levelwiseScript:
  cat >> ${tempDir}/exampleLevelwiseScript.sh <<\EOF
      #!/bin/bash
      #
      # A small trivial scipt to find the disk usage of a folder. Generated
      # during fxnSelftestFull().
      #
      # USAGE: exampleLevelwiseScript.sh [the name of the folder to examine] [tempdir for output]
      #
      folderName=${1}
      tempDir=${2}
      #
      # 1) create the direcotry where this levelwise data will reside:
      rm -fr ${tempDir}/levelOutputRaw
      rm -fr ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
      mkdir ${tempDir}/levelOutputRaw
      #
      # 2) query for size and number of files, putting raw output into levelOutputRaw:
      du -sh /${folderName} >> ${tempDir}/levelOutputRaw/folderSize-raw.txt
      find /${folderName}/ >> ${tempDir}/levelOutputRaw/fileCount-raw.txt
      #
      # 3) extract/summarize levelwise data to variables:
      folderSize=`cat ${tempDir}/levelOutputRaw/folderSize-raw.txt | awk '{print $1}'`
      fileCount=`wc -l ${tempDir}/levelOutputRaw/fileCount-raw.txt | awk '{print $1}'`
      #
      # 4) assemble header row and corresponding data row:
      rowHeader="folderName,folderSize,fileCount"
      rowSingleLevelData="${folderName},${folderSize},${fileCount}"
      #
      # 5) output to a levelwise text file with a filename that is expected by external summary/loop scripts:
      #    singleLevelOutputVectorForComparisonAcrossLevels.csv
      echo "${rowHeader}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
      echo "${rowSingleLevelData}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv

      # return value (TBD?): file path to singleLevelOutputVectorForComparisonAcrossLevels.csv
EOF

  mkdir ${tempDir}/exampleLevelwiseScript-output

  echo "(DEBUG)"
  echo "(DEBUG)...done creating exampleLevelwiseScript.sh and an output directory."
  echo "(DEBUG)"

  echo "Generated exampleLevelwiseScript.sh, which can be used as a template for"
  echo "creating your own levelwise scripts to call from ${scriptName} :"
  ls -lh  ${tempDir}/exampleLevelwiseScript.sh
  ls -ldh ${tempDir}/exampleLevelwiseScript-output

  echo ""
  echo "And for the self-test we're currently performing, that exampleLevelwiseScript.sh will now"
  echo "be used as the -s argument to ${scriptName} . Launching now: "
  echo ""

   bash ${scriptDir}/${scriptName} \
        -d                         \
        -f systemDirectories       \
        -l etc,tmp                 \
        -s ${tempDir}/exampleLevelwiseScript.sh

  echo "(DEBUG)"
  echo "(DEBUG) Completed internal fxnSelftestFull in ${scriptName}"
  echo "(DEBUG)"

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

# good practice: try to keep debugging/verbose statements  in the functions when possible
# ...and in body: short statements telling the user what's happening (when your called fxns don't have banners to do so)
# maybe limit to objects the user interacts with directly?


# Setup a temporary directory, which can be configured for clean-up:
fxnSetTempDir                 # <- use internal function to create ${tempDir}
deleteTempDirAtEndOfScript=0  # <- set to 1 to delete ${tempDir} or 0 to leave it. See end of script.


# Set options based on script invocation:
fxnProcessInvocation          


# Decide whether to launch selftest, and then subsequently whether to continue or exit:
if [ "${launchSelftest}" = "1" ]; then
   echo ""
   echo "Launching the self-test in ${scriptName} ..."
   echo ""
   fxnSelftestFull
   echo ""
   echo "Completed the self-test in ${scriptName} ."
   echo ""
   # exit after completing the self-test, ignoring all lines below:
   exit 0
   # TBD: don't exit if there is a valid factorName from commandline
fi


# Convert commas to spaces in the "-l levelNameList" csv argument:
levelNameList=`echo ${levelNameList} | sed s/\,/' '/g`
echo ""
echo "Executing levelScript once for each levelName that was provided in the call to ${scriptName}."
echo "levelScript == ${levelScript}"
echo "levelNameList == ${levelNameList}"
echo ""


# Create output directories and launch the levelScript: 
mkdir ${tempDir}/SINGLEFACTORDIR_${factorName}
for levelName in ${levelNameList}; do
   echo ""
   echo "================================================================="
   echo "START: processing level '${levelName}' of factor '${factorName}' "
         date
   echo "================================================================="
   echo ""
   mkdir ${tempDir}/SINGLEFACTORDIR_${factorName}/FACTORLEVELDIR_${levelName}
   bash ${levelScript} ${levelName} ${tempDir}/SINGLEFACTORDIR_${factorName}/FACTORLEVELDIR_${levelName}
   echo ""
   echo "================================================================="
   echo "FINISHED: processed level '${levelName}' of factor '${factorName}' "
         date
   echo "================================================================="
   echo ""
done

# compile the individual factorLevel outputs into singleFactorOutputMatrix.csv:
# (for now just dump them together for testing purposes)
cat \
${tempDir}/SINGLEFACTORDIR_${factorName}/FACTORLEVELDIR_*/singleLevelOutputVectorForComparisonAcrossLevels.csv >> \
${tempDir}/SINGLEFACTORDIR_${factorName}/SINGLEFACTOROUTPUTMATRIX_${factorName}.csv
# TBD do for real:
# 1) are there zero? Exit if so
# 2) else if there is one...
   # make sure it has two lines (one header, one data)
   # make sure they have the same number of csv fields
# 3) else if there is > 1 ...
   # compare header vectors. Exit if they are different, otherwise assign to variable headerRow
   # make sure there is only one data row per level
   # echo headerRow to output matrix, followed by one row for each individual factor levels 
   # issue warning if there are any lines that have different number of fields
   # than header rowmake sure same number of fields in headerRow and every data
   # row


#TBD: call fxnSelftestBasic if nothing happened earlier in the script

# ------------------------- FINISHED: body of script ------------------------- #


# ------------------------- START: restore environment and say bye to user/logs ------------------------- #
#
# Output some final status info to the user/log and clean-up any resources.

# If a ${tempDir} was defined, remind the user about it and (optionally) delete it:
if [ -n "${tempDir}" ]; then 
	tempDirSize=`du -sh | awk '{print $1}'`
	tempDirFileCount=`find ${tempDir} | wc -l | awk '{print $1}'`
	echo ""
	echo ""
   echo "This script's temporary directory contains ${tempDirFileCount} files and folders,"
   echo "occupying total disk space of ${tempDirSize} :"
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
   echo "...and here are its contents, NOT being deleted by ${scriptName} :"
   echo ""
   tree ${tempDir}
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

