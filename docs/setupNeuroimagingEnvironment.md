setupNeuroimagingEnvironment.md
==========

All of my scripts and documentation assume that these neuroimaging resources have been installed. For each package I cover the three computing environments I currently use:

* OS X Mountain Lion + MacPorts
* Neurodebian on Ubuntu 12.04 on 64-bit processors
* Neurodebian VM, running Debian 7.0 wheezy 32-bit on VirtualBox

stowler@gmail.com
updated: 20130523

# Neurodebian VM

1. Download the [neurodebian VM .ova/.ovf](http://neuro.debian.net/):
- click " Get Neurodebian"
- Select operating system: Mac or Windows
- Download the .ova or zip file
 
2) Download and install virtualbox
 
3) Follow neurodebian install instructions:
written: http://neuro.debian.net/vm.html#chap-vm
video: http://www.youtube.com/watch?v=eqfjKV5XaTE
 
4) Boot up. Don't bother to select any new packages from the point-and-click wizard that autoruns.
 
5) Use apt-get to install the software packages listed below
