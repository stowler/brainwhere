brainwhere
==========

**brainwhere: a repository for my brain MRI development work**
- It's mostly bash scripts. 
- heavy lifting by FSL, AFNI, FREESURFER, FBIRN
- two goals: get things done, support my training of new imagers

When port to github is complete, there will be two branches:
- master branch: tested good on my local platforms (OS X Mountain Lion, Ubuntu 12.04 + neurodebian, and the neurodebian-provided VM)
- dev branch: my active development, broken daily

**STATUS:**
- May 2013: final porting to github
  - 20130515: everything in master branch for now. 

**INSTALLATION:**

It may destroy your data and computer and everything attached to it, 
but with attribution you are welcome to use this for non-clinical purposes.
Please consider all code proof-of-concept dangerous, and test thoroughly 
**in a safe environment.** 

1. First [install a basic set of system utilities.](https://github.com/stowler/stowlerGeneralComputing/blob/master/docs/setupBasicScriptingEnvironment.md#setupbasicscriptingenvironmentmd)
2. Then [install FSL, AFNI, and BXH/XCEDE](https://gist.github.com/stowler/5544473)
3. Then use git to instal the brainwhere repository:


    ### Set installation directory (for my local OS X and linux installs: bwParentDir=/opt )
    bwParentDir=[where you would like the directory called brainwhere to reside]
    ### Test whether you have permissions to write to ${bwParentDir} :
    cd ${bwParentDir}
    sudo touch doIhavePermissionsToWriteHere.txt 
    ls -l doIhavePermissionsToWriteHere.txt
    sudo rm doIhavePermissionsToWriteHere.txt
    ### If that worked, export this directory as part of variable $bwDir 
    ### (add to your profile/rc configs as you like)
    export bwDir=${bwParentDir}/brainwhere
    ### Add ${bwDir} to your $PATH (executable scripts are in the brainwhere root):
    export PATH=${bwDir}:${PATH}
    ### If that worked, just install from github:
    sudo git clone https://github.com/stowler/brainwhere.git 
    ### If you received an error about "git not found", install git and try again: http://git-scm.com/downloads

NB: As in these installation instructions, you may notice that the source code is structured and commented
for users who have a wide range of comfort with scripting.
It can be inefficient, but I use this repository to make science *and* train new imagers, which isn't always pretty.

