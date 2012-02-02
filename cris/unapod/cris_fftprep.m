function [radbpr] = cris_fftprep(radb);

% function [radbpr] = cris_fftprep(radb);
%
% Prepare a band of CrIS spectra for FFT.  Rolloff is applied to both
% ends of the band, and the low freq side of the band is zero padded
% down to 0 wavenumbers.
% 
% Input:
%    radb  - [733/453/179 x nobs] radiance for one of the 3 CrIS bands
%       as returned by "cris_bandsplit.m" where
%       733 = length(643.75:0.625:1101.25);
%       453 = length(1197.5:1.25:1762.5);
%       179 = length(2130:2.5:2575);
%
% Output:
%    radbpr  -  [1773/1421/1041 x nobs] padded and rolled off radiance
%       1773 = length(0:0.625:1107.5);
%       1421 = length(0:1.25:1775);
%       1041 = length(0:2.5:2600);
%

% Created: 07 July 2010, Scott Hannon
% Update: 26 Jul 2010, S.Hannon - change name from
%   band_pad_rolloff to cris_fftprep; change values of nguard and nfake
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of guard+fake channels on ends of radb
nguard = 10;

% Number of extra fake channels to add to ends of radb
nfake = 10;

% Expected number of channels for each of the three CrIS bands
nbin_all = [733, 453, 179];
%
% Corresponding number of output channels
nbout_all = [1773, 1421, 1041];

% Check input
d = size(radb);
if (length(d) ~=2)
   error('Unexpected number of dimensions for radb')
end
nbin = d(1);
nobs = d(2);
%
bnum = find(nbin == nbin_all);
if (length(bnum) ~= 1)
   error('Unexpected number of channels in radb')
end
nbout = nbout_all(bnum);


% Declare output
radbpr = zeros(nbout,nobs);


% Copy input radiance to output array
ilos = round(nbout - 2*nfake - nbin + 1); % exact integer
iloe = ilos + nfake - 1;
ihis = nbout - nfake + 1;
ihie = nbout;
ind = (iloe+1):(ihis-1);
radbpr(ind,:) = radb;


% Assign fake radiances by repeating max guard channel value
ind = ilos:iloe;
ii = 1:nguard;
%fvalue = max(radb(ii,:));
fvalue = radb(1,:);
radbpr(ind,:) = ones(nfake,1)*fvalue;
ind = ihis:ihie;
ii = nbin - ii; % should this be nbin-ii+1 ?
%fvalue = max(radb(ii,:));
fvalue = radb(nbin,:);
radbpr(ind,:) = ones(nfake,1)*fvalue;


% Apply rolloff
nro = nfake + 6;
irev = nro:-1:1;
romult = ( 1 + cos(pi + pi*(0:(nro-1))/nro) )/2;
romult = romult(:); % [nro x 1]
ind = ilos:(ilos+nro-1);
radbpr(ind,:) = radbpr(ind,:).*(romult*ones(1,nobs));
ind = (ihie-nro+1):ihie;
radbpr(ind,:) = radbpr(ind,:).*(romult(irev)*ones(1,nobs));


%%% uncomment for testing
%jji = (iloe + 1):(ihis - 1);
%jjo = ilos:nbout;
%clf
%plot(jji,radb,'.',jjo,radbpr(jjo,:)),title(int2str(bnum))
%axis([ilos nbout min(min(radb)) max(max(radb))]);
%pause
%%%

%%% end of function %%%
