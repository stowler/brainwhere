#!/bin/bash
#
# LOCATION: 	      $bwDir/bwFnirtBot.sh
# USAGE:             see fxnPrintUsage() function below
#
# CREATED:	         201008?? by stowler@gmail.com http://brainwhere.googlecode.com
# LAST UPDATED:	   20150209 by stowler@gmail.com
#
# DESCRIPTION:
#
# Nonlinearly registers T1 (whole head, unstripped) to the 1mm MNI152 template,
# along with optional lesion mask deweighting. If additional images are
# provided, their transformation to the T1 is calculated, and then combined
# with the T1->MNI152 xform to bring them into MNI152 space.
#
# MNI152-space images are also reverse-transformed into native T1 space.
#
# If EPI images are provided they will be transformed into native T1 space AND
# MNI152 space. Native space T1 images and MNI152 standard-space images will
# also be transformed into native EPI space.
#
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
# - erases BRIK/HEAD commandline history (applywarp equivalent not implemented in afni...yet)
# - UNTESTED: brain extraction implementation may not be best for all brains (bet -R -v)
# - UNTESTED: variability in brain extraction may affect registration of T1->MNI152, thereby others->MNI152
# - UNTESTED: interpolation methods implemented may not be best (masks: nearest neighbor, decimal values: trilinear)
#
# TBD: 
# - test lesion masking everywhere possible
# - add teaching note: notice that interpolated outputs ("+space2space.nii.gz") images are never inputs
# - add new td/tc arguments (see comments at end of fxnPrintUsage)
# - copy self (and log?) to tempDir and outDir
# - test for EPI: bet -F, and for func2anat 7dof
# - accept HEAD/BRIK input
# - add automatic slicesdir output to visualize regs and skull-strips
# - add self-test: compare results against gold-standard prior and detect error if different
# - add automatic testing of geometry compatibility:
#     - t1 with lesion, inputBrain, other alleged t1-aligend inputs
#     - epi with alleged epi-aligend inputs
#     - 1mmMNI152 with alleged mni-aligned inputs
# - add interactive mode:
#     - initial dis/approval of aggregate geometry table
#     - interactive skull stripping
#     - interactive confirmation of epi2t1 before lengthy application to all epi volumes
# - add subdirectory for xforms
# - address lack of xforms for 4D epi (func2anat and func2mni)
#     - can corrupt timeseries pretty significantly

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
   bwFnirtBot.sh - automated all-way registration of T1 images, EPI images, and 1mmMNI152 images.

   At minumum this script receives a whole-head T1 as input and uses FSL's
   flirt and fnirt to estimate and apply linear+nonlinear transformation
   (anat2mni), as well its inverse (mni2anat).

   If the user also provides a 3D or 4D EPI image, the script will estimate and
   apply additional transformations:

   - anat2func, and its inverse func2anat (linear)
   - func2mni,  and its inverse mni2func  (linear+nonlinear)
   
   --------------------------------------------------------------
   Input images:
   --------------------------------------------------------------

   - mandatory whole-head T1 
   - optional T1-space images already aligned with input T1
   - optional EPI and EPI-aligned images from the same participant
   - optional 1mmMNI152-aligned images

   --------------------------------------------------------------
   Output images:
   --------------------------------------------------------------

   1) subdirectory "inNativeSpaceOfT1", containing:
      - native-T1-registered versions of all input images (*+mni2anat.nii.gz , *+func2anat.nii.gz)
      - native-T1-registered versions of some MNI standard images (e.g., MNI* , HarvardOxford*+mni2anat.nii.gz)
      - native-T1-registered skull-stripped version of input T1 (*t1_brain.nii.gz)
      - copies of the original user-provided input images that were already T1-aligned

   2) subdirectory "inNativeSpaceOfEPI", containing:
      - native-EPI-registered versions of all input images (*+anat2func.nii.gz , *+mni2func.nii.gz)
      - native-EPI-registered versions of some MNI standard images (e.g., MNI* , HarvardOxford*+mni2func.nii.gz)
      - native-EPI-registered EPI temporal mean (*epi_averaged.nii.gz)
      - native-EPI-registered EPI temporal mean skull-stripped (*epi_averaged_brain.nii.gz)
      - copies of the original user-provided input images that were already EPI-aligned

   3) subdirectory "inStandardSpaceOf1mmMNI152", containing:
      - 1mmMNI152-registered versions of all input images (*+anat2mni.nii.gz , *+func2mni.nii.gz)
      - copies of the original user-provided input images that were already 1mmMNI152-aligned

   --------------------------------------------------------------
   Basic usage with three required arguments: 
   --------------------------------------------------------------

     bwFnirtBot.sh                                               \\
     -t <t1NotSkullStripped.nii>                                 \\
     -s <subjectIdForOutputNaming>                               \\
     -o <fullPathToOutputDirectoryThatWillBeCreatedByThisScript>

   --------------------------------------------------------------
   Optional input images:
   --------------------------------------------------------------

   Optional input images: no more than one of each of these special volumes:
     -e <epi4Dtimeseries.nii>
     -b <brainFromSkullStrippedT1.nii>   (already aligned with the -t t1 above)
     -l <lesionMaskFromT1.nii>           (already aligned with the -t t1 above)

   Optional 3d inputs: volumes already aligned to your "-e <epi.nii>" image:
     --ed <epiAlignedVolumesContainingDiscreteMaskIntensities.nii>
     --ec <epiAlignedVolumesContainingContinuousIntensities.ni>

   Optional 3d inputs: volumes already aligned to standard-space MNI152 image:
     --sd <standardSpaceAlignedVolumeContainingDiscreteMaskIntensities.nii>
     --sc <standardSpaceAlignedVolumeContainingContinuousIntensities.ni>

   Optional arguments to control exectuion:
     -z (launch internal self-test, which ignores any input volumes)
     -d (turn on debug mode)

   --------------------------------------------------------------
   Examples:
   --------------------------------------------------------------

   Example 1: run internal self-test (no input images required):

     bwFnirtBot.sh -z

   Example 2: execute with minimum inputs required for anat2mni and mni2anat
   transformations:
   
     bwFnirtBot.sh             \\
     -t s01_wholeHead.nii.gz   \\
     -s s01                    \\
     -o ~/s01mniCoreg

   Example 3: same as example 2, but provide a carefully skull-stripped T1
   instead of allowing bwFnirtBot to perform the skull-stripping:

     bwFnirtBot.sh                           \\
     -t s01_wholeHead.nii.gz                 \\
     -s s01                                  \\
     -b s01_handheldBrainExtraction.nii.gz   \\
     -o ~/s01mniCoregCarefulBet              

   Example 4: execute with the minium inputs required for func2anat/anat2func
   and func2mni/mni2func transformations:

     bwFnirtBot.sh                         \\
     -t s01_wholeHead.nii.gz               \\
     -s s01                                \\
     -e s01_housesFaces_run1.nii.gz        \\
     -o ~/s01mniCoregWithEPI

   Example 5: same as example 4, but include EPI-derived images that are already
   aligned with the native-space EPI:

     bwFnirtBot.sh                         \\
     -t s01_wholeHead.nii.gz               \\
     -s s01                                \\
     -e s01_housesFaces_run1.nii.gz        \\
     --ed s01_clustersForHouses.nii.gz     \\
     --ed s01_clustersForFaces.nii.gz      \\
     --ec s01_fstatsForHouses.nii.gz       \\
     --ec s01_fstatsForFaces.nii.gz        \\
     -o ~/s01mniCoregWithEPI

   Example 6: same as example 5, but also include 1mmMNI152-aligned images that
   need to be transformed into native T1 and native EPI spaces:

     bwFnirtBot.sh                            \\
     -t s01_wholeHead.nii.gz                  \\
     -s s01                                   \\
     -e s01_housesFaces_run1.nii.gz           \\
     --ed s01_clustersForHouses.nii.gz        \\
     --ed s01_clustersForFaces.nii.gz         \\
     --ec s01_fstatsForHouses.nii.gz          \\
     --ec s01_fstatsForFaces.nii.gz           \\
     --sd mniFusiformFaceArea.nii.gz          \\
     --sc mniGrayMatterProbabilityMap.nii.gz  \\
     -o ~/s01mniCoregWithEPI




