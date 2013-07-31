function Mem=Etc_memory(str);
% function Mem=Etc_memory(whos);
% issue this routine with a call to the `whos` command.
%
% If no return variable is provided, will print the memory usage

  Mem=0;
  for ic=1:length(str)
    Mem=Mem+str(ic).bytes;
  end
  if(nargout()==0)
    [yy ee uu] = engunits(Mem);
    disp([num2str(yy) ' ' uu 'b' ]); 
  end
end
