#!/bin/bash

##################################################
#
#   AIRS L1BCM PRODUCTION CALLING SHELL SCRIPT
#
# This script is part of the AIRS L1bcm production
# It calls "airs_l1bcm_proc.m" over to run on 
# TARA clustar. See also "timeblock_dealer.m".
# 
# (C) ASL Group - 2013 - GPL V.3
#
##################################################
# To run on tara, simply call it from the shell:
# ./airs_l1bcm_proc_run.sh
# 
# Necessary variables are defined inside of the script:
#
# start_time - [ yyyy mm dd HH MM SS]
# end_time   - [ yyyy mm dd HH MM SS]
# delta_time - [ yyyy mm dd HH MM SS]
#
# Change this script as necessary , but do not commit it on GIT.
# 
# B.I. Aug.2013


# srun --ntasks=4 --job-name=test --qos=long_contrib --output=slurm-%j.%t.out cris_clear_test_run.sh
#
# N.B.: You may want to add a directory before the output file name
#
# Other possible options: 
#   -c=cpu_per_task "(may be 2 more if you need more memory)"
#   -p=strow "(if you want to use dedicates strow nodes)"
#
# see: "man srun" for further options


# Declare Library locations 
# Based on the fact that we are at 
# $GITROOT/rtp_prod/scripts

#GITROOT=$(dirname $(dirname $PWD))
GITROOT=/home/imbiriba/git
RTPROD=$GITROOT/rtp_prod
MATLIB=$GITROOT/matlib
export RTPROD
export MATLIB

if [ "$#" -eq 0 ] 
then
  mkdir -p log

  bn=`basename $0`
  srun --partition=batch --cpus-per-task=1 --mem-per-cpu=4096 --ntasks=5 --job-name=ArsL1bEc --qos=long_contrib --output=log/slurm-$bn-%j.%t.out $0 onnode &

elif [ "$1" == 'onnode' ]
then

  echo on node...
  start_time='[2011,03,11, 20,36,0]'
    end_time='[2011,03,11, 20,42,0]-[0,0,0,0,0,.001]'
  # 6-minute blocks for AIRS granules
  delta_time='[0,0,0,0,6,0]'  

  NPE=$SLURM_NPROCS 
  PE=$((SLURM_PROCID+1))


  echo "Calling MATLAB"
  matlab -nosplash -nodesktop -nodisplay -r "\
    timeblock_dealer($start_time, $end_time, $delta_time, $PE, $NPE, @airs_l1b_ecmwf_umw ); \
    exit;" 
  echo "Exited MATLAB"

else
  echo $0 run the job on tara.
  echo check inside for variables.
fi

