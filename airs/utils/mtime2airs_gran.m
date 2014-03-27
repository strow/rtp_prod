function gran = mtime2airs_gran(mtime)
% function gran = mtime2airs_gran(mtime)
%
%   Compute the matching AIRS L1B granule for a givem matlab time,
%   accurate to 1/1000th of 6 minutes (granule size) - which is 0.36s.
%   This is necessary because of innacurate decimal matlab times 
%   representing precise time fractions. This limit could be pushed further.
%
% Breno Imbiriba - 2013.08.01

% Compute which AIRS granule falls in the given mdate

% ALTHOUGH AIRS granules start 5m32s later than the integer boundaries 
% of "decihours", we will assume they start right at the boundary.
% Hence one day of AIRS data actually goes from 00:05:32 to 00:05:32 of the 
% next day. And all smaller time spans will have this 5:32 offset.
% Live with this for now....

  cr = centiround((mtime - floor(mtime)).*240);
  cr = min(239, cr);
  gran = mod(floor(cr),240)+1;

end

function cx = centiround(x)
  cx = nearest((x.*1000))./1000;
end

