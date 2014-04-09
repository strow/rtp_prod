#!/bin/bash

##################################################
#
#   CRIS CLEAR PRODUCTION CALLING SHELL SCRIPT
#
# This script is part of the CrIS Clear production
# It calls "cris_*.m" over to run on 
# TARA clustar. See also "filename_dealer.m".
# 
# (C) ASL Group - 2013 - GPL V.3
#
##################################################
# To run on tara, simply call it from the shell:
# ./cris_fname_run.sh file_list
# 
# Change this script as necessary, but do not commit it on GIT.
# 
# B.I. Oct.2013


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
GITROOT=/asl
RTPROD=$GITROOT/rtp_prod
MATLIB=$GITROOT/matlib
export RTPROD
export MATLIB

if [ "$1" != 'onnode' ] 
then
  mkdir -p log

  bn=`basename $0`
  srun --partition=batch --cpus-per-task=1 --mem-per-cpu=4096 --ntasks=1 --job-name=CrISProd --qos=long_contrib --output=log/$bn-%j.%t.out $0 onnode "$@" &

elif [ "$1" == 'onnode' ]
then
  
  echo on node...

  # Remove "onnode" from input list
  shift 1

  # Need to pass the file list to MATLAB
  # Use the fact that, in MATLAB, we have
  # "func('a','b')" is the same as "func a b"
  # When all input arguments are strings

  file_list="$*"

  NPE=$SLURM_NPROCS 
  PE=$((SLURM_PROCID+1))

  #echo "test_cris_clear_driver($start_time, $end_time, $delta_time, $PE, $NPE); exit"

  matlab -nosplash -nodesktop -nodisplay -r "\
  filename_dealer $PE  $NPE  $file_list  @cris_sdr60_ecmwf_umw_clear_fname; \
  exit" 
#  filename_dealer $PE  $NPE  $file_list  @test; \

else
  echo $0 run the job on tara.
  echo check inside for variables.
fi

