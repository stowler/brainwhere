#!/bin/bash
#
# LOCATION: 	   $bwDir/bwRegisterTo1mmMNI152.sh
# USAGE:           see fxnPrintUsage() function below
#
# CREATED:	   201008?? by stowler@gmail.com http://brainwhere.googlecode.com
# LAST UPDATED:	   20130521 by stowler@gmail.com
#
# DESCRIPTION:
# Registers T1 to the 1mm MNI152 template, along with optional lesion mask
# deweighting. If additional images are provided, their transformation to the
# T1 is calculated, and then combined with the T1->MNI152 xform to bring them
# into MNI152 space.
# 
# STYSTEM REQUIREMENTS:
#  - afni, fsl, getopt
#  - see brainwhere installation instructions here: https://github.com/stowler/brainwhere/blob/master/README.md
#
# INPUT FILES AND PERMISSIONS:
# <list or describe>
#
# OTHER ASSUMPTIONS:
# - Environmental variable $bwDir points to your brainwhere directory.
# - Environmental variable $FSLDIR points to your FSL directory.
#
# WEAKNESSES:
# - erases BRIK/HEAD commandline history (applywarp not implemented in afni...yet)
# - UNTESTED: brain extraction implementation may not be best for all brains (bet -R -v)
# - UNTESTED: variability in brain extraction may affect registration of T1->MNI152, thereby others->MNI152
# - UNTESTED: interpolation methods implemented may not be best (masks: nearest neighbor, decimal values: sinc)
#
# TBD: 
# - add interactive/non-interactive modes
# - accept HEAD/BRIK also
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



# ------------------------- START: define functions ------------------------- #

fxnPrintDebug() {
	if [ "${debug}" = "1" ]; then 
	   echo "////// DEBUG: ///// $@"
	fi
} 


fxnPrintUsage() {
cat <<EOF

	$0 - a script to register unstriped T1, lesion mask, EPI, and EPI-registered volumes (buck, etc.) to 1mmMNI152 space
	Usage: registerTo1mmMNI152.sh                                 \\
	  -z (launch self-test)                                       \\
	  -d (turn on debug-mode)                                     \\
	  -s <subjectID>                                              \\
	  -t <t1.nii>                                                 \\
	  -o <FullPathToOutdir>                                       \\
	[ -l <lesion.nii>                                             \\ ]
	[ -e <epi.nii>                                                \\ ]
	[ -c <clusterMasksRegisteredToAboveEPI.nii>                   \\ ]
	[ -c <anotherEPIregisteredCusterMask.nii>                     \\ ]
	[ -b <buckFileOrOtherDecimalValueImage.nii>                   \\ ]
	[ -b <anotherEPIregisteredBuckOrOtherDecimalValueImage.nii>     ]

	(specify as many -b and -c files as you like, just prepend EVERY file with -b or -c)

EOF
}


