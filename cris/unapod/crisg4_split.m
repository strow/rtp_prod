function [r1, r2, r3] = crisg4_split(id,rad);

% function [r1, r2, r3] = crisg4_split(id,rad);
%
% Split radiance computed with the UMBC "g4" CrIS RTA into
% three bands.  Returns non-empty data only for those bands
% for which input data was supplied.
%
% Input:
%   id   -  [nchan x 1] channel IDs {1-1329}
%   rad  -  [nchan x nobs] radiance {mW/cm^2 per cm^-1 per steradian}
%
% Output:
%    r1  -  [721 x nobs] or [] band1 radiance
%    r2  -  [441 x nobs] or [] band2 radiance
%    r3  -  [167 x nobs] or [] band3 radiance
%

% Created: 07 July 2010, Scott Hannon
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
%
d = size(rad);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rad')
end
if (d(1) ~= nchan)
   error('Lead dimension of rad must match length of id')
end


% Channel ids for the three CrIS bands
id1 = [1306:1309,     1:713, 1310:1313];
id2 = [1314:1317,  714:1146, 1318:1321];
id3 = [1322:1325, 1147:1305, 1326:1329];
%
% Desired order of indices after sorting
ii1 = [714:717, 1:713, 718:721];
ii2 = [434:437, 1:433, 438:441];
ii3 = [160:163, 1:159, 164:167];
%
n1 = length(id1);
n2 = length(id2);
n3 = length(id3);


% Look for band1
[idmatched, ind, junk] = intersect(id,id1);
% Note: idmatch is sorted, which is NOT what we want
if (length(idmatched) == n1)
   ind = ind(ii1);
   r1 = rad(ind,:);
else
   r1 = [];
end


% Look for band2
[idmatched, ind, junk] = intersect(id,id2);
if (length(idmatched) == n2)
  ind = ind(ii2);
   r2 = rad(ind,:);
else
   r2 = [];
end


% Look for band3
[idmatched, ind, junk] = intersect(id,id3);
if (length(idmatched) == n3)
  ind = ind(ii3);
   r3 = rad(ind,:);
else
   r3 = [];
end


%%% end of function %%%
