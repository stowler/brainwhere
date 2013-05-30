#!/bin/bash
#
# bwLevelwise-testNetShort.sh
#
# USAGE: bwTestNetShort-levelwise.sh <storage: either "local" or "remote"> <a temporary directory where this script has write perms>
#
# This is designed to be the -s scriptName argument in this call:
# bwProcessLevelsOfOneFactor.sh \
# -f locationOfInputData
# -l local,remote
# -s (this script: bwLevelwise-testNetShort.sh)

# 0) Process invocation:
storage=${1}
tempDir=${2}
hostname=`hostname -s`

# 1) create the direcotry where this levelwise data will reside:
rm -fr ${tempDir}/levelOutputRaw
rm -fr ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
mkdir ${tempDir}/levelOutputRaw

# 2) perform test:
nameOfTest=fslNonzeroEntropy

# ...first set variables contingent on the arguments:
if [ "${storage}" = "local" ]; then
	imageDir=${FSLDIR}/data/standard
	nameOfStorage=local.${hostname}
elif [ "${storage}" = "remote" ]; then
	#imageRootDir=/data/forNetworkTesting/brainwhere/utilitiesAndData/imagesFromFSL
	# DEBUG: fake hippostore for the moment:
	imageDir=${FSLDIR}/data/standard
	nameOfStorage=remote.hippostoreNFS
fi
image=${imageDir}/MNI152_T1_1mm_brain.nii.gz

# ...perform the timed test:
( time -p fslstats ${image} -E >> ${tempDir}/levelOutputRaw/fslstats_entropy.txt ) 2> ${tempDir}/levelOutputRaw/elapsedTime.txt

# 3) extract data from the test results:
resultNonzeroEntropy=`head -1 ${tempDir}/levelOutputRaw/fslstats_entropy.txt | awk '{print $1}'`
elapsedSeconds=`head -1 ${tempDir}/levelOutputRaw/elapsedTime.txt | awk '{print $2}'`
 
# 4) assemble header row and corresponding data row:
rowHeader="nameOfTest,elapsedSeconds,nameOfStorage,resultNonzeroEntropy"
rowSingleLevelData="${nameOfTest},${elapsedSeconds},${nameOfStorage},${resultNonzeroEntropy}"

# 5) output to a levelwise text file with a filename that is expected by external summary/loop scripts:
#    singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowHeader}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowSingleLevelData}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv

cat ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv | column -s , -t
# return value (TBD?): file path to singleLevelOutputVectorForComparisonAcrossLevels.csv
