function [iA iB] = match_fovs(p1, p2, which)
% function [iA iB] = match_fovs(p1, p2, which)
%
% Match FoVs based on the physical coordinates
% 
% which - method selection
% p1,p2 - input RTP profile structures containing the fields:
%   which = 0 (default) - rlat, rlon
%   which = 1           - rtime, ifov
%
% Breno Imbiriba - 2013.05.29

if(nargin()~=3)
  which=0;
elseif(nargin()<2)
  error('Wrong number of arguments');
end
  
if(which==0)

  e1lat = nearest((p1.rlat + 90)*1000);
  e1lon = nearest((p1.rlon + 180)*1000);
  e1z = complex(e1lat, e1lon);

  e2lat = nearest((p2.rlat + 90)*1000);
  e2lon = nearest((p2.rlon + 180)*1000);
  e2z = complex(e2lat, e2lon);

  [Z i1 i2] = intersect(e1z, e2z);

elseif(which==1)

  % Same thing using time
  t0 = p1.rtime(1);
  e1time = nearest((p1.rtime-t0)*10);
  e1ifov = double(p1.ifov);
  e1zz = complex(e1time, e1ifov);

  e2time = nearest((p2.rtime-t0)*10);
  e2ifov = double(p2.ifov);
  e2zz = complex(e2time, e2ifov);

  [Z iA iB] = intersect(e1zz, e2zz);
else
  error('Wrong "which" variable');
end

end
