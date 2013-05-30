#!/bin/bash
#
# bwLevelwise-testNetMed.sh
#
# USAGE: bwTestNetShort-levelwise.sh <storage: either "local" or "remote"> <a temporary directory where this script has write perms>
#
# This is designed to be the -s scriptName argument in this call:
# bwProcessLevelsOfOneFactor.sh \
# -f locationOfInputData
# -l local,remote
# -s (this script: bwLevelwise-testNetMed.sh)

# 0) Process invocation:
storage=${1}
tempDir=${2}
hostname=`hostname -s`

# 1) create the direcotry where this levelwise data will reside:
rm -fr ${tempDir}/levelOutputRaw
rm -fr ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
mkdir ${tempDir}/levelOutputRaw

# 2) perform test:
nameOfTest=fslBet-R

# ...first set variables contingent on the arguments:
if [ "${storage}" = "local" ]; then
	inputImageDir=${FSLDIR}/data/standard
	nameOfStorage=local.${hostname}
elif [ "${storage}" = "remote" ]; then
	#inputImageDir=/data/forNetworkTesting/brainwhere/utilitiesAndData/imagesFromFSL
	# DEBUG: fake hippostore for the moment:
	inputImageDir=${FSLDIR}/data/standard
	nameOfStorage=remote.hippostoreNFS
fi
inputImage=${inputImageDir}/MNI152_T1_1mm.nii.gz

# ...perform the timed test:
( time -p bet ${inputImage} ${tempDir}/levelOutputRaw/extractedBrain -B -v ) 2>${tempDir}/levelOutputRaw/elapsedTime.txt

# 3) extract data from the test results:
resultBetVoxInBrain=`fslstats ${tempDir}/levelOutputRaw/extractedBrain -V | awk '{print $1}'`
elapsedSeconds=`head -1 ${tempDir}/levelOutputRaw/elapsedTime.txt | awk '{print $2}'`
 
# 4) assemble header row and corresponding data row:
rowHeader="nameOfTest,elapsedSeconds,nameOfStorage,resultBetVoxInBrain"
rowSingleLevelData="${nameOfTest},${elapsedSeconds},${nameOfStorage},${resultBetVoxInBrain}"

# 5) output to a levelwise text file with a filename that is expected by external summary/loop scripts:
#    singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowHeader}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowSingleLevelData}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv

cat ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv | column -s , -t
# return value (TBD?): file path to singleLevelOutputVectorForComparisonAcrossLevels.csv
