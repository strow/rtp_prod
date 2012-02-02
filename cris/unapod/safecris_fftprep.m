function [rout] = cris_fftprep(rin);

% function [rout] = cris_fftprep(rin);
%
% Prepare a band of CrIS spectra for FFT.  Rolloff is applied to both
% ends of the band, and the low freq side of the band is zero padded
% down to 0 wavenumbers.
% 
% Input:
%    rin  - [733/453/179 x nobs] radiance for one of the 3 CrIS bands
%       as returned by "cris_bandsplit.m" where
%       733 = length(643.75:0.625:1101.25);
%       453 = length(1197.5:1.25:1762.5);
%       179 = length(2130:2.5:2575);
%
% Output:
%    rout  -  [1763/1411/1031 x nobs] padded and rolled off radiance
%       1763 = length(0:0.625:1101.25);
%       1411 = length(0:1.25:1762.5);
%       1031 = length(0:2.5:2575);
%

% Created: 07 July 2010, Scott Hannon
% Update: 26 Jul 2010, S.Hannon - partial re-write; change name from
%   band_pad_rolloff to cris_fftprep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Expected number of channels for each of the three CrIS bands
nbin_all = [733, 453, 179];
%
% Corresponding number of output channels
nbout_all = [1763, 1411, 1031];

% Check input
d = size(rin);
if (length(d) ~=2)
   error('Unexpected number of dimensions for rin')
end
nbin = d(1);
nobs = d(2);
%
bnum = find(nbin == nbin_all);
if (length(bnum) ~= 1)
   error('Unexpected number of channels in rin')
end
nbout = nbout_all(bnum);


% Declare output
rout = zeros(nbout,nobs);


% Copy input radiance to output array
ilo = nbout - nbin + 1;
ind = ilo:nbout;
rout(ind,:) = rin;


% Apply rolloff
nro = 8;
irev = nro:-1:1;
romult = ( 1 + cos(pi + pi*(0:(nro-1))/nro) )/2;
romult = romult(:); % [nro x 1]
ind = ilo:(ilo + nro - 1);
rout(ind,:) = rout(ind,:).*(romult*ones(1,nobs));
ind = (nbout - nro + 1):nbout;
rout(ind,:) = rout(ind,:).*(romult(irev)*ones(1,nobs));


%%% uncomment for testing
%jj = ilo:nbout;
%clf
%plot(jj,rin,'.',jj,rout(jj,:)),title(int2str(bnum))
%axis([ilo nbout min(min(rin)) max(max(rin))]);
%pause
%%%

%%% end of function %%%
