function [pmem vmem ] = Etc_mem()
% function [pmem vmem ] = Etc_mem()
%
% Calls the 'mlmem.sh' shell script to obtain the total memory used by the MATLAB program.
% 
%   Output:
%   pmem - physycal memory (Kb)
%   vmem - virtual memory (Kb)
% 
% Breno Imbiriba - 2013.12.04

  % Call mlmem.sh 
  % It must be on the same directory as Etc_mem.m

  bd = fileparts(mfilename('fullpath'));
  [s r] = system([bd '/mlmem.sh']);
  r=eval(['[' r ']']);

  vmem = r(1);
  pmem = r(2);

  if(nargout()==0)
    disp([num2str(pmem/1024) ' Mb (' num2str(vmem/1024) ' Mb virt )']);
  end
end