fxnProcessInvocation() {
	# No fxn debug greeting message at top. It's down below manual overide for $debug...

	# Always check for number of arguments, even if expecting zero.
	if [ "${scriptArgsCount}" -lt "1" ] ; then
	   echo ""
	   echo "ERROR: this script is expecting at least one argument (-z for selftest). You provided $scriptArgsCount arguments."
	   echo ""
	   fxnPrintUsage
	   echo ""
	   exit 1
	fi

	# Check for any unsatisfied environmental variables:
	if [ -d "${bwDir}" ] ; then 
		echo ""
		fxnPrintDebug "\$bwDir is currently set to ${bwDir}"
	else
		echo ""
		echo "Exiting. The environmental variable that points to the brainwhere directory (\$bwDir) is not currently set correctly. Please see brainwhere installation instructions here: https://github.com/stowler/brainwhere/blob/master/README.md " 
		echo ""
		exit 1
	fi

	if [ -d "${FSLDIR}" ] ; then 
		echo ""
		fxnPrintDebug "\$FSLDIR is currently set to ${FSLDIR}"
	else
		echo ""
		echo "Exiting. The environmental variable that points to the FSL directory (\$bwDir) is not currently set correctly. Please see brainwhere installation instructions here: https://github.com/stowler/brainwhere/blob/master/README.md " 
		echo ""
		exit 1
	fi

	# process commandline arguments with getopt:
	# (recalling it can't handle arguments with spaces in them)

	# STEP 1/3: initialize any variables that receive values during argument processing:
	launchSelftest=''
	debug=''
	blind=''
	t1=''
	outDir=''
	lesion=''
	epi=''
	integerVolumes=''
	decimalVolumes=''

	# if already set, debug must not lose its current value:
	if [ -n ${debug} ] ; then debug=${debug} ; else debug=''; fi
	# manual override for setting before the getopt below:
	#debug=1

	fxnPrintDebug "Starting fxnProcessInvocation..."
  	fxnPrintDebug " "
	fxnPrintDebug "getopt: Argument metavalues before set -- getopt ... :"
	fxnPrintDebug "getopt: \${scriptArgsVector}=${scriptArgsVector}"
	fxnPrintDebug "getopt: \${@}=${@}"
	fxnPrintDebug "getopt: \${scriptArgsCount}=${scriptArgsCount}"
	fxnPrintDebug "getopt: \${#}=${#}"
  	fxnPrintDebug " "

	# STEP 2/3: set the getopt string:
	eval set -- ${scriptArgsVector}
	TEMP=`getopt -- zds:t:o:l:e:c:b: "$@"`
	if [ $? != 0 ] ; then 
	   echo "Terminating...could not set string for getopt. Check out the Usage note:" >&2 
	   fxnPrintUsage 
	   exit 1 
	fi
	eval set -- "$TEMP"

  	fxnPrintDebug " "
	fxnPrintDebug "getopt: Argument metavalues after set -- getopt ... :"
	fxnPrintDebug "getopt: (notice that getopt changes \$@ and \$\, not \$script* :)"
	fxnPrintDebug "getopt: \${scriptArgsVector}=${scriptArgsVector}"
	fxnPrintDebug "getopt: \${@}=${@}"
	fxnPrintDebug "getopt: \${scriptArgsCount}=${scriptArgsCount}"
	fxnPrintDebug "getopt: \${#}=${#}"
  	fxnPrintDebug " "

	# STEP 3/3: process command line switches in  a loop:
	while true ; do
	    fxnPrintDebug "In while loop for processing arguments..."
	    fxnPrintDebug "\$1=${1}"
	    case "$1" in
	      -z)   launchSelftest="1" ; shift ;;
	      -d)   debug="1" ;  shift ;;
	      -s)   blind="${2}"; shift 2 ;;
	      -t)   t1="${2}"; shift 2 ;;
	      -o)   outDir="${2}"; shift 2 ;;
	      -l)   lesion="${2}"; shift 2 ;;
	      -e)   epi="${2}"; shift 2 ;;
	      -c)   integerVolumes="${integerVolumes} ${2}"; shift ;;
	      -b)   decimalVolumes="${decimalVolumes} ${2}"; shift ;;
	      --)   shift; break ;;
	      -*)   echo >&2 "Error in invocation. See usage note" ; fxnPrintUsage ;  exit 1 ;;
	       *)   echo "Error in arguments to ${scriptName}" ; fxnPrintUsage ; exit 1 ;;		# terminate while loop
	    esac
	done
	# ...and now all command line switches have been processed.

  	fxnPrintDebug " "
	fxnPrintDebug "getopt: Argument metavalues after the getopt while loop :"
	fxnPrintDebug "getopt: (notice that getopt changes \$@ and \$\, not \$script* :)"
	fxnPrintDebug "getopt: \${scriptArgsVector}=${scriptArgsVector}"
	fxnPrintDebug "getopt: \${@}=${@}"
	fxnPrintDebug "getopt: \${scriptArgsCount}=${scriptArgsCount}"
	fxnPrintDebug "getopt: \${#}=${#}"
  	fxnPrintDebug " "

	# Are we missing any required invocation options? Checking:
	if [ -z ${blind} ] && [ -z $launchSelftest ]; then
		echo ""
		echo "ERROR: must supply -s [subjectID]"
		echo ""
		fxnPrintUsage
		echo ""
		exit 1
	elif [ -z ${t1} ] && [ -z $launchSelftest ]; then
		echo ""
		echo "ERROR: must supply -t [T1]"
		echo ""
		fxnPrintUsage
		echo ""
		exit 1
	elif [ -z ${outDir} ] && [ -z $launchSelftest ]; then
		echo ""
		echo "ERROR: must supply -o [full path to outputDirectory]"
		echo ""
		fxnPrintUsage
		echo ""
		exit 1
		# TBD: change this so that it's not mandatory, but s/t that can happen at end if requested
	fi


	# check for incompatible invocation options:
	# if [ "$headingsoff" != "0" ] && [ "$headingsonly" != "0" ] ; then
	#    echo ""
	#    echo "ERROR: cannot specify both -r and -n:"
	#    echo ""
	#    fxnPrintUsage
	#    echo ""
	#    exit 1
	# fi

	# for debug, display final check of invocation variables before returning:
  	fxnPrintDebug " "
	fxnPrintDebug "\${launchSelftest} ==${launchSelftest}"
	fxnPrintDebug "\${debug} == ${debug}"
	fxnPrintDebug "\${blind} == ${blind}"
	fxnPrintDebug "\${t1} == ${t1}"
	fxnPrintDebug "\${outDir} == ${outDir}"
	fxnPrintDebug "\${lesion} == ${lesion}"
	fxnPrintDebug "\${epi} == ${epi}"
	fxnPrintDebug "\${integerVolumes} == ${integerVolumes}"
	fxnPrintDebug "\${decimalVolumes} == ${decimalVolumes}"
	fxnPrintDebug " "
	fxnPrintDebug "...completed fxnProcessInvocation ."
}

