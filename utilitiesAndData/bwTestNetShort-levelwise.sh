#!/bin/bash
#
# A small trivial scipt to find the disk usage of a folder. Generated
# during fxnSelftestFull().
#
# USAGE: exampleLevelwiseScript.sh [the name of the folder to examine] [tempdir for output]
#

# Process invocation:
storage=${1}
tempDir=${2}
hostname=`hostname -s`
#
# 1) create the direcotry where this levelwise data will reside:
rm -fr ${tempDir}/levelOutputRaw
rm -fr ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
mkdir ${tempDir}/levelOutputRaw
#
# 2) perform test:
nameOfTest=fslNonzeroEntropy
if [ "${storage}" = "local" ]; then
	imageDir=${FSLDIR}/data/standard
	nameOfStorage=local.${hostname}
elif [ "${storage}" = "remote" ]; then
	#imageRootDir=/data/forNetworkTesting/brainwhere/utilitiesAndData/imagesFromFSL
	# DEBUG: fake hippostore:
	imageDir=${FSLDIR}/data/standard
	nameOfStorage=local.${hostname}
	nameOfStorage=remoteHippostoreNFS
fi
image=${imageDir}/MNI152_T1_1mm_brain.nii.gz
resultNonzeroEntropy=`fslstats ${image} -E`
 
# assemble header row and corresponding data row:
rowHeader="nameOfTest,nameOfStorage,resultNonzeroEntropy"
rowSingleLevelData="${nameOfTest},${nameOfStorage},${resultNonzeroEntropy}"
#
# 5) output to a levelwise text file with a filename that is expected by external summary/loop scripts:
#    singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowHeader}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv
echo "${rowSingleLevelData}" >> ${tempDir}/singleLevelOutputVectorForComparisonAcrossLevels.csv

# return value (TBD?): file path to singleLevelOutputVectorForComparisonAcrossLevels.csv
