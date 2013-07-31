#!/bin/bash

# Run me like this "(on tara)":
# 
# srun --ntasks=4 --job-name=test --qos=long_contrib --output=slurm-%j.%t.out cris_clear_test_run.sh
#
# N.B.: You may want to add a directory before the output file name
#
# Other possible options: 
#   -c=cpu_per_task "(may be 2 more if you need more memory)"
#   -p=strow "(if you want to use dedicates strow nodes)"
#
# see: "man srun" for further options

if [ "$#" -eq 0 ] 
then
  srun --partition=batch --ntasks=4 --job-name=test --qos=long_contrib --output=slurm-%j.%t.out cris_clear_test_run.sh onnode &
elif [ "$1" == 'onnode' ]
then

  echo on node...
  start_time='[2012,09,20,0,0,0]'
  end_time='[2012,09,20,0,59,59.999]'
  delta_time='[0,0,0,0,10,0]'

  NPE=$SLURM_NPROCS 
  PE=$((SLURM_PROCID+1))

  #echo "test_cris_clear_driver($start_time, $end_time, $delta_time, $PE, $NPE); exit"

  /asl/opt/bin/matlab -nosplash -nodesktop -nodisplay -r "try; timeblock_dealer($start_time, $end_time, $delta_time, $PE, $NPE, @cris_clear_test ); catch err; Etc_show_error(err); end; exit" 

else
  echo $0 run the job on tara.
  echo check inside for variables.
fi