fxnSelftest() {
	# Tests the full function of the script. TBD: change to fxnSelftestBasic/fxnSelftestFull framework
	fxnPrintDebug "Launching internal fxnSelftest..."
	#fxnSelftestBasic
	#fxnPrintDebug "...fxnSelftestBasic completed. Continuing fxnSelftestFull..."
	fxnPrintDebug " "
	fxnPrintDebug "\${FSLDIR} == ${FSLDIR}"
	fxnPrintDebug "\${bwDir} == ${bwDir}"
	fxnPrintDebug "-z selftest == \${launchSelftest} ==${launchSelftest}"
	fxnPrintDebug "-s subjectID == \${blind} == ${blind}"
	fxnPrintDebug "-t t1 == \${t1} == ${t1}"
	fxnPrintDebug "-o FullPathToOutdir == \${outDir} == ${outDir}"
	#fxnPrintDebug "-l lesion.nii == \${} == ${}"
	fxnPrintDebug "-e epi.nii == \${epi} == ${epi}"
	fxnPrintDebug " "

	cat <<EOF
	SELFTEST: launching $0 using the command:
	$0 \\
	-s selftestParticipant \\
	-t \${FSLDIR}/data/standard/MNI152lin_T1_1mm.nii.gz \\
	-o \${tempDir}/selftestParticipant \\
	-e \${FSLDIR}/data/standard/MNI152lin_T1_2mm_brain.nii.gz

EOF

	#fxnPrintDebug "DEBUG: Intentionally exiting fxnSelftest before launching $0."
	#exit 1

	${bwDir}/${scriptName} \
	-s selftestGoodImages \
	-t ${FSLDIR}/data/standard/MNI152lin_T1_1mm.nii.gz \
	-o ${tempDir}/selftestParticipant \
	-e ${FSLDIR}/data/standard/MNI152lin_T1_2mm_brain.nii.gz

	# TBD: add additional self-tests:
	# badImages, noArguments, wrongArguments, etc.	
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
   fxnPrintDebug "Starting fxnSetTempDir ..."

   # Is $tempParent already defined as a writable directory? If not, try to define a reasonable one here:
   tempParentPrevouslySetToWritableDir=''
   hostname=`hostname -s`
   kernel=`uname -s`
   fxnPrintDebug "\$tempParent is currently set to ${tempParent}"
   if [ ! -z ${tempParent} ] && [ -d ${tempParent} ] && [ -w ${tempParent} ]; then
      tempParentPreviouslySetToWritableDir=1
      fxnPrintDebug "\$tempParentPreviouslySetToWritableDir=1"
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
   fxnPrintDebug "\${tempParent} is now ${tempParent}"

   # Now that writable ${tempParent} has been confirmed, create ${tempDir}:
   # e.g., tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   tempDir="${tempParent}/${startDateTime}-from_${scriptName}.${scriptPID}"
   fxnPrintDebug "\${tempDir} has been set to ${tempDir}"
   # does this $tempDir already exit? if so, don't try to make it again:
   if [ -d "${tempDir}" ] && [ -w "${tempDir}" ]; then
      echo ""
      fxnPrintDebug "${tempDir} already exists as a writable directory. Exiting fxnSetTempDir ."
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
      else
         echo "A temporary directory has been created:"
         echo "${tempDir}"
      fi
   fi
   fxnPrintDebug "...completed fxnSetTempDir ."
}


