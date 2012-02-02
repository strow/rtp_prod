function [r1, r2, r3] = crisg4_bandsplit(id, rad);

% function [r1, r2, r3] = crisg4_bandsplit(id, rad);
%
% Split a CrIS g4 radiance array into separate arrays for each of
% the three CrIS bands, with the guard channels appended to the
% ends of each band (ie sorted by freq).
%
% Input:
%   id   -  [1329 x 1] channel IDs {CrIS "g4" channel set}
%   rad  -  [1329 x nobs] radiance {mW/cm^2 per cm^-1 per steradian}
%
% Output:
%    r1  -  [713+8=721 x nobs] or [] band1 radiance
%    r2  -  [433+8=441 x nobs] or [] band2 radiance
%    r3  -  [159+8=167 x nobs] or [] band3 radiance
%

% Created: 23 July 2010, Scott Hannon
% Update: 08 Aug 2011, S.Hannon -rewrite to create "g4" version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CrIS "g4" band channel IDs
id1 = [1306:1309,    1:713,  1310:1313];
id2 = [1314:1317,  714:1146, 1318:1321];
id3 = [1322:1325, 1147:1305, 1326:1329];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
d = size(id);
if (length(d)~= 2)
   error('Unexpected number of dimensions for id')
end
if (min(d) ~= 1)
   error('id must be a 1D array')
end
nchan = max(d);
if (nchan ~= 1329)
   error('Unexpected number of channels')
end
%
d = size(rad);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rad')
end
if (d(1) ~= nchan)
   error('Lead dimension of rad must match length of id')
end
nobs = d(2);
%
if (min(id) < 1 | max(id) > 1329)
  error('id out of expected 1-1329 range')
end


% Loop over the bands
for ib=1:3
   bstr = sprintf('%1d',ib);
   eval(['idx = id' bstr ';']);
   % Find indices of g4 channels for current band
   [junk, ind] = ismember(idx, id);
   if (length(ind) ~= length(idx))
      error(['Did not find all required g4 channel IDs for band' bstr]);
   end
   % Pull out radiance for current band
   eval(['r' bstr ' = rad(ind,:);']);
end

%%% end of function %%%
