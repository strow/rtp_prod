function [id] = cris_freq_to_id(freq, nguard);

% function [id] = cris_freq_to_id(freq, nguard);
%
% Convert CrIS channel frequencies to channel IDs.
% Note: this version for 8/4/2 mm OPD CrIS
%
% Input:
%    freq   : [n x 1] channel freq (wn)
%    nguard : OPTIONAL [1 x 1] number of guard channels at each edge
%       of each band {default=4}
%
% Output:
%    id : [n x 1] channel ID
%

% Created: 29 Jul 2011, S.Hannon - total rewrite of bad "cris_freq_to_id_g4.m"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

opd_bands = [ 0.8  0.4  0.2]; % cm
%
flo_bands = [ 650 1210 2155]; % wn
fhi_bands = [1095 1750 2550]; % wn
%
nguard_default = 4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin < 1 | nargin > 2)
  error('unexpected number of input arguments')
end
if (nargin == 1)
   nguard = nguard_default;
else
   d = size(nguard);
   if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= 1)
      error('unexpected dimensions for argument nguard')
   end
   nguard = round(nguard); % exact integer
   if (nguard < 0)
      error('must have nguard >= 0')
   end
end
%
d = size(freq);
if (length(d) ~= 2 | min(d) ~= 1)
  error('unexpected dimensions for input freq')
end


% Compute number of channels in each band
nbands = length(opd_bands);
df_bands = 1./(2*opd_bands);
nchan_bands = round((fhi_bands-flo_bands)./df_bands + 1); % exact integers
nchan = sum(nchan_bands);
fx = zeros(nchan,1);
fg = zeros(nguard*6,1);


% Loop over the bands
ioffset = 0;
ioffset_guard = 0;
for ib=1:nbands
   ind = ioffset + (1:nchan_bands(ib));
   fx(ind) = flo_bands(ib):df_bands(ib):fhi_bands(ib);
   ioffset = ioffset + nchan_bands(ib);
   %
   % lo band edge guard channels
   ind = ioffset_guard + (1:nguard);
   fg(ind) = flo_bands(ib) + df_bands(ib)*(-nguard:-1);
   ioffset_guard = ioffset_guard + nguard;
   %
   % hi band edge guard channels
   ind = ioffset_guard + (1:nguard);
   fg(ind) = fhi_bands(ib) + df_bands(ib)*(1:nguard);
   ioffset_guard = ioffset_guard + nguard;
end
% All channel freqs, with ID = index
f = [fx; fg];


% Round all freqs to the nearest 0.001 wn to ensure there
% is no numerical noise to prevent matchups of f and freq
fx = round(f*1000)/1000;
freqx = round(freq*1000)/1000;


% Match freq to fx
[junk, loc] = ismember(freqx, fx);
id = loc( find(loc > 0) );
if (length(id) < length(freq))
  error('input freq contained repeats or unexpected values')
end

%%% end of function %%%
