#!/bin/bash

# Quick and dirty tracking of melodic progress from the command line.

# TBD: test command-line arguments
# TBD: test validity of $melodicOutDir
# TBD: maybe print top CPU users like with ps aux | sort -rk 3,3 | head -n 4

##################
# OUTPUT:
##################
# Output looks like:
#     $ bwMelodicProgress.sh /tmp/melFromFeeds-struct12dof-standard2mmNonlinear.ica
#     
#     Progress of the melodic creating output in /tmp/melFromFeeds-struct12dof-standard2mmNonlinear.ica:
#     drwxrwxr-x 6 stowler-local stowler-local 4096 Aug 19 11:12 /tmp/melFromFeeds-struct12dof-standard2mmNonlinear.ica
#     
#     Melodic Started at Wed Aug 19 11:12:43 EDT 2015 :
#     39M     /tmp/melFromFeeds-struct12dof-standard2mmNonlinear.ica
#     ...but melodic not yet finished as of Wed Aug 19 11:16:55 EDT 2015. Will check again in 20 seconds...
#     
#     ...snip...
#     ...snip...
#     ...snip...
#
#     Melodic Started at Wed Aug 19 11:12:43 EDT 2015 :
#     93M     /tmp/melFromFeeds-struct12dof-standard2mmNonlinear.ica
#     ...but melodic not yet finished as of Wed Aug 19 11:28:15 EDT 2015. Will check again in 20 seconds...
#     
#     Finished at Wed Aug 19 11:28:23 EDT 2015
#
##################
# INPUT:
##################
# Relies on consistent Melodic html output even when not live monitoring melodic via web browser ("Progress Watcher" off in Melodic GUI):
# - "Started" stamp is in `report_log.html`, even after completion
# - "Finished" stamp is in `report.html` (has started stamp until completion)
# 
# For example:
# $ grep -IEr "Started|Finished" /tmp/melFromFeeds-*.ica/*
# /tmp/melFromFeeds-struct6dof-standard2mmLinear.ica/logs/feat0:Started at Wed Aug 19 08:59:13 EDT 2015<p>
# /tmp/melFromFeeds-struct6dof-standard2mmLinear.ica/report.html:Finished at Wed Aug 19 09:06:57 EDT 2015
# /tmp/melFromFeeds-struct6dof-standard2mmLinear.ica/report_log.html:Started at Wed Aug 19 08:59:13 EDT 2015<p>
# /tmp/melFromFeeds-struct6dof-standardNone.ica/logs/feat0:Started at Wed Aug 19 07:57:51 EDT 2015<p>
# /tmp/melFromFeeds-struct6dof-standardNone.ica/report.html:Finished at Wed Aug 19 08:05:03 EDT 2015
# /tmp/melFromFeeds-struct6dof-standardNone.ica/report_log.html:Started at Wed Aug 19 07:57:51 EDT 2015<p>
# # ...snip...


melodicOutDir=$1
sleepSeconds=20

echo ""
echo "Progress of the melodic creating output in ${melodicOutDir}:"
ls -ald ${melodicOutDir}
echo ""

until grep Finished ${melodicOutDir}/report.html; do 
   # while Melodic is processing print these three lines over and over again:
   echo -n "Melodic "; grep Started ${melodicOutDir}/report.html | tr -d '\n'; echo " :"
   du -sh ${melodicOutDir}
   echo -n "...but melodic not yet finished as of "; date | tr -d '\n'; echo ". Will check again in ${sleepSeconds} seconds..."; echo ""
   sleep ${sleepSeconds}
done
