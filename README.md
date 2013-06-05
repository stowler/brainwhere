brainwhere
==========

**brainwhere: a repository for my neuroimaging scripts and resources**
- It's mostly bash scripts. 
- Heavy lifting by FSL, AFNI, FREESURFER, FBIRN.
- Two goals: make the science, support my training of new imagers.


## STATUS:
*May 2013:* final porting to github. Before June **7** the master branch will become stable, with broken daily development isolated in a dev branch. 



This codebase isn't formal enough for numbered releases, but I am maintaining two branches:
- **master**, which passes weekly testing on my local platforms:
	- OS X Mountain Lion + MacPorts
	- Neurodebian on Ubuntu 12.04 on 64-bit processors
	- Neurodebian VM, running Debian 7.0 wheezy 32-bit on VirtualBox
- **dev**, where I make and break things daily

## INSTALLATION:

It may destroy your data and computer and everything attached to it, 
but with attribution you are welcome to use this for non-clinical purposes.
Please consider all code proof-of-concept-dangerous, and test thoroughly 
**in a safe environment.** 

1. Install [this basic set of system utilities.](http://goo.gl/ncbZD)
2. Install FSL, AFNI, and BXH/XCEDE. You may want to refer to [my instructions.](http://goo.gl/BAEH2)
3. Install the brainwhere repository by cloning it with git. Here's how:

(It is safer to paste these into your terminal line-by-line rather than as a block:)

    # =================================================================================================
    # STEP 1/5: Set installation directory (for my local OS X and linux installs: bwParentDir=/opt )
    #
    bwParentDir=[where you would like the directory called brainwhere to reside]
    
    # =================================================================================================
    # STEP 2/5: Test whether you have permissions to write to ${bwParentDir} :
    #
    cd ${bwParentDir}
    sudo touch doIhavePermissionsToWriteHere.txt 
    ls -l doIhavePermissionsToWriteHere.txt
    sudo rm doIhavePermissionsToWriteHere.txt
    
    # =================================================================================================
    # STEP 3/5: If that worked, just install from github:
    #
    cd ${bwParentDir}
    sudo git clone https://github.com/stowler/brainwhere.git
    export bwDir=${bwParentDir}/brainwhere
    ls ${bwDir}
    
    # =================================================================================================
    # STEP 4/5: Add brainwhere's new location to the path in your system-wide bash config file:
    #
    #    WARNING: note the \${escapedVariables} below, which
    #    are escaped for heredoc (http://goo.gl/j3HMJ). 
    #    Un-escape them if manually typing into a text editor.
    #    Otherwise, just paste these lines to your bash prompt
    #    (up to and including "EOF" line):
    #
    mySystemBashConfig=/etc/bash.bashrc    #debian is /etc/bash.bashrc , ubuntu and lion are /etc/bashrc
    editDate=`/bin/date +%Y%m%d`
    editTime=$(date +%k%M)
    sudo tee -a ${mySystemBashConfig} >/dev/null <<EOF
    #------------------------------------------
    # on ${editDate} at ${editTime}, $USER  
    # added some brainwhere environmental variables:
    export bwDir=$bwDir
    export PATH=\${bwDir}:\${PATH}
    #------------------------------------------
    EOF
    
    # =================================================================================================
    # STEP 5/5: Confirm that the system-wide access works:
    #
    cat ${mySystemBashConfig}
    # open a new terminal window and confirm $bwDir:
    ls $bwDir
    echo $PATH

    
    
NB: As in these installation instructions, you may notice that the source code is structured and commented
for users who have a wide range of comfort with scripting. I use this repository to make science *and* train new imagers, which doesn't produce the prettiest or most efficient code.
