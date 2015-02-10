MoAE images were downloaded from
http://www.fil.ion.ucl.ac.uk/spm/data/auditory/ as analyze volumes, and
processed into their current form with "fslmerge -a", fslchfiletype, and
fslreorient2std.

MoAE_t1_brain.nii.gz is an imprecise extraction created using bet from FSL
5.0.8, and bet options "-f 0.40 -B"

MoAE_epi_tstd.nii.gz was created with fslmaths -Tstd

MoAE_epi_funcROI.nii.gz has six mask intensity values and was manually drawn in
itksnap 3.2.0 (OS X).

MoAE_lesionT1LeftSloppyHG.nii.gz has one mask intensity value and was manually drawn in
itksnap 3.2.0 (OS X).
