#!/bin/bash

# Display the total memory used by the caller MATLAB process
# 
# From inside MATLAB, you call !mlmem.sh or system('mlmem.sh') 
# and it will return the amount of used memory by the calling
# MATLAB process.
#
# Breno Imbiriba - 2013.12.04


# The main MATLAB process is called "MATLAB"
# My parent may or may not be "MATLAB", we
# will keep moving up the chain of parents
# until we find "MATLAB":

found_matlab=0

# Start with my parent
parent=$PPID

while [[ $found_matlab -eq 0 ]]
do
  name=`ps -p $parent -o cmd=`
  if [[ "$name" == *MATLAB* ]]  # Use this shell pattern thing... somewhere in the man pages...
  then
    found_matlab=1
  else
    parent=`ps -p $parent -o ppid=`
  fi
  # If we get to pid==1 means that we didn't call this from MATLAB
  if [[ "$parent" -eq 1 ]]
  then
    echo Not called from MATLAB
    exit 1
  fi
done

# Now get the memory
memory=`ps -p $parent -o vsz= -o rss=`
echo $memory

exit 0

