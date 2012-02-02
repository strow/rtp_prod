function [radbpr] = band_pad_rolloff(radb);

% function [radbpr] = band_pad_rolloff(radb);
%
% Pad band spectra and apply rolloff.  The output radiance
% extends from 0 wavenumbers up to a few wavenumbers (10 channels)
% past the true upper band edge. 
% 
% Input:
%    radb  - [721/441/167 x nobs] radiance for one of the 3 CrIS bands
%
% Output:
%    radbpr  -  [1773/1421/1041 x nobs] padded and rolled off radiance
%

% Created: 07 July 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nguard = 4; % each end
%nfake = 6;
nfake = 16;

% Expected number of channels for each of the three CrIS bands (including
% nguard=4 guard channels at each end)
nbin_all = [721, 441, 167];
%
% Corresponding number of output channels (for nguard=4 and nfake=6);
%nbout_all = [1763, 1411, 1031];
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
nro = nfake + 2;
%nro = nfake+4;
irev = nro:-1:1;
romult = ( 1 + cos(pi + pi*(0:(nro-1))/nro) )/2;
romult = romult(:); % [nro x 1]
ind = ilos:(ilos+nro-1);
radbpr(ind,:) = radbpr(ind,:).*(romult*ones(1,nobs));
ind = (ihie-nro+1):ihie;
radbpr(ind,:) = radbpr(ind,:).*(romult(irev)*ones(1,nobs));


%%% uncomment for testing
%jj = (iloe+1):(ihis-1);
%clf
%plot(jj,radb,'.',1:nbout,radbpr),title(int2str(bnum))
%axis([ilos-1 iloe+8 min(min(radb)) max(max(radb))]);
%pause
%axis([ihis-8 ihie+1 min(min(radb)) max(max(radb))]);
%pause
%%%

%%% end of function %%%
