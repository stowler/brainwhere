brainwhere
==========

**brainwhere: a repository for my brain MRI development work**
- It's mostly bash scripts. 
- heavy lifting by FSL, AFNI, FREESURFER, FBIRN
- two goals: get things done, support my training of new imagers

When port to github is complete, there will be two branches:
- master branch, which always passes Wednesday AM testing on my local platforms:
	- OS X Mountain Lion + MacPorts
	- Neurodebian on Ubuntu 12.04 on 64-bit processors
	- Neurodebian-provided VM, running Debian 7.0 Wheezy 32-bit on VirtualBox
- dev branch: my active development, broken daily

**STATUS:**
- May 2013: final porting to github
  - 20130522: everything in master branch for now. 

**INSTALLATION:**

It may destroy your data and computer and everything attached to it, 
but with attribution you are welcome to use this for non-clinical purposes.
Please consider all code proof-of-concept dangerous, and test thoroughly 
**in a safe environment.** 

1. First [install a basic set of system utilities.](https://github.com/stowler/stowlerGeneralComputing/blob/master/docs/setupBasicScriptingEnvironment.md#setupbasicscriptingenvironmentmd)
2. Then [install FSL, AFNI, and BXH/XCEDE.](https://gist.github.com/stowler/5544473)
3. Then use git to instal the brainwhere repository:

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
    bwDir=${bwParentDir}/brainwhere
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
