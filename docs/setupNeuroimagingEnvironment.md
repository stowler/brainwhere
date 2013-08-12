setupNeuroimagingEnvironment.md
==========

stowler@gmail.com
updated: 20130524


My neuroimaging scripts and documentation refer to these open-source neuroimaging resources:

* neurodebian virtual machine
* fsl
* afni
* BXH/XCEDE tools (from FBIRN)
* freesurfer
* itksnap
* mricron
* mricrogl
* imagej/fiji
* spm

This document describes how to deploy these resources in the three computing environments I currently use:

* OS X Mountain Lion + MacPorts
* Neurodebian on Ubuntu 12.04 on 64-bit processors
* Neurodebian VM, running Debian 7.0 wheezy 32-bit on VirtualBox

[This basic set of system utilities](http://goo.gl/ncbZD) must be installed prior to following these instructions.

Once these neuroimaging packages have been installed and tested you could also follow [these instructions](http://goo.gl/gwZCv) to install my personal repository of neuroimaging scripts.


Neurodebian Virtual Machine (VM)
===================================

1. Download the [neurodebian VM .ova/.ovf](http://neuro.debian.net/):
 * click "Get Neurodebian"
 * Select operating system: Mac or Windows
 * Download the Debian 7.0 .ova or zip/ovf file (I prefer the 32-bit version. Easier to distribute to heterogeneous hardware).

2. Download and install the latest [VirtualBox binaries](https://www.virtualbox.org/wiki/Downloads).

3. Follow the neurodebian [install instructions](http://neuro.debian.net/vm.html#chap-vm), which they support with a [youtube video](http://www.youtube.com/watch?v=eqfjKV5XaTE).

4. Boot up the new virtual machine. Don't bother to select any new packages from the point-and-click wizard that autoruns.



FSL
==================

Install FSL on Mac OS X Mountain/Lion:
----------------------------------------------------------------

Before installing FSL, freesurfer, or  AFNI on Mountain/Lion be doulbe-sure you have installed [XQuartz](http://xquartz.macosforge.org), and loged out and then back in.


Google "FSL install" and [follow instructions](http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/MacOsX#Downloading_the_install_file_without_installing_the_software)


There are multiple ways to install (as of May 2013). I get mixed results with the recommended fslinstaller.py, but I typically use it and then just fix whatever didn't work.

1. Run FSL's installer script in  "download only" mode (about 1-hr):

    ```
    cd ~/Downloads
    python fslinstaller.py -o
    ```

2. Calculate the md5 sum of the downloaded file and use it to launch installation:

    ```
    fslDownload=fsl-5.0.2.2-macosx.tar.gz
    fslDestDir="/usr/local"
    fslMD5=`md5 ${fslDownload} | awk '{ print $NF}'` 
    python fslinstaller.py -d ${fslDestDir} -f ${fslDownload} -C ${fslMD5}
    ```

3. After the install completes, confirm that the file /etc/bashrc received a block of FSL environmental variables (below). If not, the install program may have added it to your personal ~/.profile or ~/.bash_profile instead.

For system-wide installation, remove from those files and append to /etc/bashrc:



    #    WARNING: note the \${escapedVariables} below, which
    #    are escaped for heredoc (http://goo.gl/j3HMJ). 
    #    Un-escape them if manually typing into a text editor.
    #    Otherwise, just paste these lines to your bash prompt
    #    (up to and including "EOF" line):
    #
    editDate=`/bin/date +%Y%m%d`
    editTime=$(date +%k%M)
    sudo tee -a /etc/bashrc >/dev/null <<EOF
    #------------------------------------------
    # on ${editDate} at ${editTime}, $USER 
    # added some FSL setup:
    FSLDIR=/usr/local/fsl
    PATH=\${FSLDIR}/bin:\${PATH}
    export FSLDIR PATH
    . \${FSLDIR}/etc/fslconf/fsl.sh
    #------------------------------------------
    EOF
    cat /etc/bashrc 
 

Either log out and back in again, or issue this terminal command:

     . /etc/bashrc

TEST: did $FSLDIR get exported correctly? This should return "/usr/local/fsl" (no quotes) :

     echo $FSLDIR

TEST: Does fslview exist in /Applications?

    ls /Applications
    # ...if not create a shortcut like this:
    sudo ln -s /usr/local/fsl/bin/fslview.app /Applications/fslview.app

TEST: we should be able to open /Applications/fslview.app from the commandline:

     open /Applications/fslview.app

TEST: we should be able to open fslview.app from the commandline :

     fslview ${FSLDIR}/data/standard/MNI152_T1_2mm_LR-masked.nii.gz



Install FSL on Ubuntu 12.04:
-----------------------------------------------------------------

I am currently happy with the version in the neurodebian repos:

    sudo apt-get install fsl-complete fsl-feeds

...but previous to fsl-completed, you needed to install separate packages:

    sudo apt-get instal fsl-atlases fsl-feeds fsl-first-data fslview and fsl-feeds?

After installation of the packages, get instructions for environmental variables (e.g., may need to source AFNI/FSL script from /etc/bash.bashrc)

    man fsl



Install FSL on Debian 7.0 Wheezy Neurodebian VM:
------------------------------------------------------------

I am currently happy with the version in the neurodebian repos:

    sudo apt-get install fsl-complete fsl-feeds

...but previous to fsl-completed, you needed to apt-get install separate packages:

    sudo apt-get install fsl-atlases fsl-feeds fsl-first-data fslview and fsl-feeds
    
After installation of the packages, get instructions for environmental variables (e.g., may need to source AFNI/FSL script from /etc/bash.bashrc)

    man fsl

After the install completes, confirm whether the file /etc/bash.bashrc received a block of FSL environmental variables (below). If not, the install program may have added it to your personal ~/.profile or ~/.bash_profile instead. For system-wide installation, remove from those files and append to /etc/bash.bashrc:

    cat /etc/bashrc
    #
    # No FSL environmental variables in /etc/bashrc ? Add them by pasting these lines into the terminal:
    #
    #    WARNING: note the \${escapedVariables} below, which
    #    are escaped for heredoc (http://goo.gl/j3HMJ). 
    #    Un-escape them if manually typing into a text editor.
    #    Otherwise, just paste these lines to your bash prompt
    #    (up to and including "EOF" line):
    #
    editDate=`/bin/date +%Y%m%d`
    editTime=$(date +%k%M)
    sudo tee -a /etc/bash.bashrc >/dev/null <<EOF
    #------------------------------------------
    # on ${editDate} at ${editTime}, $USER 
    # added some FSL setup:
    . /etc/fsl/5.0/fsl.sh
    #------------------------------------------
    EOF
    #
    cat /etc/bashrc 



Install and run FSL test suite ("FEEDS"):
---------------------------------------------------------------

Download [FEEDS from FSL > 270 MB](http://fsl.fmrib.ox.ac.uk/fsldownloads/)
OR neurodebian can download via command:

    sudo apt-get install fsl-feeds

[Run FEEDS](http://fsl.fmrib.ox.ac.uk/fsl/feeds/doc/):

    # (on neurodebian, this is all replaced by command fsl-selftest or /usr/bin/time fsl-selftest)
    # 2013 i7 imac:  971.77 real  951.78 user 22.83 sys
    # 2012 i7 rMBP: 1108.44 real 1080.64 user 31.06 sys
    cd ~/Downloads       # (or the folder where you saved your download)
    tar -zxvf fsl-*-feeds.tar.gz
    cd feeds
    /usr/bin/time ./RUN all



AFNI
==========

Installing AFNI on Mac OS X Mountain/Lion:
------------------------------------------------------------

Before installing FSL, freesurfer, or  AFNI on Mountain/Lion be sure to install [XQuartz](http://xquartz.macosforge.org), and logout and then back in. 

Then download latest AFNI for Mac, unzip, and move to a reasonable location: 

    cd ~/Downloads
    curl -O http://afni.nimh.nih.gov/pub/dist/tgz/macosx_10.7_Intel_64.tgz
    tar -zxvf macosx_10.7_Intel_64.tgz
    sudo mv macosx_10.7_Intel_64 /usr/local/abin

Add AFNI's new location to the path in /etc/bashrc :

    #    WARNING: note the \${escapedVariables} below, which
    #    are escaped for heredoc (http://goo.gl/j3HMJ). 
    #    Un-escape them if manually typing into a text editor.
    #    Otherwise, just paste these lines to your bash prompt
    #    (up to and including "EOF" line):
    #
    editDate=`/bin/date +%Y%m%d`
    editTime=$(date +%k%M)
    sudo tee -a /etc/bashrc >/dev/null <<EOF
    #------------------------------------------
    # on ${editDate} at ${editTime}, $USER  
    # added some AFNI environmental variables:
    export PATH=/usr/local/abin:\${PATH}
    export AFNI_ENFORCE_ASPECT=YES
    #------------------------------------------
    EOF
    #
    cat /etc/bashrc

Either log out and back in again, or issue this terminal command:

    . /etc/bashrc 

TEST: Open a new terminal window and test your afni install by issuing the command "afni" (no quotes) to open GUI. Confirm whether AFNI_ENFORCE_ASPECT is working effectively (see below)



Installing AFNI on Ubuntu 12.04:
-----------------------------------------------------------------

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install afni afni-atlases

...then "man afni" to get instructions for environmental variables (e.g., may need to source AFNI/FSL script from /etc/bash.bashrc)

In the event that the Neurodebian version of AFNI is broken/old/whatever 
you may want to substitute a binary version from outside of Neurodebian. Two steps to do that:


1. Download,  unzip, and move to a reasonable destination (not overwriting Neurodebian's AFNI in the process):

    ```
    curl -O http://afni.nimh.nih.gov/pub/dist/tgz/linux_xorg7_64.tgz  # (> 600 MB)
    tar -zxvf linux_xorg7_64.tgz    # ...results in directory called linux_xorg7_64
    mv linux_xorg7_64 /opt/abin     # ...simultaneous move and rename of directory
    ```
    
2. Kill Neurodebian's AFNI environmental variables and add this new directory to $PATH (see below)


Installing AFNI on Debian 7.0 Wheezy Neurodebian VM:
---------------------------------------------------------------

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install afni afni-atlases

...then "man afni" to get instructions for environmental variables
(e.g., may need to source AFNI/FSL script from /etc/bash.bashrc)

    # For system-wide install, source the AFNI config file from /etc/afni/afni.sh :
    #
    #    WARNING: note the \${escapedVariables} below, which
    #    are escaped for heredoc (http://goo.gl/j3HMJ). 
    #    Un-escape them if manually typing into a text editor.
    #    Otherwise, just paste these lines to your bash prompt
    #    (up to and including "EOF" line):
    #
    editDate=`/bin/date +%Y%m%d`
    editTime=$(date +%k%M)
    sudo tee -a /etc/bash.bashrc >/dev/null <<EOF
    #------------------------------------------
    # on ${editDate} at ${editTime}, $USER  
    # added some AFNI environmental variables:
    . /etc/afni/afni.sh
    #------------------------------------------
    EOF
    #
    cat /etc/bashrc


Checking and Setting env variable AFNI_ENFORCE_ASPECT :
---------------------------------------------------------------

In some environments the AFNI GUI allows you to accidentally distort image aspect ratio by resizing an image window. Not good, but avoidable:

First here's a reminder of how to read and set AFNI environmental variables:

    afni -help | grep Vname
    afni -help | grep Dname

If the following command returns no output, the variable AFNI_ENFORCE_ASPECT isn't set [sic: yes, this command should end with "=" as written here:]

    afni -VAFNI_ENFORCE_ASPECT= 

To set AFNI_ENFORCE_ASPECT on a per-execution basis, can launch the afni GUI with:

    afni -DAFNI_ENFORCE_ASPECT=YES


Unsetting AFNI environmental variables:
----------------------------------------------------------

Sometimes you need to clear AFNI-related environmental variables, for example 
if Neurodebian is installed but you need to temporarily use a more up-to-date version of AFNI:

1. Unset current AFNI environmental variables:

    ```
    unset `env | awk -F= '/AFNI/ {print $1}' | xargs`
    ```
    
2. Prepend this new AFNI directory to your ${PATH}, so that its program are found before the programs from the old versio of AFNI:

    ```
    export PATH=/opt/abin:${PATH}
    ```
    
3. TEST: check that the "right" AFNI will run:

    ```
    which afni
    which 3dinfo
    ```
    
 4. Comment out any of the existing AFNI lines in the /etc/bashrc or /etc/bash.bashrc, and add the new location so that it can continue to be found after logging out and back in again.


BXH/XCEDE FBIRN TOOLS
=======================


Install FBIRN BXH/XCEDE tools on Mac OS X Mountain/Lion:
-----------------------------------------------------------------

As of May 2013, the shipping binaries of BXH/XCEDE tools includes imagemagick bugs on Mountain Lion.

I wrote an installation script that [describes the problem](http://goo.gl/Nalzn) and provides a workaround via macports.

1. Follow the steps in [my workaround install script](http://goo.gl/9Rd6V), then confirm the changes to /etc/bashrc:

      ```
      cat /etc/bashrc
      ```
      
2. Either log out and back in again, or issue this terminal command:

     ```
     . /etc/bashrc
     ```

3. TEST: did $BXHDIR get exported correctly? This should return a listing of bxh programs :

      ```
      ls $BXHDIR
      ```


Installing BXH/XCEDE tools on Debian Linux 7.0 Wheezy Neurodebian VM
-----------------------------------------------------------------

1. manualy download most recent bxh/xcede release from nitrc: http://www.nitrc.org/projects/bxh_xcede_tools

     ```
     $ ls -l ~/Downloads/bxh_xcede_tools-*.tgz
     bxh_xcede_tools-1.10.7-lsb31.i386.tgz
     ```
     
2. unpack and install bxh/xcede:

     ```
     # ...first declare the bxh version as it appears in the download filename:
     bxhVersion=1.10.7
     
     # ...then unpack and install:
     cd ~/Downloads
     tar -zxvf bxh_xcede_tools-${bxhVersion}-lsb31.i386.tgz
     sudo mv bxh_xcede_tools-${bxhVersion}-lsb31.i386 /opt/
     sudo ln -s /opt/bxh_xcede_tools-${bxhVersion}-lsb31.i386 /opt/bxh
     ```
     
3. For system-wide access, configure the environment via /etc/bash.bashrc :

     ```
     #    WARNING: note the \${escapedVariables} below, which
     #    are escaped for heredoc (http://goo.gl/j3HMJ). 
     #    Un-escape them if manually typing into a text editor.
     #    Otherwise, just paste these lines to your bash prompt
     #    (up to and including "EOF" line):
     #
     editDate=`/bin/date +%Y%m%d`
     editTime=$(date +%k%M)
     sudo tee -a /etc/bash.bashrc >/dev/null <<EOF
     #------------------------------------------
     # on ${editDate} at ${editTime}, $USER 
     # added some BXH/XCEDE environment statements:
     BXHDIR=/opt/bxh
     PATH=\${BXHDIR}/bin:\${PATH}
     export BXHDIR PATH
     #------------------------------------------
     EOF
     ```

4. Either log out and back in again, or issue this terminal command:

     ```
     . /etc/bashrc
     ```
     
5. TEST: did $BXHDIR get exported correctly? This should return a listing of bxh programs :

      ```
      ls $BXHDIR
      ```

FreeSurfer
===============
(WARNINING: Stable 5.2 release WITHDRAWN awaiting upcoming version 5.3)

If you haven't done so already, obtain a license, and copy the .license file to your 
$FREESURFER_HOME directory per https://surfer.nmr.mgh.harvard.edu/registration.html


Installing FreeSurfer on Mac OS X Mountain/Lion:
-----------------------------------------------------------------

1. Before installing freesurfer on Mountain/Lion be sure to install [XQuartz](http://xquartz.macosforge.org)
and FSL (b/c FS's install will detect location of FSL).

2. [Download](http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall) latest .dmg from the Freesurfer Wiki. This can also be done from the commandline instead of the webpage:

      ```
      fsFtpDir="ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.2.0"
      fsFtpFilename="freesurfer-Darwin-lion-stable-pub-v5.2.0.dmg"
      cd ~/Downloads
      curl -O ${fsFtpDir}/${fsFtpFilename}
     
      # …and to resume a failed download:
      curl -C - -o ${fsFtpFilename} ${fsFtpDir}/${fsFtpFilename}
      ```
      
3. Confirm that the download is valid:

     ```
     sh <<EOF
     curl -s -o freesurfer_md5sums.txt http://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/md5sum.txt
     echo ""
     echo "expected md5 sum:"
     grep ${fsFtpFilename} freesurfer_md5sums.txt
     echo ""
     echo "md5sum of downloaded ${fsFtpFilename}:"
     md5 ${fsFtpFilename}
     echo ""
     echo "(re-download if they don't match)"
     echo ""
     EOF
     ```
 
4. Doubleclick on the .dmg and run the .pkg installation file found inside of it. 
   [Detailed instructions](http://surfer.nmr.mgh.harvard.edu/fswiki/Installation) are available if you want them.
   (Note the folder that this installs to, likely /Applications/freesurfer, which you will assign to $FREESURFER_HOME below.)

5. add post-install config to /etc/bashrc per the bash section of the freesurfer [documentation](http://surfer.nmr.mgh.harvard.edu/fswiki/SetupConfiguration) :

     ```
     #
     #    WARNING: note the \${escapedVariables} below, which
     #    are escaped for heredoc (http://goo.gl/j3HMJ). 
     #    Un-escape them if manually typing into a text editor.
     #    Otherwise, just paste these lines to your bash prompt
     #    (up to and including "EOF" line):
     #
     editDate=`/bin/date +%Y%m%d`
     editTime=$(date +%k%M)
     sudo tee -a /etc/bashrc >/dev/null <<EOF
     #------------------------------------------
     # on ${editDate} at ${editTime}, $USER   
     # added some freesurfer environmental variables:
     export FREESURFER_HOME=/Applications/freesurfer
     . \${FREESURFER_HOME}/SetUpFreeSurfer.sh
     #------------------------------------------
     EOF
     
     cat /etc/bashrc 
     ```

4. Copy the sample data to a place where users can write to it:

     ```
     cp -a $SUBJECTS_DIR /Users/Shared/fs_sampleSubjects
     ```

5. Edit ${FREESURFER_HOME}/SetUpFreeSurfer.sh to reflect the change in $SUBJECTS_DIR, then
   either log out and back in again, or issue this terminal command:

     ```
     . /etc/bashrc 
     ```
 
6. TEST: open a new terminal window. You should see a number of freesurfer-related lines at the top of the new terminal window, and all the terminal windows you open after that.

7. TESTS: Test your installation by issuing the test commands detailed on the [Testing Freesurfer webpage](http://surfer.nmr.mgh.harvard.edu/fswiki/TestingFreeSurfer ).

      ```
      # TEST freeview:
      freeview \
      -v $SUBJECTS_DIR/bert/mri/norm.mgz \
      -v $SUBJECTS_DIR/bert/mri/aseg.mgz:colormap=lut:opacity=0.2 \
      -f $SUBJECTS_DIR/bert/surf/lh.white:edgecolor=yellow \
      -f $SUBJECTS_DIR/bert/surf/rh.white:edgecolor=yellow \
      -f $SUBJECTS_DIR/bert/surf/lh.pial:annot=aparc:edgecolor=red \
      -f $SUBJECTS_DIR/bert/surf/rh.pial:annot=aparc:edgecolor=red
        
      # TEST tkmedit (volume viewer):
      tkmedit bert orig.mgz
      tkmedit bert norm.mgz -segmentation aseg.mgz $FREESURFER_HOME/FreeSurferColorLUT.txt
       
      # TEST tksurfer (surface viewer):
      tksurfer bert rh pial 
       
      # TEST short reconstruction segment (< 30 minutes)
      recon-all -s bert -autorecon1 
       
      # TEST full reconstruction (~ 24 hours)
      # 2013 i7 iMac:
      #     recon-all -s bert finished without error at Mon May  6 00:52:13 EDT 2013
      #     22032.75 real     21947.85 user        60.84 sys
      recon-all -s bert -all 
      ```



Installing FreeSurfer on Ubuntu 12.04 :
---------------------------------------------------------------

1. [Download](http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall) the latest .tar.gz binaries from the Freesurfer Wiki.


2. This can also be done from the commandline instead of the webpage:

      ```
      fsFtpDir="ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.2.0"
      fsFtpFilename="freesurfer-Linux-centos4_x86_64-stable-pub-v5.2.0.tar.gz"
      cd ~/Downloads
      wget ${fsFtpDir}/${fsFtpFilename}
        
      # …and to resume a failed download:
      curl -C - -o ${fsFtpFilename} ${fsFtpDir}/${fsFtpFilename}
      ```
 
3. Confirm that the download is valid:

      ```
      sh <<EOF
      curl -s -o freesurfer_md5sums.txt http://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/md5sum.txt
      echo ""
      echo "expected md5 sum:"
      grep ${fsFtpFilename} freesurfer_md5sums.txt
      echo ""
      echo "md5sum of downloaded ${fsFtpFilename}:"
      md5 ${fsFtpFilename}
      echo ""
      echo "(re-download if they don't match)"
      echo ""
      EOF
      ```

ITK-SNAP
====================

Install the ITK-SNAP binary on OS X Mountain/Lion:
-----------------------------------------------------------------

Download latest version from the [ITK-SNAP Downloads page](http://www.itksnap.org/pmwiki/pmwiki.php?n=Main.Downloads).
* Choose "MacOS Binary (Intel, 64 bit, OSX 10.5+)"
* Drag the resulting ITK-SNAP.app to /Applications folder


Install the ITK-SNAP binary on Ubuntu 12.04:
-----------------------------------------------------------------

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install itksnap



MRIcron
==============================


Install MRIcron on Mac OS X Mountain/Lion:
--------------------------------------------------------------

1. Download latest [MRIcron binary](http://www.nitrc.org/projects/mricron) (probably called "MRIcron [month]/[year] osx.zip")

2. Unzip the downloaded file (which currently produces a folder called osx).

3. Install:

     ```
     cd ~/Downloads/osx/
     mv mricron.app dcm2niigui.app npm.app /Applications/
     ```

4. Move dcm2nii to a folder in the $PATH, e.g., /usr/local/bin:

    ```
    echo ${PATH}   # does this contain /usr/local/bin ?
    ls /usr/local  # is there a folder called bin inside of /usr/local ? If not: sudo mkdir /usr/local/bin
    sudo mv ~/Downloads/osx/dcm2nii /usr/local/bin/
    ```

Install MRIcron on Neurodebian (Ubuntu or Debian)
-----------------------------------------------------------------

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install mricron mricron-data mricron-doc

Remember that preferences are stored here if you would like to edit them:

    ~/.dcm2niigui/dcm2niigui.ini
    ~/.dcm2nii/dcm2nii.ini




MRIcroGL
===============


Install MRIcroGL on Mac OS X Mountain/Lion:
-----------------------------------------------------------------

1. Download the [latest version](http://www.mccauslandcenter.sc.edu/mricrogl/).
NB: pay attention to downloaded filename: if you already had osx.zip in your Downloads folder from mricrON, this mricrogl download may get called "osx(1).zip" etc.

2. Unzip and install it: 

    ```
    cd ~/Downloads
    mkdir mricrogl
    cd mricrogl
    unzip ~/Downloads/osx.zip
    sudo mv mricrogl.app /Applications/
    mv *.nii.gz /Users/Shared/sampleBrainVolumes/mricrogl # or other parent of sample data
    ```

3. Save the pdf manual somewhere handy.



ImageJ / FIJI
==================

Install FIJI on Mac OS X Mountain/Lion:
-----------------------------------------------------------------

1. Download the [fiji for macosx dmg](http://fiji.sc/Downloads)

2. Install:

    ```
    cd ~/Downloads
    open fiji-macosx.dmg
    cp -R /Volumes/Fiji/Fiji.app /Applications/
    hdiutil unmount /Volumes/Fiji
    open /Applications/Fiji.app 
    ```
    
3. Install imagej plugins (instructions below)


Install ImageJ/FIJI on Ubuntu 12.04:
-----------------------------------------------------------------

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install fiji

Then install imagej plugins (instructions below).


Install ImageJ plugins:
-----------------------------------------------------------------

Even in 2013 imagej/fiji can't open .nii.gz files without a plugin (though .nii's work).
Download and install the [imagej nifti plugin](http://rsb.info.nih.gov/ij/plugins/nifti.html):

    cd ~/Downloads
    curl -O http://rsb.info.nih.gov/ij/plugins/download/jars/nifti_io.jar
    cp nifti_io.jar /Applications/Fiji.app/plugins/      # ...for OS X . Adapt for linux.

* Re-open imagej/fiji. Opening nii.gz files should now work (drag & drop, or File->Open).
* Also should now see five new commands in imagej/fiji:  
 * File/Import/NIfTI-Analyze, 
 * File/Save As/Analyze (NIfTI-1), 
 * File/Save As/NIfTI-1, 
 * File/Save As/Analyze 7.5 and 
 * Analyze/Tools/Coordinate Viewer.




SPM (Mountain Lion)
=========================

1. Download the latest [SPM 8 package](http://www.fil.ion.ucl.ac.uk/spm/software/spm8/)

2. Unzip the downloaded SPM package and move the resulting SPM folder to /usr/local , 
   so that SPM program files are not in /usr/local/spm.

3. Open matlab and issue the command "userpath;" (no quotes). This will tell you what
   folder Matlab is going to look in for certain files. You care about this folder because 
   in the next step you are going to create a special file that gets placed there.

4. In the Matlab window issue the command "pathtool;" (no quotes). This opens a new window. 
   In this window, add /usr/local/spm to the list of folders that Matlab searches for files. 
   (NB: Upon clicking "save", this window may complain about problems creating a file called pathdef.m, and ask you where you would like to put this file. Put it on the folder that was returned by the userpath command you entered earlier.)

5. Test your installation by closing and then reopening Matlab. Type "spm;" (no quotes) at the Matlab prompt, and the SPM graphical user interface should open.
