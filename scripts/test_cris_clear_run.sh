#!/bin/bash


#SBATCH --job-name=CrisTest
#SBATCH --qos=long_contrib
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8


start_time='[2012,09,20,0,0,0]'
end_time='[2012,09,20,0,59,59.999]'
delta_time='[0,0,0,0,10,0]'

NPE=$SLURM_NPROCS
PE=$SLURM_PROCID


rsun echo "test_cris_clear_driver($start_time, $end_time, $delta_time, $PE, $NPE); exit"

#rsun matlab -r "test_cris_clear_driver($start_time, $end_time, $delta_time, $PE, $NPE); exit"