EOF

# Near future additions to usage:
#   Additional input images (below) need special handling according to:
#      1) which image they are already aligned with: t1, epi, or standard space MNI152 template
#      2) whether they contain discrete intensities only (e.g., masks), or continuous intensities (e.g. T1, F-stats)
#
#
#   Optional 3d inputs: volumes already aligned to your "-t <t1NotSkullStripped.nii>" image:
#     --td <t1Aligned3dVolumesContainingDiscreteMaskIntensities.nii>
#     --tc <t1Aligned3dVolumesContainingContinuousIntensities.ni>
#
#

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
   inputBrain=''
   sd=''
   sc=''
   ed=''
   ec=''

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
	TEMP=`getopt -o zds:t:o:l:e:b: --long sd:,sc:,ed:,ec: -- "$@"`
# worked before adding long options:
#	TEMP=`getopt -- zds:t:o:l:e:b: "$@"`
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
	      -b)   inputBrain="${2}"; shift 2 ;;
         --sd) sd="${sd} ${2}"; shift 2 ;;
         --sc) sc="${sc} ${2}"; shift 2 ;;
         --ed) ed="${ed} ${2}"; shift 2 ;;
         --ec) ec="${ec} ${2}"; shift 2 ;;
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
	fxnPrintDebug "\${inputBrain} == ${inputBrain}"
	fxnPrintDebug "\${sd} == ${sd}"
	fxnPrintDebug "\${sc} == ${sc}"
	fxnPrintDebug "\${ed} == ${ed}"
	fxnPrintDebug "\${ec} == ${ec}"
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
	fxnPrintDebug "-l lesion.nii == \${lesion} == ${lesion}"
	fxnPrintDebug "-e epi.nii == \${epi} == ${epi}"
	fxnPrintDebug "-b inputBrain.nii == \${inputBrain} == ${inputBrain}"
	fxnPrintDebug "--sd standardAlignedDiscrete.nii == \${sd} == ${sd}"
	fxnPrintDebug "--sc standardAlignedContinuous.nii == \${sc} == ${sc}"
	fxnPrintDebug "--ed epiAlignedDiscrete.nii == \${ed} == ${ed}"
	fxnPrintDebug "--ec epiAlignedContinuous.nii == \${ec} == ${ec}"
	fxnPrintDebug " "

	cat <<EOF
	SELFTEST: launching $0 using  -s selftestMoAE \\

