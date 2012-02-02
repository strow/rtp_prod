function [rbox] = hamg4_to_box(rham);

% function [rbox] = hamg4_to_box(rham);
% WARNING! do not use
%
% Convert Hamming apodized radiance to crude approximate
% boxcar/unapodized radiance by a linear combination of radiances.
% This version requires 4 guard channels at each end of the band(s).
%
% Input:
%    rham - [nchan x nobs] Hamming apodized radiance. The
%       radiance must be:
%       a) sorted by frequency (either ascending or descending)
%       b) point spacing 1/(2*L) where L is the maximum OPD
%       c) continuous (at least in part)
%
% Output:
%    rbox -  [nchan x nobs] crude approximate boxcar/unapodized radiance
%

% Created: 19 July 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of guard channels
nguard = 4;
nmin=nguard*2 + 1;
% radiance weight [nmin x 1]
% Note: rweight comes from inv(M) where M is a [nmin x nmin] matrix
% with central row [0 0 0 0.23 0.54 0.23 0 0 0]
% The inversion implicitly assumes all radiances are otherwise
% equally weighted over the spectral interval, which is a very poor
% approximation as it ignores both transmittance and planck effects.
rweight=[0.236692413302790 -0.555712622536986  1.068024178740567 ...
        -1.951822405810433  3.514515382727406 -1.951822405810433 ...
         1.068024178740567 -0.555712622536986  0.236692413302790];
% Note: sum(rweight) = 1.108878510119283 so must be renormalized
rweight=rweight./sum(rweight);


% Check input
d = size(rham);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rham')
end
nchan = d(1)
nobs = d(2);
if (nchan < nmin)
  error(['Lead dimension of rham must be at least ' int2str(nmin)])
end


% Convert rham to rbox
rbox = zeros(nchan,nobs);
ii = (nguard+1):(nchan-nguard);
offset = -nguard;
for jj=1:nmin
   ind = ii + offset;
   rbox(ii,:) = rbox(ii,:) + rham(ind,:)*rweight(jj);
   offset = round(offset + 1); % exact integer
end

%%% end of function %%%
