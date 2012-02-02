function [radu] = crisg4_unapod(id,rada);

% function [radu] = crisg4_unapod(id,rada);
%
% Convert CrIS Hamming apodized spectra computed with the
% UMBC "g4" RTA to unapodized spectra.
%
% Input:
%   id    -  [nchan x 1] channel IDs {1-1329}
%   rada  -  [nchan x nobs] adpodized radiance
%
% Output:
%    radu -  [1305 x nobs] unapodized radiances; returns
%       no data (-9999) for bands with incomplete data.
%

% Created: 07 July 2010, Scott Hannon
% Update: 12 July 2010, S.Hannon - remove "fftconv" toolkit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Check input
if (nargin ~= 2)
   error('Unexpected number of input arguments')
end
%
d = size(id);
if (length(d)~= 2)
   error('Unexpected number of dimensions for id')
end
if (min(d) ~= 1)
   error('id must be a 1D array')
end
nchan = max(d);
%
d = size(rada);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rada')
end
if (d(1) ~= nchan)
   error('Lead dimension of rad must match length of id')
end
nobs = d(2);


% Declare output
radu = -9999*ones(1305,nobs);


% Check data and split into bands
[r1, r2, r3] = crisg4_split(id,rada);


% Process band1
if (length(r1) > 0)
   [radpr] = band_pad_rolloff(r1);
   radu(1:713,:) = band_unapod(radpr);
end


% Process band2
if (length(r2) > 0)
   [radpr] = band_pad_rolloff(r2);
   radu(714:1146,:) = band_unapod(radpr);
end


% Process band3
if (length(r3) > 0)
   [radpr] = band_pad_rolloff(r3);
   radu(1147:1305,:) = band_unapod(radpr);
end

%%% end of function %%%
