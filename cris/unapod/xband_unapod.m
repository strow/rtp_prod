function [radbu] = band_unapod(radbpr);

% function [radbu] = band_unapod(radbpr);
%
% Convert padded & rolled off Hamming CrIS spectra to unapodized spectra.
%
% Input:
%    radbpr  -  [1763/1411/1031 x nobs] padded/rolloed off Hamming spectra
%
% Output:
%    radbu [713/433/159 x nobs] unapodized CrIS spectra
%

% Created: 07 July 2010, Scott Hannon
% Update: 12 July 2010, S.Hannon - call "hamapod" rather than "apod"
% Update: 15 July 20-10, S.Hannon - add recursive correction for
%    points near band edge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Expected number of channels in input
%nbin_all = [1763, 1411, 1031];
nbin_all = [1773, 1421, 1041];
% Number of output channels
nbout_all = [713, 433, 159];
% Index of true band start channel in padded spectrum
istart_all = [1041, 969, 863];
% Number of points for ifft/fft
npts_all = [2048, 2048, 2048];
% "laser" (math-only) frequency {cm^-1}
vlaser_all = [2560.0, 5120.0, 10240.0];
% Maximum OPD {cm}
opd_all = [0.8, 0.4, 0.2];


% Check input
if (nargin ~= 1)
   error('Unexpected number of input arguments')
end
%
d = size(radbpr);
if (length(d) ~= 2)
   error('Unexpected number of dimensions for radbpr')
end
nbin = d(1);
nobs = d(2);
%
ib = find(nbin == nbin_all);
if (length(ib) ~= 1)
   error('Unexpected leading dimension for radbpr')
end


% Assign ifft/fft parameters
npts = npts_all(ib);
opd = opd_all(ib);
istart = istart_all(ib);
nbout = nbout_all(ib);
vlaser = vlaser_all(ib);
dv = 1/(2*opd);
dd = 1/vlaser;
d = 0:dd:opd; % Note: length(d) = npts+1
yham = hamapod(d, opd);
yham = yham(:); % [npts+1 x 1]
irev = npts:-1:2;
yapod = fftshift([yham(irev); yham])*ones(1,nobs); % size(yham)=[2*npts,nobs]
rwork = zeros(npts,nobs);
rwork(1:nbin,:) = radbpr;


% Compute interferogram
%%%
%irev = npts:-1:2;
%ifg = ifft([rwork; zeros(1,nobs); rwork(irev,:)]);
%%%
irev = npts:-1:1;
ifg = ifft([rwork; rwork(irev,:)]);
%%%
% Note: length(ifg) = 2*npts real & imaginary

% Undo Hamming apodization
ifg = ifg./yapod;


% Convert interferogram to spectrum
rwork = real( fft(ifg) );


%%% uncomment for testing
%plot(1:nbin, mean(radbpr,2),'b',1:npts,mean(rwork(1:npts,:),2),'r')
%title(int2str(ib))
%pause
%%%


% Pull out channels
ind = istart:(istart+nbout - 1);
radbu = rwork(ind,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Recursively apply correction for points near the two band edges

% Channel distance from edge where hamming to unapodization conversion
% is assumed to be negligible
noffset = 11;

for ii = noffset:-1:2
   indlo = (ii-1):(ii+1);
   indhi = 1 + nbout - indlo;
   rwork = radbu(union(indlo, indhi),:); % [6 x nobs]
   rworkh = box_to_ham(rwork);
   herrlo = radbpr(istart + ii - 1,:) - rworkh(2,:);
   herrhi = radbpr(istart - ii + nbout,:) - rworkh(5,:);
   radbu(ii-1,:) = radbu(ii-1,:) - herrlo;
   radbu(nbout-ii+2,:) = radbu(nbout-ii+2,:) - herrhi;
end


%%% end of function %%%