EOF

	${bwDir}/${scriptName} \
   -s selftestMoAE \
   -t ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_t1.nii.gz \
 	-b ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_t1_brain.nii.gz \
  	-l ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_lesionT1LeftSloppyHG.nii.gz \
   -e ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi.nii.gz \
   --ed ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi_funcROI.nii.gz \
   --ec ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi_tstd.nii.gz \
   --sd ${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz  \
   --sc ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz \
  	-o ${tempDir}/nominalOutDirFromSelftest 

# easly to add a pre-extracted t1 brain and lesion to the self-test:
#	-b ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_t1_brain.nii.gz \
# 	-l ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_lesionT1LeftSloppyHG.nii.gz \

# easy to add standard-space discrete- and continuous-intensity volumes to the self test:
#  --sd ${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz  \
#  --sc ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz \

# easy to add EPI, as well as EPI-aligned discrete- and continuous-intensity volumes to the self test:
#  -e ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi.nii.gz \
#  --ed ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi_funcROI.nii.gz \
#  --ec ${bwDir}/utilitiesAndData/imagesFromSPM/MoAE_epi_tstd.nii.gz \

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

	if [ ! -z ${inputBrain} ]; then
		fxnValidateImages ${inputBrain}
		if [ $? -eq 1 ]; then 
			echo ""
			echo "ERROR: $inputBrain is not a valid image"
			echo ""
			fxnPrintUsage
			echo ""
			exit 1
		fi
	fi

#	the following requires echo $var, not just $var for ws-sep'd values in $var to be subsequently read as multiple values instead of single value containing ws:
	for image in `echo ${sd} ${sc} ${ed} ${ec}`; do
		fxnPrintDebug "validating image ${image}"
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

	fxnPrintDebug " "
	fxnPrintDebug "Completed internal fxnConfirmOurInputImages ..." 
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

# Create logical subdirectories in $tempDir:
subdirNameSpaceT1=inNativeSpaceOfT1
subdirNameSpaceEPI=inNativeSpaceOfEPI
subdirNameSpaceStandard=inStandardSpaceOf1mmMNI152
tempDirSpaceT1=${tempDir}/${subdirNameSpaceT1}
tempDirSpaceEPI=${tempDir}/${subdirNameSpaceEPI}
tempDirSpaceStandard=${tempDir}/${subdirNameSpaceStandard}
mkdir -p ${tempDirSpaceT1}
mkdir -p ${tempDirSpaceStandard}
# NB: delaying creation of $tempDirSpaceEPI until we know whether user provided a valid EPI image
#mkdir -p ${tempDirSpaceEPI}


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
# confirm input image metadata:
#
# TBD: fix bwDisplayImageGeometry.sh so that it doesn't need an input image to print header row


# Geometry check for T1-aligned images if user provided more than just the T1:
if [ -n "${lesion}" ] || [ -n "${inputBrain}" ]; then
   echo ""
   echo "All T1-aligned input images must have consistent 3D geometry:"
   echo ""
   # Create the header row for the geometry table:
   bash ${bwDir}/bwDisplayImageGeometry.sh -n ${t1} >> ${tempDir}/inputUnformatted.txt
   # Create the per-image rows:
   for image in ${t1} ${lesion} ${inputBrain}; do
      if [ -s ${image} ]; then
         bash ${bwDir}/bwDisplayImageGeometry.sh -r ${image} >> ${tempDir}/inputUnformatted.txt
      fi
   done
   cat ${tempDir}/inputUnformatted.txt | column -t
   echo ""
   rm -f ${tempDir}/inputUnformatted.txt
fi


# Geometry check for EPI-aligned images if user provided more than just the EPI:
if [ -n "${ed}" ] || [ -n "${ec}" ]; then
   echo ""
   echo "All EPI-aligned input images must have consistent 3D geometry:"
   echo ""
   # Create the header row for the geometry table:
   bash ${bwDir}/bwDisplayImageGeometry.sh -n ${t1} >> ${tempDir}/inputUnformatted.txt
   # Create the per-image rows:
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in $var
   #    to be subsequently read as multiple values instead of single value containing
   #    ws.
   for image in ${epi} `echo ${ed} ${ec}`; do
      if [ -s ${image} ]; then
         bash ${bwDir}/bwDisplayImageGeometry.sh -r ${image} >> ${tempDir}/inputUnformatted.txt
      fi
   done
   cat ${tempDir}/inputUnformatted.txt | column -t
   echo ""
   rm -f ${tempDir}/inputUnformatted.txt
fi


# Geometry check for 1mmMNI152-aligned images if user provided any:
if [ -n "${sd}"  ] || [ -n "${sc}" ]; then
   echo ""
   echo "All 1mmMNI152-aligned input images must match the 3D geometry of FSL's MNI152_T1_1mm standard template:"
   echo ""
   # Create the header row for the geometry table:
   bash ${bwDir}/bwDisplayImageGeometry.sh -n ${t1} >> ${tempDir}/inputUnformatted.txt
   # Create the per-image rows:
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in $var
   #    to be subsequently read as multiple values instead of single value containing
   #    ws.
   for image in ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz `echo ${sd} ${sc}`; do
      if [ -s ${image} ]; then
         bash ${bwDir}/bwDisplayImageGeometry.sh -r ${image} >> ${tempDir}/inputUnformatted.txt
      fi
   done
   cat ${tempDir}/inputUnformatted.txt | column -t
   echo ""
   rm -f ${tempDir}/inputUnformatted.txt
fi

# TBD: handle switch b/t non/interactive modes:
#echo "DEBUG: Happy? (Return to continue, ctrl-c to exit)"
#read


echo ""
echo ""
echo "================================================================="
echo "START: nonlinear registration of ${blind} to 1mmMNI152"
echo "(typically < 30 minutes)"
      date
echo "================================================================="
echo ""
echo ""

echo ""
echo "-----------------------------------------------------------------"
echo "Importing images and preparing for registration:"
echo "-----------------------------------------------------------------"
echo ""


# ================================================================= #
# copy images to $tempDir:
#
echo ""
echo "Creating new copies of input images to ensure consistent naming, "
echo "consistent spatial orientation, and to avoid bad datatypes:"
echo ""

cp ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
   ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz \
   ${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz \
   ${tempDirSpaceStandard}/

# Below I'm using 3dresample instead of fslreorient2std to allow for the later
# possibility that AFNI BRIK/HEAD images may be used as input:

# ...import t1:
3dresample \
-orient rpi \
-prefix ${tempDirSpaceT1}/${blind}_t1.nii.gz \
-inset $t1 \
2>/dev/null
du -h ${tempDirSpaceT1}/${blind}_t1* 

#...import skull-stripped inputBrain, if provided:
if [ -s "`echo ${inputBrain}`" ]; then
	3dresample \
   -orient rpi \
   -prefix ${tempDirSpaceT1}/${blind}_t1_brain.nii.gz \
   -inset ${inputBrain} \
   2>/dev/null
	du -h ${tempDirSpaceT1}/${blind}_t1_brain*
fi

# ...import lesion, if provided:
if [ -s "`echo ${lesion}`" ]; then
	fslmaths ${lesion} ${tempDirSpaceT1}/${blind}_lesion_char.nii.gz -odt char
	3dresample \
	-orient rpi \
	-prefix ${tempDirSpaceT1}/${blind}_lesion.nii.gz \
	-inset ${tempDirSpaceT1}/${blind}_lesion_char.nii.gz \
   2>/dev/null
	rm -f ${tempDirSpaceT1}/${blind}_lesion_char.nii.gz
	du -h ${tempDirSpaceT1}/${blind}_lesion*
fi

#...import EPI, if provided:
if [ -s "`echo ${epi}`" ]; then
   mkdir -p ${tempDirSpaceEPI}
	3dresample \
   -orient rpi \
   -prefix ${tempDirSpaceEPI}/${blind}_epi.nii.gz \
   -inset ${epi} \
   2>/dev/null
	du -h ${tempDirSpaceEPI}/${blind}_epi*
fi


# ...import any standard-space discrete- or continuous-intensity volumes, if provided: 
#
#    NB: the following requires echo $var, not just $var for ws-sep'd values in
#    $var to be subsequently read as multiple values instead of single value
#    containing ws:
for image in `echo ${sd} ${sc}`; do
        if [ -s "`echo ${image}`" ]; then
                imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
                fxnPrintDebug "3dresampling ${imageBasename} ..."
		3dresample \
		-orient rpi \
		-prefix ${tempDirSpaceStandard}/${imageBasename}.nii.gz \
		-inset ${image} \
      2>/dev/null
                fxnPrintDebug "...done 3dresampling ${imageBasename} ."
		du -h ${tempDirSpaceStandard}/${imageBasename}.*
	fi
done

# ...import any EPI-aligned discrete- or continuous-intensity volumes, if provided: 
#
#    NB: the following requires echo $var, not just $var for ws-sep'd values in
#    $var to be subsequently read as multiple values instead of single value
#    containing ws:
for image in `echo ${ed} ${ec}`; do
        if [ -s "`echo ${image}`" ]; then
                imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
                fxnPrintDebug "3dresampling ${imageBasename} ..."
		3dresample \
		-orient rpi \
		-prefix ${tempDirSpaceEPI}/${imageBasename}.nii.gz \
		-inset ${image} \
      2>/dev/null
                fxnPrintDebug "...done 3dresampling ${imageBasename} ."
		du -h ${tempDirSpaceEPI}/${imageBasename}.*
	fi
done

echo "...done. (`date`)"


# ================================================================= #
# skull-strip T1 if skull-striped T1 wasn't already provided:
#
if [ -z ${inputBrain} ]; then 
   betOptsT1="-f 0.35 -B"
   if [ "${debug}" = "1" ] ; then betOptsT1="${betOptsT1} -v"; fi 
   echo ""
   echo ""
   echo "Skull-striping T1, which should take between one and twenty minutes..."
   echo "(using bet options ${betOptsT1})"

   bet ${tempDirSpaceT1}/${blind}_t1 ${tempDirSpaceT1}/${blind}_t1_brain ${betOptsT1}

   du -h ${tempDirSpaceT1}/${blind}_t1_brain*
   echo "...done. (`date`)"
else 
   echo ""
   echo ""
   echo "No need to skull-strip T1, as user provided a previously skull-stripped T1:"
   du -h ${inputBrain}
   du -h ${tempDirSpaceT1}/${blind}_t1_brain*
fi
   



# ================================================================= #
# if lesion mask is being used, invert intensities so 1's are outside of lesion:
#
if [ -s "`echo ${lesion}`" ]; then
	echo ""
	echo ""
	echo "Inverting lesion mask..."

	fslmaths ${tempDirSpaceT1}/${blind}_lesion -sub 1 -abs ${tempDirSpaceT1}/${blind}_lesionInverted -odt char
	du -h ${tempDirSpaceT1}/${blind}_lesionInverted*
	echo "...done. (`date`)"
fi



# ================================================================= #
# If epi was provided, linearly register epi to t1_brain:
#
# TBD: experimenting to try to get better func2anat registrations (maybe including motion-correction)
# TBD: create an option for skull-striping EPI or not
# TBD: create verification of func2anat results
#
if [ -s "`echo ${epi}`" ]; then
  
	# skull-strip the EPI:
	betOptsAveragedEPI="-R"
	if [ "${debug}" = "1" ] ; then betOptsAveragedEPI="${betOptsAveragedEPI} -v"; fi
   echo ""
   echo ""
   echo "Skull-stripping mean EPI (typically < 10 minutes)..."
   echo "(using bet options ${betOptsAveragedEPI})"

	# First create a 3D mean across EPI timepoints:
	fslmaths ${tempDirSpaceEPI}/${blind}_epi.nii.gz -Tmean ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz
   # ...then skull-strip:`
	bet ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz ${tempDirSpaceEPI}/${blind}_epi_averaged_brain.nii.gz ${betOptsAveragedEPI}

   du -h ${tempDirSpaceEPI}/${blind}_epi_averaged*
   echo "...done. (`date`)"


   echo ""
   echo ""
   echo ""
   echo "-----------------------------------------------------------------"
   echo "1) estimating linear transform:    func2anat"
   echo "2) inverting to:                   anat2func"
   echo "-----------------------------------------------------------------"


	echo ""
	echo ""
	echo "func2anat: estimating, and applying to EPI-aligned images (about two minutes)..."

	# TBD: put back in refweight as part of a conditional version of that that gets executed if lesion is available
	#	-refweight ${tempDirSpaceT1}/${blind}_lesionInverted \
	# TBD: was originally using "-in ${tempDirSpaceEPI}/${blind}_epi_averaged_brain"
	# ...but got some bad PiB registrations so trying instead:
	# 	-in ${tempDirSpaceEPI}/${blind}_epi_averaged \

   # calculate func2anat:
	flirt \
	-in ${tempDirSpaceEPI}/${blind}_epi_averaged \
	-ref ${tempDirSpaceT1}/${blind}_t1_brain \
	-dof 6 \
	-cost corratio \
	-usesqform \
	-coarsesearch 20 \
	-omat ${tempDir}/${blind}_func2anat.mat
   du -h ${tempDir}/${blind}_func2anat.mat

   # ...apply to mean EPI:
	flirt \
	-in ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz \
	-ref ${tempDirSpaceT1}/${blind}_t1_brain.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_func2anat.mat \
	-out  ${tempDirSpaceT1}/${blind}_epi_averaged+func2anat
   du -h ${tempDirSpaceT1}/${blind}_epi_averaged+func2anat*

	# ...and also apply to extracted EPI:
	flirt \
	-in ${tempDirSpaceEPI}/${blind}_epi_averaged_brain.nii.gz \
	-ref ${tempDirSpaceT1}/${blind}_t1_brain.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_func2anat.mat \
	-out  ${tempDirSpaceT1}/${blind}_epi_averaged_brain+func2anat
	du -h ${tempDirSpaceT1}/${blind}_epi_averaged_brain+func2anat*


   # apply func2anat to EPI-aligned discrete-intensity (mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${ed}`; do
      if [ -s "`echo ${image}`" ]; then
         imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
         flirt \
         -in ${tempDirSpaceEPI}/${imageBasename} \
         -ref ${tempDirSpaceT1}/${blind}_t1_brain.nii.gz \
         -applyxfm -init ${tempDir}/${blind}_func2anat.mat \
         -interp nearestneighbour \
         -out  ${tempDirSpaceT1}/${imageBasename}+func2anat
         du -h ${tempDirSpaceT1}/${imageBasename}+func2anat*
      fi
   done

   # apply func2anat to EPI-aligned continuous-intensity (non-mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${ec}`; do
      if [ -s "`echo ${image}`" ]; then
         imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
         flirt \
         -in ${tempDirSpaceEPI}/${imageBasename} \
         -ref ${tempDirSpaceT1}/${blind}_t1_brain.nii.gz \
         -applyxfm -init ${tempDir}/${blind}_func2anat.mat \
         -interp trilinear \
         -out  ${tempDirSpaceT1}/${imageBasename}+func2anat
         du -h ${tempDirSpaceT1}/${imageBasename}+func2anat*
      fi
   done


	echo "...done. (`date`)"


   # Now invert the func2anat xform and use it to bring t1-registered images
   # into EPI space:
	echo ""
	echo ""
	echo "anat2func: inverting from func2anat, applying to T1-aligned images (typically < 1 minute)..."

   # invert the func2anat xform, producing anat2func.mat:
   convert_xfm \
   -omat ${tempDir}/${blind}_anat2func.mat \
   -inverse \
   ${tempDir}/${blind}_func2anat.mat
   du -h ${tempDir}/${blind}_anat2func.mat

   # apply anat2func to whole-head t1:
	flirt \
	-in ${tempDirSpaceT1}/${blind}_t1 \
	-ref ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_anat2func.mat \
	-out  ${tempDirSpaceEPI}/${blind}_t1+anat2func
   du -h ${tempDirSpaceEPI}/${blind}_t1+anat2func*

   # apply anat2func to t1_brain:
	flirt \
	-in ${tempDirSpaceT1}/${blind}_t1_brain \
	-ref ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz \
	-applyxfm -init ${tempDir}/${blind}_anat2func.mat \
	-out  ${tempDirSpaceEPI}/${blind}_t1_brain+anat2func
   du -h ${tempDirSpaceEPI}/${blind}_t1_brain+anat2func*

   # apply anat2func to t1-aligned lesion, if lesion was provided:
   if [ -s "`echo ${lesion}`" ]; then
      flirt \
      -in ${tempDirSpaceT1}/${blind}_lesion \
      -ref ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz \
      -applyxfm -init ${tempDir}/${blind}_anat2func.mat \
      -interp nearestneighbour \
      -out  ${tempDirSpaceEPI}/${blind}_lesion+anat2func
      du -h ${tempDirSpaceEPI}/${blind}_lesion+anat2func*
      flirt \
      -in ${tempDirSpaceT1}/${blind}_lesionInverted \
      -ref ${tempDirSpaceEPI}/${blind}_epi_averaged.nii.gz \
      -applyxfm -init ${tempDir}/${blind}_anat2func.mat \
      -interp nearestneighbour \
      -out  ${tempDirSpaceEPI}/${blind}_lesionInverted+anat2func
      du -h ${tempDirSpaceEPI}/${blind}_lesionInverted+anat2func*
   fi

	echo "...done. (`date`)"

fi



echo ""
echo ""
echo ""
echo "-----------------------------------------------------------------"
echo "1) estimating linear+nonlinear transform:    anat2mni"
echo "2) inverting to:                             mni2anat"
echo "-----------------------------------------------------------------"



# ================================================================= #
# calculate linear+nonlinear transformation of t1_brain to template brain:
echo ""
echo ""
echo "anat2mni: estimating, and applying to T1-aligned images (typically < 15 minutes)..."

# Estimate linear transformation first, specifying -inweight if we have a lesion:
if [ -s "`echo ${lesion}`" ]; then
	flirt \
	     -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz \
	     -in ${tempDirSpaceT1}/${blind}_t1_brain \
	     -inweight ${tempDirSpaceT1}/${blind}_lesionInverted \
	     -omat ${tempDir}/${blind}_anat2mni.mat 
else
	flirt \
	     -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz \
	     -in ${tempDirSpaceT1}/${blind}_t1_brain \
	     -omat ${tempDir}/${blind}_anat2mni.mat 
fi

du -h ${tempDir}/${blind}_anat2mni.mat 


# Now estimate the nonlinear transform, using the linear xform as the --aff argument:
#
# NB: It may seem unintuitive that the fnirt input image below is ${blind}_t1 instead of
# the skull stripped ${blind}_t1_brain, but that is the recommendation from FSL's
# documentation: "Note though that the recommended use of fnirt is to not use
# skull-stripped data and to inform fnirt of any affine warps through the --aff
# parameter instead of resampling the data." 
#         -from http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FNIRT/UserGuide
# NB: ignore messages about requested tolerance...unless your transformation turns out horrible, in which case they may have been meaningful)

# TBD: maybe calculate lesionInverted in new space rather than transforming it?
if [ -s "`echo ${lesion}`" ]; then
	fnirt \
	     --in=${tempDirSpaceT1}/${blind}_t1 \
	     --aff=${tempDir}/${blind}_anat2mni.mat \
	     --cout=${tempDir}/${blind}_warp_anat2mni \
	     --config=T1_2_MNI152_2mm \
	     --inmask=${tempDirSpaceT1}/${blind}_lesionInverted 
else
	fnirt \
	     --in=${tempDirSpaceT1}/${blind}_t1 \
	     --aff=${tempDir}/${blind}_anat2mni.mat \
	     --cout=${tempDir}/${blind}_warp_anat2mni \
	     --config=T1_2_MNI152_2mm 
fi

du -h ${tempDir}/${blind}_warp_anat2mni* 

# move fnirt-generated log file from ${tempDirSpaceT1} to ${tempDir}
mv ${tempDirSpaceT1}/*t1_to_MNI152_T1_2mm.log ${tempDir}


# apply to t1:
applywarp \
--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
--in=${tempDirSpaceT1}/${blind}_t1 \
--warp=${tempDir}/${blind}_warp_anat2mni \
--interp=trilinear \
--out=${tempDirSpaceStandard}/${blind}_t1+anat2mni
du -h ${tempDirSpaceStandard}/${blind}_t1+anat2mni*

# apply to t1_brain:
applywarp \
--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
--in=${tempDirSpaceT1}/${blind}_t1_brain \
--warp=${tempDir}/${blind}_warp_anat2mni \
--interp=trilinear \
--out=${tempDirSpaceStandard}/${blind}_t1_brain+anat2mni
du -h ${tempDirSpaceStandard}/${blind}_t1_brain+anat2mni*

# apply to t1 lesion mask:
if [ -s "`echo ${lesion}`" ]; then
   applywarp \
	     	--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
	     	--in=${tempDirSpaceT1}/${blind}_lesion \
	     	--warp=${tempDir}/${blind}_warp_anat2mni \
	     	--interp=nn \
	     	--out=${tempDirSpaceStandard}/${blind}_lesion+anat2mni
	     	du -h ${tempDirSpaceStandard}/${blind}_lesion+anat2mni*
   applywarp \
	     	--ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
	     	--in=${tempDirSpaceT1}/${blind}_lesionInverted \
	     	--warp=${tempDir}/${blind}_warp_anat2mni \
	     	--interp=nn \
	     	--out=${tempDirSpaceStandard}/${blind}_lesionInverted+anat2mni
	     	du -h ${tempDirSpaceStandard}/${blind}_lesionInverted+anat2mni*
fi

echo "...done. (`date`)"


# ================================================================= #
# inversion of nonlinear t1->mni transformation:
echo ""
echo ""
echo "mni2anat: inverting from anat2mni linear+nonlinear, applying to mni152-aligned images (typically < 2 minutes)..."

# invert anat2mni to mni2anat:
invwarp \
--ref=${tempDirSpaceT1}/${blind}_t1 \
--warp=${tempDir}/${blind}_warp_anat2mni \
--out=${tempDir}/${blind}_warp_mni2anat
du -h ${tempDir}/${blind}_warp_mni2anat*


# apply to H-O cortical atlas:
applywarp \
--ref=${tempDirSpaceT1}/${blind}_t1 \
--in=$FSLDIR/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz \
--warp=${tempDir}/${blind}_warp_mni2anat \
--interp=nn \
--out=${tempDirSpaceT1}/HarvardOxford-cort-maxprob-thr25-1mm+mni2anat
du -h ${tempDirSpaceT1}/HarvardOxford-cort-maxprob-thr25-1mm+mni2anat*


# apply to whole-head MNI template:
applywarp \
--ref=${tempDirSpaceT1}/${blind}_t1 \
--in=$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz \
--warp=${tempDir}/${blind}_warp_mni2anat \
--interp=trilinear \
--out=${tempDirSpaceT1}/MNI152_T1_1mm+mni2anat
du -h ${tempDirSpaceT1}/MNI152_T1_1mm+mni2anat*


# apply to skull-stripped MNI template:
applywarp \
--ref=${tempDirSpaceT1}/${blind}_t1 \
--in=$FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz \
--warp=${tempDir}/${blind}_warp_mni2anat \
--interp=trilinear \
--out=${tempDirSpaceT1}/MNI152_T1_1mm_brain+mni2anat
du -h ${tempDirSpaceT1}/MNI152_T1_1mm_brain+mni2anat*

# apply mni2anat to standard-space discrete-intensity (mask) images
#
#    NB: the following requires echo $var, not just $var for ws-sep'd values in
#    $var to be subsequently read as multiple values instead of single value
#    containing ws:
for image in `echo ${sd}`; do
	if [ -s "`echo ${image}`" ]; then
		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
		applywarp \
		--ref=${tempDirSpaceT1}/${blind}_t1 \
		--in=${tempDirSpaceStandard}/${imageBasename} \
		--warp=${tempDir}/${blind}_warp_mni2anat \
		--interp=nn \
		--out=${tempDirSpaceT1}/${imageBasename}+mni2anat
		du -h ${tempDirSpaceT1}/${imageBasename}+mni2anat*
	fi
done

# apply mni2anat to standard-space continuous-intensity (non-mask) images
#
#    NB: the following requires echo $var, not just $var for ws-sep'd values in
#    $var to be subsequently read as multiple values instead of single value
#    containing ws:
for image in `echo ${sc}`; do
	if [ -s "`echo ${image}`" ]; then
		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
		applywarp \
		--ref=${tempDirSpaceT1}/${blind}_t1 \
		--in=${tempDirSpaceStandard}/${imageBasename} \
		--warp=${tempDir}/${blind}_warp_mni2anat \
		--interp=trilinear \
		--out=${tempDirSpaceT1}/${imageBasename}+mni2anat
		du -h ${tempDirSpaceT1}/${imageBasename}+mni2anat*
	fi
done


echo "...done. (`date`)"


# if epi was provided, apply combined transforms to create func2mni and mni2func images:
if [ -s "`echo ${epi}`" ]; then

   echo ""
   echo ""
   echo ""
   echo "-----------------------------------------------------------------"
   echo "1) apply combined transforms as:          func2mni"
   echo "2) invert to:                             mni2func"
   echo "-----------------------------------------------------------------"


	echo ""
	echo ""
	echo "func2mni: applying combined transforms to epi-aligned images (typically < 2 minutes)..."

   # apply func2mni to temporal mean of EPI:
	applywarp \
   --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
   --in=${tempDirSpaceEPI}/${blind}_epi_averaged \
   --warp=${tempDir}/${blind}_warp_anat2mni \
   --premat=${tempDir}/${blind}_func2anat.mat \
   --interp=trilinear \
   --out=${tempDirSpaceStandard}/${blind}_epi_averaged+func2mni
	du -h ${tempDirSpaceStandard}/${blind}_epi_averaged+func2mni*

   # apply func2mni to skull-stripped temporal mean of EPI:
	applywarp \
   --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
   --in=${tempDirSpaceEPI}/${blind}_epi_averaged_brain \
   --warp=${tempDir}/${blind}_warp_anat2mni \
   --premat=${tempDir}/${blind}_func2anat.mat \
   --interp=trilinear \
   --out=${tempDirSpaceStandard}/${blind}_epi_averaged_brain+func2mni
	du -h ${tempDirSpaceStandard}/${blind}_epi_averaged_brain+func2mni*


   # apply func2mni to EPI-aligned discrete-intensity (mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${ed}`; do
      if [ -s "`echo ${image}`" ]; then
         imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
         applywarp \
         --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
         --in=${tempDirSpaceEPI}/${imageBasename} \
         --warp=${tempDir}/${blind}_warp_anat2mni \
         --premat=${tempDir}/${blind}_func2anat.mat \
         --interp=nn \
         --out=${tempDirSpaceStandard}/${imageBasename}+func2mni
         du -h ${tempDirSpaceStandard}/${imageBasename}+func2mni*
      fi
   done

   # apply func2mni to EPI-aligned continuous-intensity (non-mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${ec}`; do
      if [ -s "`echo ${image}`" ]; then
         imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
         applywarp \
         --ref=${FSLDIR}/data/standard/MNI152_T1_1mm \
         --in=${tempDirSpaceEPI}/${imageBasename} \
         --warp=${tempDir}/${blind}_warp_anat2mni \
         --premat=${tempDir}/${blind}_func2anat.mat \
         --interp=trilinear \
         --out=${tempDirSpaceStandard}/${imageBasename}+func2mni
         du -h ${tempDirSpaceStandard}/${imageBasename}+func2mni*
      fi
   done


   echo "...done. (`date`)"


	echo ""
	echo ""
	echo "mni2func: applying inverted transforms to MNI-aligned images (typically < 2 minutes)..."


   # create mni2func version of skull-stripped MNI template:
   applywarp \
   --ref=${tempDirSpaceEPI}/${blind}_epi_averaged \
   --in=${FSLDIR}/data/standard/MNI152_T1_1mm_brain \
   --warp=${tempDir}/${blind}_warp_mni2anat \
   --postmat=${tempDir}/${blind}_anat2func.mat \
   --interp=trilinear \
   --out=${tempDirSpaceEPI}/MNI152_T1_1mm_brain+mni2func
   du -h ${tempDirSpaceEPI}/MNI152_T1_1mm_brain+mni2func*

   # create mni2func version of un-skull-stripped MNI template:
   applywarp \
   --ref=${tempDirSpaceEPI}/${blind}_epi_averaged \
   --in=${FSLDIR}/data/standard/MNI152_T1_1mm \
   --warp=${tempDir}/${blind}_warp_mni2anat \
   --postmat=${tempDir}/${blind}_anat2func.mat \
   --interp=trilinear \
   --out=${tempDirSpaceEPI}/MNI152_T1_1mm+mni2func
   du -h ${tempDirSpaceEPI}/MNI152_T1_1mm+mni2func*

   # create mni2func version of discrete H-O cortical atlas:
   applywarp \
   --ref=${tempDirSpaceEPI}/${blind}_epi_averaged \
   --in=${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz \
   --warp=${tempDir}/${blind}_warp_mni2anat \
   --postmat=${tempDir}/${blind}_anat2func.mat \
   --interp=nn \
   --out=${tempDirSpaceEPI}/HarvardOxford-cort-maxprob-thr25-1mm+mni2func
   du -h ${tempDirSpaceEPI}/HarvardOxford-cort-maxprob-thr25-1mm+mni2func*


   # apply mni2func to standard-space discrete-intensity (mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${sd}`; do
   	if [ -s "`echo ${image}`" ]; then
   		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
   		applywarp \
   		--ref=${tempDirSpaceEPI}/${blind}_epi_averaged \
   		--in=${tempDirSpaceStandard}/${imageBasename} \
   		--warp=${tempDir}/${blind}_warp_mni2anat \
         --postmat=${tempDir}/${blind}_anat2func.mat \
   		--interp=nn \
   		--out=${tempDirSpaceEPI}/${imageBasename}+mni2func
   		du -h ${tempDirSpaceEPI}/${imageBasename}+mni2func*
   	fi
   done
   
   # apply mni2func to standard-space continuous-intensity (non-mask) images
   #
   #    NB: the following requires echo $var, not just $var for ws-sep'd values in
   #    $var to be subsequently read as multiple values instead of single value
   #    containing ws:
   for image in `echo ${sc}`; do
   	if [ -s "`echo ${image}`" ]; then
   		imageBasename="`echo ${image} | xargs basename | xargs ${FSLDIR}/bin/remove_ext`"
   		applywarp \
   		--ref=${tempDirSpaceEPI}/${blind}_epi_averaged \
   		--in=${tempDirSpaceStandard}/${imageBasename} \
   		--warp=${tempDir}/${blind}_warp_mni2anat \
         --postmat=${tempDir}/${blind}_anat2func.mat \
   		--interp=trilinear \
   		--out=${tempDirSpaceEPI}/${imageBasename}+mni2func
   		du -h ${tempDirSpaceEPI}/${imageBasename}+mni2func*
   	fi
   done


   echo "...done. (`date`)"

fi



echo ""
echo ""
echo "================================================================="
echo "FINISHED: nonlinear registration of ${blind} to 1mmMNI152 "
      date
echo "================================================================="
echo ""
echo ""

# cp important output from $tempDir to $outDir:
if [ -n ${outDir} ]; then 
	mkdir -p ${outDir} &> /dev/null
	#cp ${tempDir}/*.nii.gz ${outDir}/ &> /dev/null
	#cp ${tempDir}/*.nii ${outDir}/ &> /dev/null
	#cp ${tempDir}/*.mat ${outDir}/ &> /dev/null
	cp -R ${tempDirSpaceT1}       ${outDir}/ &> /dev/null
	cp -R ${tempDirSpaceEPI}      ${outDir}/ &> /dev/null
	cp -R ${tempDirSpaceStandard} ${outDir}/ &> /dev/null
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
	tempDirSize=`du -sh ${tempDir} | awk '{print $1}'`
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


# give advice on inspecting output:
# (TBD: make this automatic if interactive mode is enabled)

echo ""
echo ""
echo "To inspect some of your MNI152-aligned output images in fslview with"
echo "reasonable color choices, paste this block of commands into the terminal:"

if [ -s "`echo ${epi}`" ]; then
   cat <<EOF

   standardTemplate=$FSLDIR/data/standard/MNI152_T1_1mm
   warpedT1=${finalDir}/${subdirNameSpaceStandard}/${blind}_t1_brain+anat2mni
   warpedEPI=${finalDir}/${subdirNameSpaceStandard}/${blind}_epi_averaged_brain+func2mni
   atlas=${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
   bottomLayer=\${standardTemplate}
   middleLayer=\${warpedT1}
   topLayer=\${warpedEPI}
   atlasLayer=\${atlas}
   fslview -m ortho \${bottomLayer} -l Green \${middleLayer} -l Pink \${topLayer} -l Greyscale \${atlasLayer} -l MGH-Cortical -t 0.5 &

EOF

else
   cat <<EOF

   standardTemplate=$FSLDIR/data/standard/MNI152_T1_1mm
   warpedT1=${finalDir}/${subdirNameSpaceStandard}/${blind}_t1_brain+anat2mni
   atlas=${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz
   bottomLayer=\${standardTemplate}
   middleLayer=\${warpedT1}
   atlasLayer=\${atlas}
   fslview -m ortho \${bottomLayer} -l Green \${middleLayer} -l Pink \${atlasLayer} -l MGH-Cortical -t 0.5 &

EOF

fi


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


