#!/bin/sh

# This script is just a convenient way to nifti-fy all of a project's sessions
# by calling bwDicomToFslNifti-oneSession.sh for each of them.
#
# Sessions are niftified in serial (see for loop below), but within each
# session individual series may be niftified in parallel via argument in call
# to bwDicomToFslNifti-oneSession.sh


fxnNiftifyOneSession(){
  bwDicomToFslNifti-oneSession.sh \
  ${dicomDirSession} \
  ${sessionName} \
  ${niftiDirSession} \
  ${parallelDicomDirs}
}

# Below, "groomed" just means that each sessiondir has been named with a consistently
# formatted participantSessionID (e.g., p0000s01)
#
# $dicomDirProjectUngroomed
# $dicomDirProjectGroomed
#    $dicomDirSession
#       $dicomDirSeries
#           (individual DICOM files)
#


############  INPUT: DICOMS ############
# parent directory that contains well-named session directories (see above)
# dicomDirProjectGroomed=$1
dicomDirProjectGroomed=/data/tmpJoe/exportedFromDicomStore/groomedForNiftiConversion


############  OUTPUT: NIFTIs ############
# output directory where each session's folder full of niftis will go:
# niftiDirProject=$2
niftiDirProject=/data/tmpJoe/acqfiles-nifti
#outputNiftiParent=/data/tmpJoe/acqfiles-nifti


# number of dicomdirs to attempt simultaneously:
# (gets passed to bwDicomToFslNifti-oneSession.sh)
parallelDicomDirs=0

# in serial, convert every groomed $dicomDirSession to a new $niftiDirSession
for sessionName in `basename ${dicomDirProjectGroomed}/*`; do
   dicomDirSession=${dicomDirProjectGroomed}/${sessionName}
   niftiDirSession=${niftiDirProject}/${sessionName}
   rm -fr ${niftiDirSession}
   mkdir -p ${niftiDirSession}
   fxnNiftifyOneSession
done
