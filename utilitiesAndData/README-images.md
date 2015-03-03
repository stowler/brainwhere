Sample images from AFNI, FSL, and SPM are used by scripts in this repo.

# AFNI sample images

## single-session data: "FT"

AFNI's [AFNI_data6.tgz sample data](http://afni.nimh.nih.gov/pub/dist/edu/data/AFNI_data6.tgz) contains a single session anatomic + EPI dataset. It is used in their tutorial ["AFNI Start to Finish"](http://afni.nimh.nih.gov/pub/dist/edu/latest/afni_handouts/afni16_start_to_finish.pdf).

I created RPI-reoriented nifti copies of their FT T1 anatomic volume and three EPI timeseries:

```
- EPI slice-timing:     intact
- EPI slice plane:      axial
- EPI qty runs:         3
- EPI TR length:        2 s
- EPI TR qty:           152 per run
- EPI TRs to remove:    2 TRs
- hemisphere marker:    none
- DICOMS:               not available
- processing history:   not available
- orientation:          RPI via 3dresample -orient RPI
```

Derived images: 

FT_anat_brain.nii.gz is an imprecise extraction created using bet from FSL
5.0.8, and bet options "-f 0.40 -B"


## single-session data: "data3" (maybe sb23 ?)

AFNI's [AFNI_data3.tgz sample data](http://afni.nimh.nih.gov/pub/dist/edu/data/AFNI_data3.tgz) contains a single-session anatomic + EPI dataset. It is used in their tutorial ["Where do AFNI Datasets Come From?"](http://afni.nimh.nih.gov/pub/dist/edu/latest/afni02_to3d/afni02_to3d.pdf). I have a strong suspicion this is also the "sb23" session available in [AFNI_data4.tgz sample data](http://afni.nimh.nih.gov/pub/dist/edu/data/AFNI_data4.tgz) and referenced in AFNI's afni_proc.py [help page](http://afni.nimh.nih.gov/pub/dist/doc/program_help/afni_proc.py.html).

I created RPI-reoriented nifti copies of their data3 T1 anatomic volume and single EPI timeseries:

```
- EPI slice-timing:     intact
- EPI slice plane:      axial
- EPI qty runs:         1
- EPI TR length:        3 s
- EPI TR qty:           67 per run
- EPI TRs to remove:    3 (per AFNI_data4/proc.sb23.blk)
- hemisphere marker:    none
- DICOMS:               available
- processing history:   available via 3dinfo
- orientation:          RPI via 3dresample -orient RPI
```

Derived images: 

data3_anat_brain.nii.gz is an imprecise extraction created using bet from FSL
5.0.8, and bet options "-f 0.40 -B"



# FSL sample images

TBD

# SPM sample images


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
