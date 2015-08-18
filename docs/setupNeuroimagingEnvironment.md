Configure a Stand-Alone Neuroimaging Environment
=================================================

_This is a rough and evolving guide to installing the neuroimaging applications that appear in my scripts and documentation._


Contents
=================

  * [Dependencies](#dependencies)
  * [VM: FSL CentOS 6](#vm-fsl-centos-6)
  * [VM: Neurodebian](#vm-neurodebian)
  * [ITK-SNAP](#itk-snap)
  * [FSL](#fsl)
  * [FSL FIX](#fsl-fix)
  * [FSL melview](#fsl-melview)
  * [FSL ICA-AROMA](#fsl-ica-aroma)
  * [FSLNets](#fslnets)
  * [AFNI](#afni)
  * [FBIRN tools](#fbirn-tools)
  * [FreeSurfer](#freesurfer)
  * [MRIcron](#mricron)
  * [MRIcroGL](#mricrogl)
  * [ImageJ / FIJI](#imagej--fiji)
  * [SPM](#spm)




# Dependencies

Before following the instructions below make sure that you have functional installs of [this basic set of system utilities](http://j.mp/setupScripting).

<!--
After installing and testing the neuroimaging packages below you could also follow [these instructions](http://j.mp/brainwhereREADME) to install my personal repository of miscellaneous neuroimaging scripts.
-->

# VM: FSL CentOS 6

**UPDATED: 20150809**

FSL provides a virtual machine (VM) built on [CentOS 6](http://wiki.centos.org/Manuals/ReleaseNotes/CentOS6.6) and VMware. At the moment I'm using this VM to run HCP software that has been validated on CentOS 6, as well as recreate the environment of a collaborator whose institution mandates RHEL 6.

I run this VM under VMware Fusion Professional 7.1.2 running on OS X Yosemite 10.10, but I imagine it will perform similarly well on any modern VMware host.

1. Download the virtual machine from the [FSL downloads page](http://fsl.fmrib.ox.ac.uk/fsldownloads/fsldownloadmain.html) (see the `FSLVm6_64.zip` button under "Windows 7 
Windows users should download the FSL VM for use with a virtualisation platform.")

1. Install the VM by following or adapting [FSL's installation instructions](http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/Windows).

1. Change the timezone (TBD)

1. Change the keyboard (TBD)

1. Upgrade to the most recent version of CentOS 6:

   ```bash
   yum clean all
   yum upgrade -y
   ```

1. [Update VMware tools](http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/Windows#Updating_VMware_Tools) if the previous step generated significant upgrades.

1. Configure special shared folders (TBD).

1. Download FSL (TBD).

# VM: Neurodebian 
**UPDATED: TBD**

At the time of writing, the Neurodebian virtual machine (VM) is built on Debian stable 7.4.0 "wheezy". 
In prepreation for installing applications and using the VM, first import the VM and update its guest additions:


1. Download and install the latest [VirtualBox binaries](https://www.virtualbox.org/wiki/Downloads).

2. Download the [neurodebian VM .ova/.ovf](http://neuro.debian.net/):
	* click "Get Neurodebian"
	* Select operating system: Mac or Windows
	* Download the latest Debian .ova or zip/ovf file 

3. Import the virtual machine by following the neurodebian [install instructions](http://neuro.debian.net/vm.html#chap-vm), which they support with a [youtube video](http://www.youtube.com/watch?v=eqfjKV5XaTE).

4. Before booting the VM, confirm a few settings that will help avoid initial errors:
	* 2048 MB of RAM (Settings -> System -> Motherboard)
	* one or two CPU's (Settings -> System -> Processor)
	* \>= 64 MB video RAM (Settings -> Display -> Video)
	* no 3D or 2D accelleration (Settings -> Display -> Video)
	* create a shared folder that the guest sees as "host", and set to automount (Settings -> Shared Folders)

5. Boot the VM and follow the Neurodebian Setup Wizard to completion:
	1. Answer "Yes" to the system update question.
	1. Answer "Yes" to "Do you want to proceed with updating the system?"
	1. Click "Install Updates" button in the Update Manger.
		1. Allow updates to complete, ending in message "Your system is up-to-date".
		1. Click "Close" to close the update manager.
	1. Answer yes to the questions about participating in the package popularity contest.
	1. Answer "Yes" to custom environment question ("Packages, such as AFNI and FSL, provide large collections of command line tools...").
	1. De-select all items from the list of additional components, and click "OK".
	1. Allow the wizard to close.

6. Reboot the guest to complete installation of those initial updates: `sudo shutdown -r now`.

7. After rebooting, update again for good measure:
    ```
    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo aptitude (then "g", "g" to see queue and allow it to complete)
    ```

8. If you installed the newest version of virtualbox (which you should have in step 1), 
notice that the currently installed virtualbox guest additions are older than your version of virtualbox: 
    ```
    sudo lsmod | grep -io vboxguest | xargs sudo modinfo
    (compare to version of VirtualBox: mouse to Virtualbox VM -> About Virtualbox VM
    ```

9. Find the installed packages that currently supply those older guest additions:

    ```
    dpkg -l | grep virtualbox
    ```

10. Uninstall those outdated guest additions: 
    ```
    sudo apt-get purge         \
    virtualbox-guest-dkms      \
    virtualbox-guest-utils     \
    virtualbox-guest-x11       \
    virtualbox-ose-guest-dkms  \
    virtualbox-ose-guest-utils \
    virtualbox-ose-guest-x11
    ```

11. Reboot the guest, and confirm that the modules from those old guest additions are no longer present: 
    ```
    sudo lsmod | grep -io vboxguest | xargs sudo modinfo
    ```

12. Install the guest additions that match your current version of virutalbox:
    ```
    sudo apt-get install build-essential module-assistant
    sudo m-a prepare

    (mouse: Virtualbox GUI menu: Device -> Insert Guest Additions CD image... )
    
    sudo mount /media/cdrom0
    ls /media/cdrom0
    sudo sh /media/cdrom0/VBoxLinuxAdditions.run
    ```

13. Shutdown the VM (not reboot, but "shutdown -h now").
14. Enable 3D accelleration (Settings -> Display -> Enable 3D Acceleration)
15. Boot the guest.
16. `sudo aptitude` and git rid of the queued items (`g`, `-`, `q`)
17. Install support for 3D operations and the impending R installation:
    ```
    # The lsb package listed below isn't required for 3D and R, but it has
    # the potential to affect 3D and R install so I include it here, prior
    # to the 3D and R testing that follows later:
    sudo apt-get install \
    xorg-dev libx11-dev libglu1-mesa-dev \
    libxml2-dev libopenmpi-dev mesa-utils glew-utils lsb

    sudo apt-get install \
    cdbs debhelper tcl-tclreadline tk8.5-dev unixodbc-dev
    
    # If this is a 64-bit virtual machine, install 32-bit support:
    # (libc6-i386 seems to have replaced ia32-libs in wheezy)
    sudo apt-get install libc6-i386
    ```

18. Reboot the guest.
19. Test 3D support by running `glxgears`.
20. Grant the user named brain access the host's shared folder established in step 2 above:
    ```
    sudo usermod -a -G vboxsf brain

    (reboot the VM)
    
    ls -al /media/sf_host
    ls -al ~/host  
    (you should see that /home/brain/host is just a symlink to /media/sf_host)
    ```

If everything is stable, the VM is now ready to receive [this basic set of system utilities](http://j.mp/setupScripting), followed by the neuroimaging apps listed below.  

# ITK-SNAP
**UPDATED: TBD**

## Install the ITK-SNAP binary on OS X Mountain/Lion

Download latest version from the [ITK-SNAP Downloads page](http://www.itksnap.org/pmwiki/pmwiki.php?n=Main.Downloads).
* Choose "MacOS Binary (Intel, 64 bit, OSX 10.5+)"
* Drag the resulting ITK-SNAP.app to /Applications folder


## Install the ITK-SNAP binary on Ubuntu 12.04

I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install itksnap



# FSL

## Install FSL on Mac OS X Mountain/Lion
**UPDATED: TBD**


Before installing FSL, freesurfer, or  AFNI on Mountain/Lion be double-sure you have installed [XQuartz](http://xquartz.macosforge.org), and logged out and then back in.


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

3. After the install completes, confirm that the file `/etc/bashrc` received a block of FSL environmental variables. If not, the install program may have added it to your personal `~/.profile` or `~/.bash_profile` instead. For system-wide installation remove the FSL variables from those personal files, and append to `/etc/bashrc` by doing this:

    First cache your sudo credentials via this command (ignoring the output):

    ```
    sudo tail /var/log/auth.log
    ```

    ...then immediately copy this block of lines and paste it into the terminal:

    ```
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
    # on ${editDate} at ${editTime}, user $USER 
    # added some FSL setup:
    FSLDIR=/usr/local/fsl
    PATH=\${FSLDIR}/bin:\${PATH}
    export FSLDIR PATH
    . \${FSLDIR}/etc/fslconf/fsl.sh
    #------------------------------------------
    EOF
    #
    cat /etc/bashrc 
    ```

    Either log out and back in again, or issue this terminal command:
    ```
     . /etc/bashrc
    ```

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



## Install FSL on Ubuntu 12.04
**UPDATED: TBD**


I am currently happy with the version in the neurodebian repos:

    sudo apt-get install fsl-complete fsl-feeds

...but previous to fsl-completed, you needed to install separate packages:

    sudo apt-get instal fsl-atlases fsl-feeds fsl-first-data fslview and fsl-feeds

After installation of the packages, get instructions for environmental variables (e.g., may need to source AFNI/FSL script from /etc/bash.bashrc)

    man fsl

For instructions on how to configure those environmental variables, see the neurodebian VM section below.



## Install FSL on Debian 7.2.0 Wheezy Neurodebian VM
**UPDATED: TBD**


I am currently using the version in the neurodebian repos, but during installation it needs some hand-holding to avoid installation of GPU-related components. I demonstrate installation during minutes 28:20 through 34:01 of [my screencast on neurodebian wheezy 3D support.](http://j.mp/neurodebianVM3D)

After following those instructions to install the FSL packages, check for instructions on configuring environmental variables (e.g., you may need to source FSL's setup script from `/etc/bash.bashrc`):

    man fsl

For system-wide installation, confirm that the file `/etc/bash.bashrc` received a block of FSL environmental variables. If not, the install program may have added it to your personal `~/.profile` or `~/.bash_profile` instead. For system-wide installation, remove the lines from those personal files and append to `/etc/bash.bashrc` by doing this: 

First cache your sudo credentials via this command (ignoring the output):
 
    sudo tail /var/log/auth.log

...then immediately copy this block of lines and paste it into the terminal:

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
    # on ${editDate} at ${editTime}, user $USER 
    # added some FSL setup:
    . /etc/fsl/5.0/fsl.sh
    #------------------------------------------
    EOF
    #
    cat /etc/bash.bashrc 

Either log out and back in again, or issue this terminal command:

     . /etc/bash.bashrc

TEST: did the environmental variable $FSLDIR get exported correctly? The command `echo $FSLDIR` should return something like `/usr/share/fsl/X.X`

TEST: can the shell environment find the FSL binaries? The command `fslinfo` issued without an image filename should produce something like `Usage: /usr/lib/fsl/X.X/fslinfo <filename>`.



## Install and run FSL test suite ("FEEDS")
**UPDATED: 20150818**


Download [FEEDS from FSL (> 270 MB)](http://fsl.fmrib.ox.ac.uk/fsldownloads/), or neurodebian can download via command:

    sudo apt-get install fsl-feeds

Extract and [run FEEDS](http://fsl.fmrib.ox.ac.uk/fsl/feeds/doc/) :

```bash
# (on neurodebian, this is all replaced by command fsl-selftest or /usr/bin/time fsl-selftest)
cd ~/Downloads       # (or the folder where you saved your download)
tar -zxvf fsl-*-feeds.tar.gz
cd feeds

# On some linux installs the user may need to remove
# "DYLD_LIBRARY_PATH LD_LIBRARY_PATH" from line 398 in file "RUN"
# (confirmed in FSL 5.0.7 and 5.0.8 running on neurodebian ubuntu 12.04 and 14.04)

/usr/bin/time ./RUN all
```

Check FEEDS output for errors, and compare run time with other platforms. "Real" or "elapsed" time is the number of wall-clock seconds that passed during execution:

```
2014 i7 rMBP @2.5 GHz, FEEDS 5.0.8: 1190.10 real  980.56 user 22.94 sys
2010 i5 iMac @2.8 GHz, FEEDS 5.0.8: 1711.25 real 1497.34 user 24.42 sys
```


# FSL FIX
**UPDATED: TBD**

TBD


# FSL melview
**UPDATED: TBD**

TBD


# FSL ICA-AROMA
**UPDATED: TBD**

TBD

# FSLNets
**UPDATED: TBD**

TBD



# AFNI

## Install AFNI on Mac OS X Mountain/Lion
**UPDATED: TBD**


Before installing FSL, freesurfer, or  AFNI on Mountain/Lion be sure to install [XQuartz](http://xquartz.macosforge.org), and logout and then back in. 

AFNI also requires netpbm:

    sudo port install netpbm

Then download latest AFNI for Mac, unzip, and move to a reasonable location: 

    cd ~/Downloads
    curl -O http://afni.nimh.nih.gov/pub/dist/tgz/macosx_10.8_gcc.tgz
    tar -zxvf macosx_10.8_gcc.tgz
    sudo mv macosx_10.8_gcc /usr/local/abin

Add AFNI's new location to the path in `/etc/bashrc` by first caching your sudo credentials via this command (ignoring the output):
 
    sudo tail /var/log/auth.log

...then immediately copy this block of lines and paste it into the terminal:

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
    # on ${editDate} at ${editTime}, user $USER  
    # added some AFNI environmental variables:
    export PATH=/usr/local/abin:\${PATH}
    export AFNI_ENFORCE_ASPECT=YES
    echo ""
    echo "----------- active afni version and variables: -----------"
    afni -ver
    echo -n "The command 'afni' will launch: "
    which afni
    echo -n "The command '3dinfo' will launch: "
    which 3dinfo
    echo "AFNI environmental variables, if any exist:"
    env | grep AFNI
    echo "----------------------------------------------------------"
    echo ""
    #------------------------------------------
    EOF
    #
    cat /etc/bashrc

Either log out and back in again, or issue this terminal command:

    . /etc/bashrc 

TEST: Open a new terminal window and test your afni install by issuing the command "afni" (no quotes) to open GUI. Confirm whether AFNI_ENFORCE_ASPECT is working effectively (see below)



## Install AFNI on Neurodebian (Ubuntu 12.04 or the Debian 7.0 Wheezy Neurodebian VM)
**UPDATED: TBD**


I'm currently happy with the version in the neurodebian repos. Install with:

    sudo apt-get install afni afni-atlases

...then execute `man afni` to see instructions for setting environmental variables.
You may be instructed to source an AFNI setup script from `/etc/bash.bashrc` . 
I recommend doing so as follows, so that every new terminal window contains a message about 
what version of AFNI is active. First cache your sudo credentials via this command (ignoring the output):

   sudo tail /var/log/auth.log

...then immediately copy this block of lines and paste into the terminal:

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
    # on ${editDate} at ${editTime}, user $USER 
    # added some AFNI setup:
    . /etc/afni/afni.sh
    echo ""
    echo "----------- active afni version and variables: -----------"
    afni -ver
    echo -n "The command 'afni' will launch: "
    which afni
    echo -n "The command '3dinfo' will launch: "
    which 3dinfo
    echo "AFNI environmental variables, if any exist:"
    env | grep AFNI
    echo "----------------------------------------------------------"
    echo ""
    #------------------------------------------
    EOF
    #
    cat /etc/bash.bashrc

The `cat /etc/bash.bashrc` command above is just a reminder to visually inspect the final changes to the file.
To activate those changes just type `source /etc/bash.bashrc`, or open a new terminal window.

In the event that the Neurodebian version of AFNI is broken/old/whatever 
you may want to substitute an alternative binary version from outside of Neurodebian. Here is one way to manage
parallel installations:


1. Download the correct AFNI archive, unpack it, and move it to a reasonable destination (not overwriting Neurodebian's AFNI in the process):

    ```
    # For 64-bit linux download linux_xorg7_64.tgz, or for 32-bit linux, linux_xorg7.tgz:
    curl -O http://afni.nimh.nih.gov/pub/dist/tgz/linux_xorg7_64.tgz  # (> 600 MB)
    
    tar -zxvf linux_xorg7_64.tgz                  # ...results in directory called linux_xorg7_64
    linux_xorg7_64/afni -ver                      # ...note the compile date at the end, and use it in the next command:
    afniDate=YYYYMMDD                             # ...assign that compile date to a variable in format YYYYMMDD
    sudo mv linux_xorg7_64 /opt/abin-${afniDate}  # ...simultaneous moving and renaming the directory
    sudo rm /opt/abin                             # ...remove existing /opt/abin alias
    sudo ln -s /opt/abin-${afniDate} /opt/abin    # ...create a link to that directory from a standard location
    rm linux_xorg7_64.tgz                    # ...no need to keep this file around
    ```
    
2. Download and edit my short AFNI switching scripts: [/opt/afniSwitchFromRepo.sh](http://goo.gl/LVrpaj) and [/opt/afniSwitchToRepo.sh](http://goo.gl/hx8JVF).

3. Type `source /opt/afniSwitchFromRepo.sh` to switch the current terminal's AFNI version 
to the fresh one installed in `/opt/abin/` instead of the default version from the Neurodebian repository. 
The change only applies to the current terminal window, and only until it is closed.

4. If you need to switch this terminal back to the Neurodebian version of AFNI, just type `source /opt/afniSwitchToRepo.sh`.
 




## Check and Set environmental variable AFNI_ENFORCE_ASPECT

In some environments the AFNI GUI allows you to accidentally distort image aspect ratio by resizing an image window. Not good, but avoidable:

First here's a reminder of how to read and set AFNI environmental variables:

    afni -help | grep Vname
    afni -help | grep Dname

If the following command returns no output, the variable AFNI_ENFORCE_ASPECT isn't set [sic: yes, this command should end with "=" as written here:]

    afni -VAFNI_ENFORCE_ASPECT= 

To set AFNI_ENFORCE_ASPECT on a per-execution basis, can launch the afni GUI with:

    afni -DAFNI_ENFORCE_ASPECT=YES



# FBIRN tools 


## Install FBIRN tools on Mac OS X Mountain/Lion
**UPDATED: TBD**


As of May 2013, the shipping binaries of FBIRN BXH/XCEDE tools includes imagemagick bugs on Mountain Lion. (NB: 20150108: also works on Yosemite 10.10.1)

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
      ls $BXHDIR/bin
      ```


## Install FBIRN tools on Debian Linux 7.0 Wheezy Neurodebian VM
**UPDATED: TBD**


1. Install lsb if it isn't already installed:

    ```
    sudo apt-get install lsb
    ```

2. Manualy download most recent bxh/xcede release from nitrc: http://www.nitrc.org/projects/bxh_xcede_tools

     ```
     $ ls -l ~/Downloads/bxh_xcede_tools-*.tgz
     bxh_xcede_tools-1.10.7-lsb31.i386.tgz
     ```
     
3. Unpack and install bxh/xcede:

     ```
     # ...first declare the bxh version and architecture as they appear in the download filename:
     bxhVersion=1.10.7
     bxhArch=lsb31.i386
     
     # ...then unpack and install:
     cd ~/Downloads
     tar -zxvf bxh_xcede_tools-${bxhVersion}-${bxhArch}.tgz
     sudo mv bxh_xcede_tools-${bxhVersion}-${bxhArch} /opt/
     sudo rm -f /opt/bxh
     sudo ln -s /opt/bxh_xcede_tools-${bxhVersion}-${bxhArch} /opt/bxh
     ```
     
4. For system-wide access, configure the environment via `/etc/bash.bashrc`.  First cache your sudo credentials via this command (ignoring the output):

        sudo tail /var/log/auth.log

    ...then immediately copy this block of lines and paste it into the terminal:


       #    WARNING: note the \${escapedVariables} below, which
       #    are escaped for heredoc (http://goo.gl/j3HMJ). 
       #    Un-escape them if manually typing into a text editor.
       #    Otherwise, just paste these lines to your bash prompt
       #    (up to and including "EOF" line):
       #
       editDate=`/bin/date +%Y%m%d`
       editTime=$(date +%k%M)
       sudo tee -a /etc/bash.bashrc >/dev/null <<EOF
       #-------------------------------------------
       # on ${editDate} at ${editTime}, user $USER 
       # added some BXH/XCEDE environment statements:
       BXHDIR=/opt/bxh
       PATH=\${BXHDIR}/bin:\${PATH}
       export BXHDIR PATH
       #------------------------------------------
       EOF
       #
       cat /etc/bash.bashrc


5. Either log out and back in again, or issue this terminal command:

     ```
     . /etc/bash.bashrc
     ```
     
6. TEST: did `$BXHDIR` get exported correctly? This should return a listing of bxh programs :

      ```
      ls ${BXHDIR}/bin
      ```
      
7. TEST: does the command `bxhabsorb` (no arguments) produce its help message? If not, and instead there is a system message about command not found, there may be a problem with the lsb package.


8. Because the `convert` and `montage` imagemagick programs included with the bxh download often produce font errors, replace them wtih the system-wide convert and montage programs:

    ```
    sudo mv ${BXHDIR}/bin/convert ${BXHDIR}/bin/orig_convert
    sudo mv ${BXHDIR}/bin/montage ${BXHDIR}/bin/orig_montage
    sudo ln -s /usr/bin/convert ${BXHDIR}/bin/convert
    sudo ln -s /usr/bin/montage ${BXHDIR}/bin/montage
    ls -l ${BXHDIR}/bin/convert
    ls -l ${BXHDIR}/bin/montage 
    ```

# FreeSurfer

(WARNINING: Stable 5.2 release WITHDRAWN awaiting upcoming version 5.3)

If you haven't done so already, obtain a license, and copy the .license file to your 
`$FREESURFER_HOME` directory per https://surfer.nmr.mgh.harvard.edu/registration.html


## Install FreeSurfer on Mac OS X Mountain/Lion
**UPDATED: TBD**


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
   (Note the folder that this installs to, likely `/Applications/freesurfer`, which you will assign to `$FREESURFER_HOME` below.)

5. Add post-install config to `/etc/bashrc` per the bash section of the freesurfer [documentation](http://surfer.nmr.mgh.harvard.edu/fswiki/SetupConfiguration). First cache your sudo credentials via this command (ignoring the output):

    ```
    sudo tail /var/log/auth.log
    ```
    ...then immediately copy this block of lines and paste into the terminal:

     ```
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
     #
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



## Install FreeSurfer on Ubuntu 12.04
**UPDATED: TBD**


1. [Download](http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall) the latest .tar.gz binaries from the Freesurfer Wiki.  This can also be done from the commandline instead of the webpage:

    ```
    fsFtpDir="ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.3.0-HCP"
    fsFtpFilename="freesurfer-Linux-centos4_x86_64-stable-pub-v5.3.0-HCP.tar.gz"
    fsLocalDirName=`echo "$fsFtpFilename" | sed 's/\.tar\.gz//' | sed 's/\.tgz//'`
    cd ~/Downloads
    curl -O ${fsFtpDir}/${fsFtpFilename}
        
    # …and to resume a failed download:
    curl -C - -o ${fsFtpFilename} ${fsFtpDir}/${fsFtpFilename}
    ```
 
2. Confirm that the download is valid:

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

4. Unpack the download and move it to a reasonable destination:
   ```
   cd ~/Downloads
   rm -fr freesurfer                                     #...removes any existing directory named freesurfer
   tar -zxvf ${fsFtpFilename}                            #...results in a new directory named freesurfer
   sudo mv freesurfer /opt/${fsLocalDirName}             #...simultaneously removes and renames the directory
   sudo rm /opt/freesurfer                               #...removes any existing /opt/freesurfer link
   sudo ln -s /opt/${fsLocalDirName} /opt/freesurfer     #...creates a standard-location link to the freesurfer directory
   ```

5. Add post-install config to /etc/bashrc per the bash section of the freesurfer [documentation](http://surfer.nmr.mgh.harvard.edu/fswiki/SetupConfiguration) :

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
     # added some freesurfer environmental variables:
     export FREESURFER_HOME=/opt/freesurfer
     . \${FREESURFER_HOME}/SetUpFreeSurfer.sh
     #------------------------------------------
     EOF
     #
     cat /etc/bash.bashrc 
     ```

4. Copy the sample data to a place where users can write to it:

     ```
     cp -a $SUBJECTS_DIR /home/fs-localSubjects
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


# MRIcron


## Install MRIcron on Mac OS X Mountain/Lion
**UPDATED: TBD**


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

## Install MRIcron on Neurodebian (Ubuntu or Debian)
**UPDATED: TBD**


I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install mricron mricron-data mricron-doc

Remember that preferences are stored here if you would like to edit them:

    ~/.dcm2niigui/dcm2niigui.ini
    ~/.dcm2nii/dcm2nii.ini




# MRIcroGL


## Install MRIcroGL on Mac OS X Mountain/Lion
**UPDATED: TBD**


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



# ImageJ / FIJI

## Install FIJI on Mac OS X Mountain/Lion
**UPDATED: TBD**


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


## Install ImageJ/FIJI on Ubuntu 12.04
**UPDATED: TBD**


I'm currently happy with the version in the neurodebian repos:

    sudo apt-get install fiji

Then install imagej plugins (instructions below).


## Install ImageJ plugins
**UPDATED: TBD**


The location of the system-wide destination for imagej plugins differs by platform:

```
# for Fiji on OS X mountain/lion:
imagejSystemWidePluginDir=/Applications/Fiji.app/plugins
# for ImageJ on neurodebian ubuntu 12.04:
imagejSystemWidePluginDir=/usr/share/imagej/plugins

```

I always install this basic set of neuroimaging plugins for imagej:

* Even in 2013, imagej/fiji can't open .nii.gz files without a plugin.
Download and install the [imagej nifti plugin](http://rsb.info.nih.gov/ij/plugins/nifti.html) :

  ```
  cd ~/Downloads
  curl -O http://rsb.info.nih.gov/ij/plugins/download/jars/nifti_io.jar
  sudo mv nifti_io.jar ${imagejSystemWidePluginDir}/
  ```

   * Re-open imagej/fiji. Opening nii.gz files should now work via drag & drop, or File->Import->Nifti/Analyze.
   * Also should now see five new commands in imagej/fiji:  
     * File/Import/NIfTI-Analyze, 
     * File/Save As/Analyze (NIfTI-1), 
     * File/Save As/NIfTI-1, 
     * File/Save As/Analyze 7.5 and 
     * Analyze/Tools/Coordinate Viewer

* The [Tudor DICOM](http://santec.tudor.lu/project/dicom) plugin provides a number of DICOM-related functions, including the ability to parse a DICOMDIR
file and inspect its images interactively. It can also act as a DICOM receiver.

   * Download the file [tudordicom_plugin_*.zip](http://www.santec.lu/project/dicom/download)
   * `cd ~/Downloads`
   * `unzip tudordicom_plugin_*.zip  # (...which creates a child directory called plugins)`
   * `sudo mv plugins/TudorDICOM* ${imagejSystemWidePluginDir}/`
   * `rmdir plugins`
   * restart imagej/fiji
   * The imagej/fiji should now have two new submenus: Plugins/TudorDICOM submenu and Plugins/TudorDICOMLibs
   * Some additional 3D components may need to be installed system-wide:
   		* Launch imagej/fiji as an administrative user (e.g., sudo imagej)
   		* Select menu item Plugins -> TudorDICOMLibs -> 3D Viewer
   		* If java 3D is not already installed, will display message "Java 3D seems not to be installed. Auto-install?"
   		* Allow installation. Shouldn't ask about destination.
   		* Restart imagej/fiji as a normal user and attempt to open 3D viewer again. Should not produce message about java 3D installation.
  

  

# SPM
**UPDATED: TBD**


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
