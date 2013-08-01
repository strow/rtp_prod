function mtime = airs_gran2mtime(gran)
% function mtime = airs_gran2mtime(gran)
%
% Compute the matlab time for the formal start time of AIRS L1B granule "gran".
%
% 

  mtime = mod((gran - 1),240)./240;

end