fxnConfirmOurInputImages() {
	# check for bad or nonexistent images :
	fxnPrintDebug " "
	fxnPrintDebug "Launching internal fxnConfirmOurInputImages ..." 
	fxnPrintDebug " "

	fxnValidateImages ${t1}
	if [ $? -eq 1 ]; then 
		echo ""
		echo "ERROR: $t1 is not a valid image"
		echo ""
		fxnPrintUsage
		echo ""
		exit 1
	fi

	if [ ! -z ${lesion} ]; then
		fxnValidateImages ${lesion}
		if [ $? -eq 1 ]; then 
			echo ""
			echo "ERROR: $lesion is not a valid image"
			echo ""
			fxnPrintUsage
			echo ""
			exit 1
		fi
	fi

	if [ ! -z ${epi} ]; then
		fxnValidateImages ${epi}
		if [ $? -eq 1 ]; then 
			echo ""
			echo "ERROR: $epi is not a valid image"
			echo ""
			fxnPrintUsage
			echo ""
			exit 1
		fi
	fi

	# the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws"
	for image in `echo ${integerVolumes}`; do
		fxnPrintDebug "validating integerVolume ${image}"
		if [ ! -z ${image} ]; then
			fxnValidateImages ${image}
			if [ $? -eq 1 ]; then 
				echo ""
				echo "ERROR: $image is not a valid image"
				echo ""
				fxnPrintUsage
				echo ""
				exit 1
			else
				fxnPrintDebug "$image is a valid image. Yay!"
			fi
		fi
	done

	# the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws"
	for image in `echo ${decimalVolumes}`; do
		fxnPrintDebug "validating decimalVolume ${image}"
		if [ ! -z ${image} ]; then
			fxnValidateImages ${image}
			if [ $? -eq 1 ]; then 
				echo ""
				echo "ERROR: $image is not a valid image"
				echo ""
				fxnPrintUsage
				echo ""
				exit 1
			else
				fxnPrintDebug "DEBUG $image is a valid image. Yay!"
			fi
		fi
	done

	fxnPrintDebug " "
	fxnPrintDebug "Launching internal fxnConfirmOurInputImages ..." 
	fxnPrintDebug " "
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

fxnPrintDebug "\${listOfBasicConstants} is:"
fxnPrintDebug "${listOfBasicConstants}"


# ------------------------- FINISHED: define basic script constants------------------------- #



# ------------------------- START: greet the user/logs ------------------------- #
echo ""
echo ""
echo "#################################################################"
echo "START: \"${scriptName} $@\""
      date
echo "#################################################################"
echo ""
echo ""
# ------------------------- FINISHED: greet the user/logs ------------------------- #



# ------------------------- START: body of script ------------------------- #

source ${bwDir}/utilitiesAndData/brainwhereCommonFunctions.sh

# Set options based on script invocation:
fxnProcessInvocation     

# Setup a temporary directory, which can be configured for clean-up:
fxnSetTempDir                 # <- use internal function to create ${tempDir}
deleteTempDirAtEndOfScript=0  # <- set to 1 to delete ${tempDir} or 0 to leave it. See end of script.

# Decide whether to launch selftest, and then subsequently whether to continue or exit:
if [ "${launchSelftest}" = "1" ]; then
   echo ""
   echo "Launching the self-test in ${scriptName} ..."
   echo ""
   fxnSelftest
   echo ""
   echo "...completed the self-test in ${scriptName} ."
   echo ""
   exit 0 # exit after completing the self-test, ignoring all lines below:
   # TBD: don't exit if this should continue to process actual images
fi

# test the validity of the input images:
fxnConfirmOurInputImages

# TBD: Verify that destination directories exist and are user-writable:
mkdir -p ${outDir}


# ================================================================= #
# display input image metadata:
#
echo ""
echo "Images to be nonlinearly register to 1mmMNI152"
echo "- IMPORTANT: a lesion must match T1's geometry"
echo "- IMPORTANT: images following EPI must match EPI geometry"
echo ""
# ...first just create the header row:
bash ${bwDir}/displayImageGeometry.sh -n ${t1} >> ${tempDir}/inputUnformatted.txt
# ...then create the per-image rows:
# (the following requires echo $var, not just $var for ws-sep'd values in $var
# to be subsequently read as multiple values instead of single value containing
# ws:)
for image in $t1 $lesion $epi `echo ${integerVolumes} ${decimalVolumes}`; do
	if [ -s $image ]; then
		bash ${bwDir}/displayImageGeometry.sh -r $image >> ${tempDir}/inputUnformatted.txt
	fi
done
fxnPrintDebug "${tempDir}/inputUnformatted.txt put into columns for your pleasure:"
cat ${tempDir}/inputUnformatted.txt | column -t
echo ""
# TBD: handle switch b/t non/interactive modes:
echo "DEBUG: Happy? (Return to continue, ctrl-c to exit)"
read

echo ""
echo ""
echo "================================================================="
echo "START: nonlinear registration of ${blind} to 1mmMNI152"
echo "(about 20 minutes, or about 60 minutes if also applying warp to epi)"
      date
echo "================================================================="
echo ""
echo ""


# ================================================================= #
# copy images to $tempDir:
#
echo ""
echo "Copying input images to ensure consistent naming and avoid bad datatypes:"
echo ""

# ...always for the t1:
3dresample \
-orient rpi \
-prefix ${tempDir}/${blind}_t1.nii.gz \
-inset $t1
ls -1 ${tempDir}/${blind}_t1*

#...for the lesion, if provided:
if [ -s "`echo ${lesion}`" ]; then
	fslmaths ${lesion} ${tempDir}/${blind}_lesion_char.nii.gz -odt char
	3dresample \
	-orient rpi \
	-prefix ${tempDir}/${blind}_lesion.nii.gz \
	-inset ${tempDir}/${blind}_lesion_char.nii.gz
	rm -f ${tempDir}/${blind}_lesion_char.nii.gz
	ls -1 ${tempDir}/${blind}_lesion*
fi
#...for the EPI, if provided:
if [ -s "`echo ${epi}`" ]; then
	3dresample \
        -orient rpi \
        -prefix ${tempDir}/${blind}_epi.nii.gz \
        -inset ${epi}
	ls -1 ${tempDir}/${blind}_epi*
fi
# ...for any integerVolumes or decimalVolumes, if provided: 
# the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws:
for image in `echo ${integerVolumes} ${decimalVolumes}`; do
        if [ -s "`echo ${image}`" ]; then
                imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
                fxnPrintDebug "3dresampling ${imageBasename} ..."
		3dresample \
		-orient rpi \
		-prefix ${tempDir}/${imageBasename}.nii.gz \
		-inset ${image}
                fxnPrintDebug "...done 3dresampling ${imageBasename} ."
		ls -1 ${tempDir}/${imageBasename}.*
	fi
done



# ================================================================= #
# skull-strip T1:
#
betOptsT1="-f 0.35 -B"
if [ "${debug}" = "1" ] ; then betOptsT1="${betOptsT1} -v"; fi 
echo ""
echo ""
echo "Skull-striping T1..."
echo "(using bet options ${betOptsT1})"
echo ""
bet ${tempDir}/${blind}_t1 ${tempDir}/${blind}_t1_brain ${betOptsT1}
echo ""
echo "...done skull-striping T1:"
ls -l ${tempDir}/${blind}_t1_brain*
echo ""
echo ""



# ================================================================= #
# if lesion mask is being used, invert intensities so 1's are outside of lesion:
#
if [ -s "`echo ${lesion}`" ]; then
	echo ""
	echo ""
	echo "Inverting lesion mask..."
	fslmaths ${tempDir}/${blind}_lesion -sub 1 -abs ${tempDir}/${blind}_lesionInverted -odt char
	echo "...done inverting lesion mask:"
	ls -l ${tempDir}/${blind}_lesionInverted*
fi



# ================================================================= #
# linear registration of t1_brain to template:
#
echo ""
echo ""
echo "Linear transformation of T1 takes about two minutes..."
# include -inweight if we have a lesion, don't if we don't: 
if [ -s "`echo ${lesion}`" ]; then
	flirt \
	     -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz \
	     -in ${tempDir}/${blind}_t1_brain \
	     -inweight ${tempDir}/${blind}_lesionInverted \
	     -omat ${tempDir}/${blind}_affine_transf.mat 
else
	flirt \
	     -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz \
	     -in ${tempDir}/${blind}_t1_brain \
	     -omat ${tempDir}/${blind}_affine_transf.mat 
fi
echo "...done with linear transformatio of T1:"
ls -l ${tempDir}/${blind}_affine_transf.mat



# ================================================================= #
# if epi is to be registered, here's linear registration of epi to t1_brain:
# TBD: experimenting to try to get better func2struct registrations
# TBD: create an option for skull-striping EPI or not
#
if [ -s "`echo ${epi}`" ]; then
	echo ""
	echo ""
	echo "Linear transformation of EPI takes about two minutes..."
	# first create a 3D mean across EPI timepoints:
	fslmaths ${tempDir}/${blind}_epi.nii.gz -Tmean ${tempDir}/${blind}_epi_averaged.nii.gz
	# then skull-strip the averated EPI:
	betOptsAveragedEPI="-R"
	if [ "${debug}" = "1" ] ; then betOptsAveragedEPI="${betOptsAveragedEPI} -v"; fi
	bet ${tempDir}/${blind}_epi_averaged.nii.gz ${tempDir}/${blind}_epi_averaged_brain.nii.gz ${betOptsAveragedEPI}

	# now use this 3D average EPI in the calculation of the transformation
	# instead of the original EPI:
	# TBD: put back in refweight as part of a conditional version of that that gets executed if lesion is available
	#	-refweight ${tempDir}/${blind}_lesionInverted \
	# TBD: was originally using "-in ${tempDir}/${blind}_epi_averaged_brain"
	# ...but got some bad PiB registrations so trying instead:
	# 	-in ${tempDir}/${blind}_epi_averaged \
	flirt \
	-in ${tempDir}/${blind}_epi_averaged \
	-ref ${tempDir}/${blind}_t1_brain \
	-dof 6 \
	-cost corratio \
	-usesqform \
	-coarsesearch 20 \
	-omat ${tempDir}/${blind}_func2struct.mat
	echo "...done with linear transform of EPI to T1:"
	ls -l ${tempDir}/${blind}_func2struct.mat
	echo ""
	echo ""

	# and now apply calcuated transformtion to produce
	# _epi_averaged_func2struct.nii.gz for easy visual verification of
	# linear EPI-to-structural registration:
	flirt \
	-in ${tempDir}/${blind}_epi_averaged.nii.gz \
	-ref ${tempDir}/${blind}_t1_brain.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_func2struct.mat \
	-out ${tempDir}/${blind}_epi_averaged_func2struct.nii.gz

	# ...and also to extracted EPI:
	flirt \
	-in ${tempDir}/${blind}_epi_averaged_brain.nii.gz \
	-ref ${tempDir}/${blind}_t1_brain.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_func2struct.mat \
	-out ${tempDir}/${blind}_epi_averaged_brain_func2struct.nii.gz
fi



# ================================================================= #
# calculation of nonlinear t1->mni transformation:
#
echo ""
echo ""
echo "nonlinear transformation of t1 to template takes about 15 minutes..."
echo "(ignore messages about requested tolerance...unless your transformation turns out horrible, in which case they may have been meaningful)"
echo ""
if [ -s "`echo ${lesion}`" ]; then
	fnirt \
	     --in=${tempDir}/${blind}_t1 \
	     --aff=${tempDir}/${blind}_affine_transf.mat \
	     --cout=${tempDir}/${blind}_nonlinear_transf \
	     --config=T1_2_MNI152_2mm \
	     --inmask=${tempDir}/${blind}_lesionInverted 
else
	fnirt \
	     --in=${tempDir}/${blind}_t1 \
	     --aff=${tempDir}/${blind}_affine_transf.mat \
	     --cout=${tempDir}/${blind}_nonlinear_transf \
	     --config=T1_2_MNI152_2mm 
fi
echo ""
echo "...done:"
ls -l ${tempDir}/${blind}_nonlinear_transf*



# ================================================================= #
# apply nonlinear transformations :
#
echo ""
echo ""
echo "applying nonlinear warp to T1 (about 1 minute)..."
applywarp \
     --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
     --in=${tempDir}/${blind}_t1 \
     --warp=${tempDir}/${blind}_nonlinear_transf \
     --out=${tempDir}/${blind}_t1_warped
ls -l ${tempDir}/${blind}_t1_warped*

echo ""
echo ""
echo "applying nonlinear warp to skull-striped T1 (about 1 minute)..."
applywarp \
     	--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
     	--in=${tempDir}/${blind}_t1_brain \
     	--warp=${tempDir}/${blind}_nonlinear_transf \
     	--out=${tempDir}/${blind}_t1_brain_warped
ls -l ${tempDir}/${blind}_t1_brain_warped*

if [ -s "`echo ${lesion}`" ]; then
	echo ""
	echo ""
	echo "applying nonlinear warp to lesion (about 1 minute)..."
	applywarp \
	     	--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
	     	--in=${tempDir}/${blind}_lesion \
	     	--warp=${tempDir}/${blind}_nonlinear_transf \
	     	--out=${tempDir}/${blind}_lesion_warped \
	     	--interp=nn
	ls -l ${tempDir}/${blind}_lesion_warped*
fi

if [ -s "`echo ${epi}`" ]; then
	echo ""
	echo ""
	echo "applying nonlinear warp to epi (about 30 minutes)..."
	# temporarily disabling warp of full 4D EPI....
	#ls -l ${tempDir}/${blind}_epi*
	#applywarp \
	#     --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
	#     --in=${tempDir}/${blind}_epi \
	#     --warp=${tempDir}/${blind}_nonlinear_transf \
	#     --premat=${tempDir}/${blind}_func2struct.mat \
	#     --out=${tempDir}/${blind}_epi_warped

	# ...in exchange for faster warp of 3D EPI average:
	applywarp \
		--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
		--in=${tempDir}/${blind}_epi_averaged \
		--warp=${tempDir}/${blind}_nonlinear_transf \
		--premat=${tempDir}/${blind}_func2struct.mat \
		--out=${tempDir}/${blind}_epi_averaged_warped
	ls -l ${tempDir}/${blind}_epi*warped*
fi

# the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws:
# integer-based volumes like cluster masks are registered with nearest neighbor interpolation:
for image in `echo ${integerVolumes}`; do
	if [ -s "`echo ${image}`" ]; then
		echo ""
		echo ""
		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
		echo "applying nonlinear warp to ${imageBasename} (probably 30 or fewer minutes)..."
		applywarp \
		--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
		--in=${tempDir}/${imageBasename} \
		--warp=${tempDir}/${blind}_nonlinear_transf \
		--premat=${tempDir}/${blind}_func2struct.mat \
		--out=${tempDir}/${imageBasename}_warped.nii.gz \
		--interp=nn
		ls -l ${tempDir}/${imageBasename}_warped*
	fi
done

# the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws:
# decimal-based volumes like stats are registered with fancier interpolation:
for image in `echo ${decimalVolumes}`; do
	if [ -s "`echo ${image}`" ]; then
		echo ""
		echo ""
		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
		echo "applying nonlinear warp to ${imageBasename} (probably 30 or fewer minutes)..."
		applywarp \
		--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
		--in=${tempDir}/${imageBasename} \
		--warp=${tempDir}/${blind}_nonlinear_transf \
		--premat=${tempDir}/${blind}_func2struct.mat \
		--out=${tempDir}/${imageBasename}_warped.nii.gz \
		--interp=sinc
		ls -l ${tempDir}/${imageBasename}_warped*
	fi
done

echo ""
echo ""
echo "================================================================="
echo "FINISHED: nonlinear registration of ${blind} to 1mmMNI152 "
      date
echo "================================================================="
echo ""
echo ""

if [ -n ${outDir} ]; then 
	mkdir ${outDir} >2/dev/null
	cp ${tempDir}/*.nii.gz ${outDir}/ >2/dev/null
	cp ${tempDir}/*.nii ${outDir}/ >2/dev/null
	cp ${tempDir}/*.mat ${outDir}/ >2/dev/null
	finalDir=${outDir}
else
	deleteTempDirAtEndOfScript=0
	finalDir=${tempDir}
fi


# ------------------------- FINISHED: body of script ------------------------- #


# ------------------------- START: say bye and restore environment ------------------------- #
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
echo "One way to begin inspecting your output images would be this fslview command:"
cat <<EOF

standardTemplate=$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz
warpedT1=${finalDir}/${blind}_t1_brain_warped
warpedEPI=${finalDir}/${blind}_epi_averaged_warped
bottomLayer=\${standardTemplate}
middleLayer=\${warpedT1}
topLayer=\${warpedEPI}
fslview -m ortho \${bottomLayer} -l Green \${middleLayer} -l Pink \${topLayer} -l Greyscale &

EOF

echo ""
echo "#################################################################"
echo "FINISHED: \"${scriptName} $@\""
      date
echo "#################################################################"
echo ""
echo ""
echo ""
export FSLOUTPUTTYPE=${FSLOUTPUTTYPEorig}

# ------------------------- END: say bye and restore environment ------------------------- #


