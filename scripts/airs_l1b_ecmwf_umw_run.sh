#!/bin/bash

# Run me like this "(on tara)":
# 
# srun --ntasks=4 --job-name=test --qos=long_contrib --output=slurm-%j.%t.out airs_l1b_ecmwf_umw_run.sh
#
# N.B.: You may want to add a directory before the output file name
#
# Other possible options: 
#   -c=cpu_per_task "(may be 2 more if you need more memory)"
#   -p=strow "(if you want to use dedicates strow nodes)"
#
# see: "man srun" for further options

GITROOT=/home/imbiriba/git
RTPROD=$GITROOT/rtp_prod
MATLIB=$GITROOT/matlib
export RTPROD
export MATLIB

if [ "$#" -eq 0 ] 
then
  srun --partition=batch --cpus-per-task=2 --ntasks=4 --exclusive --job-name=AirsAFVs --qos=long_contrib --output=slurm-%j.%t.out $0 onnode &

elif [ "$1" == 'onnode' ]
then

  echo on node...
  start_time='[2013,08,27,0,0,0]'
    end_time='[2013,08,28,0,59,59.999]'
  # 6-minute blocks for AIRS granules
  delta_time='[0,0,0,0,6,0]'  

  NPE=$SLURM_NPROCS 
  PE=$((SLURM_PROCID+1))

  #echo "test_airs_clear_driver($start_time, $end_time, $delta_time, $PE, $NPE); exit"

  matlab -nosplash -nodesktop -nodisplay -r "timeblock_dealer($start_time, $end_time, $delta_time, $PE, $NPE, @airs_l1b_ecmwf_umw ); exit;" 

else
  echo $0 run the job on tara.
  echo check inside for variables.
fi

