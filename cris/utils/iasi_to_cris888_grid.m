function [f_cris, rad_cris] = iasi_to_cris888_grid(rad_iasi, atype, fcrisbandstart, fcrisbandstep, fcrisbandend);

% function [f_cris, rad_cris] = iasi_to_cris888_g2(rad_iasi, atype);
%
% Convert IASI L1C radiance to fake CrIS radiance with
% selectable apodization type.
% version888 with bands2&3 8mm OPD rather than standard 4mm & 2mm
% and "g2" guard channels.
%
% Input:
%    rad_iasi  - [8461 x nobs] IASI L1C or calculated radiances
%       for OPD=2 cm with Gaussian apodization 
%    atype - OPTIONAL apodization type string with allowed values:
%       'boxcar', 'box' (ie unapodized) DEFAULT
%       'triangle', 'tri'
%       'hamming', 'ham'
%       'kaiser-bessel', 'kb' {with default aparg}
%       'norton-beer', 'nb' {with default aparg}
%       'cosine', 'cos'
%       'beer'
%       'gauss'
%    Grid Parameters With Guard Cells, Eg:
%    fcrisbandstart, fcrisbandstep, fcrisbandend - 
%                                    Grid Parameters With Guard Cells,
%    Eg. (4 guard channels)
%      crisbandstart = [ 648.75, 1208.75, 2153.75]-1.25;
%      crisbandend   = [1096.25, 1751.25, 2551.25]+1.25;
%      crisbandstep  = [0.625 0.625 0.625];
%
% Output:
%    f_cris - [2223 x 1] CrIS channel frequencies {cm^-1}
%    rad_cris - [2223 x nobs] fake CrIS radiance
% Hint: CrIS band1(8mm)=1:717, band2(8mm)=718:1586, band8(8mm)=1587:2223
%
% Needs: fftconv library

%
% Created: 13 July 2009, Scott Hannon
% Update: 14 Jul 2009, S.Hannon - do interpft instead of interp1 of IASI
% Update: 30 July 2009, S.Hannon - partial re-write to cut IASI spectral
%    range to match CrIS band prior to doing FFT.
% Update: 24 Sep 2009, partial re-write of the transform portion of
%    the code to do use 2*npt fft
% Update: 23 Nov 2010, S.Hannon - version888 with bands2&3 8mm OPD
% Update: 24 Feb 2012, S.Hannon - "g2" variant
% Modified: 14 Mar 2013, Breno Imbiriba - grid variant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% length of extra IASI spectra to retain at band edges {cm^-1}
dfextra = 30;

% length of spectral rolloff to apply at band edges {cm^-1}
% Note: dfrolloff must be less than dfextra
dfrolloff = 25;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%addpath /asl/matlab2012/fftconv   % apod
% Check input
if (nargin ~= 5)
   error('incorrect number of input arguments')
end

%
d = size(rad_iasi);
if (length(d) ~= 2 | d(1) ~= 8461)
   d
   error('Unexpected dimensions for rad_iasi, expecting array [8461 x nobs]');
end
nobs = d(2);


% IASI channel freqs {cm^-1}
niasi = 8461;

% CrIS bands 1,2,3 freqs {cm^-1}
%fcrisbandstep = [0.625, 1.25, 2.50];   % 8, 4, 2 mm OPD
%fcrisbandstep = [0.625, 1.25, 1.25];   % 8, 4, 4 mm OPD
%fcrisbandstep = [0.625, 0.625, 0.625]; % 8, 8, 8 mm OPD
%
%%% no guard channels, any OPD
%fcrisbandstart = [650, 1210, 2155];
%fcrisbandend = [1095, 1750, 2550];
%%% 2 guard channels, 8/8/8 OPD
%fcrisbandstart = [ 648.75, 1208.75, 2153.75];
%fcrisbandend   = [1096.25, 1751.25, 2551.25];
%%%
%
f_cris = [];
ncrisband = zeros(1,3);
ioffsetband = zeros(1,3);
for ib=1:3
   junk = (fcrisbandstart(ib):fcrisbandstep(ib):fcrisbandend(ib))'; %'
   f_cris = [f_cris; junk];
   ncrisband(ib) = length(junk);
   if (ib < 3)
      ioffsetband(ib + 1) = ioffsetband(ib) + ncrisband(ib);
   end
end
ncris = round(sum(ncrisband)); % exact integer

% For IASI, we require vmax > 2800 cm^-1, and the largest common
% freq grid for IASI and CrIS is 0.125 cm^-1.  This implies
%    OPD = 1/(2*dv) of 4 cm
%    vmax = vlaser/2 > 2800 cm^-1
%    dv = vlaser/(2*npts) = 0.125 cm^-1
% A further requirement is that npts should be a power of two, so
% the minimum npts that gives use a suitable vmax is npts=2^15
% with vlaser=8192 cm^-1, and dd = 1/vlaser = 1/8192 cm.
% The actual dv_iasi = 0.25 and OPD_iasi = 2 cm, so we need
% to interpolate IASI spectra.
%
dv = 0.125; % cm^-1
vlaser = 8192; % cm^-1
dd = 1/vlaser; % cm
vmax = vlaser/2; % cm^-1
npts = round(2^15); % 32768 exact integer
nptsp1 = round(npts + 1); % exact integer
OPD = 4; % 4 cm
d = 0:dd:OPD; % cm. Note d is length npts+1


% Compute apodization functions
yapod_iasi = gaussapod(d, 2)'; %'
iok_iasi = find(yapod_iasi > 0);
yapod_cris = zeros(nptsp1,3);
yapod_cris(:,1) = apod(d, 0.8, atype)'; %'
%
%yapod_cris(:,2) = apod(d, 0.4, atype)'; %'
yapod_cris(:,2) = apod(d, 0.8, atype)'; %' 8mm OPD
%
%yapod_cris(:,3) = apod(d, 0.2, atype)'; %' 2mm OPD
%yapod_cris(:,3) = apod(d, 0.4, atype)'; %' 4mm OPD
yapod_cris(:,3) = apod(d, 0.8, atype)'; %' 8mm OPD


% Declare output array
rad_cris = zeros(ncris,nobs);


% Rolloff for band ends
npts_rolloff = 1 + round( dfrolloff/0.25 );
rolloff_end = 0.5*(1 + cos((0:(180/(npts_rolloff - 1)):180)*pi/180))'; %'
rolloff_start = rolloff_end(npts_rolloff:-1:1);


% Indices of 645:0.25:2760 in 0:0.25:4095.75;
npts25 = round(4096/0.25); % exact integer
ind25 = round( 645/0.25 + (1:niasi) ); % exact integers
rpad25 = zeros(npts25,1);

% Min and max indices of IASI data in rpad25
iminiasi = round(1 + 645/0.25);
imaxiasi = round(1 + 2760/0.25);

% Indices of CrIS bands in rpad and rpad25, and channels in rpad25
iminband25 = zeros(1,3);
imaxband25 = zeros(1,3);
iminband = zeros(1,3);
imaxband = zeros(1,3);
iminchan = zeros(1,3);
imaxchan = zeros(1,3);
idelchan = zeros(1,3);
for ib=1:3
   iminband25(ib) = round(1 + (fcrisbandstart(ib) - dfextra)./0.25);
   imaxband25(ib) = round(1 + (fcrisbandend(ib)   + dfextra)./0.25);
   iminband(ib) = round(1 + (fcrisbandstart(ib) - dfextra)./0.125);
   imaxband(ib) = round(1 + (fcrisbandend(ib)   + dfextra)./0.125);
   iminchan(ib) = round(1 + fcrisbandstart(ib)./0.125);
   imaxchan(ib) = round(1 + fcrisbandend(ib)./0.125);
   idelchan(ib) = round(fcrisbandstep(ib)./0.125);
end


% Loop over radiances
for iobs=1:nobs

   if (mod(iobs,100) == 0)
   disp(['working on profile ' int2str(iobs)])
   end

   % Pad current robs with zeros to span 0-4096 cm^-1
   rpad25(ind25)=rad_iasi(:,iobs);

   % Loop over bands
   for ib=1:3

   % (Re-)create rwork for every band
      rwork25 = zeros(npts25,1);
 
      % Copy current band data from rpad25
      ind = iminband25(ib):imaxband25(ib);
      rwork25(ind) = rpad25(ind);
      if (iminband25(ib) < iminiasi)
         % Repeat first data point
         ind = iminband25(ib):(iminiasi - 1);
         rwork25(ind) = rpad25(iminiasi);
      end
      if (imaxband25(ib) > imaxiasi)
         % Repeat last data point
         ind = (imaxiasi + 1):imaxband25(ib);
         rwork25(ind) = rpad25(imaxiasi);
      end


      % Apply rolloff to band edges
      ind = iminband25(ib):(iminband25(ib) + npts_rolloff - 1);
      rwork25(ind) = rwork25(ind).*rolloff_start;
      ind = (imaxband25(ib) - npts_rolloff + 1):imaxband25(ib);
      rwork25(ind) = rwork25(ind).*rolloff_end;

%%% remove this and instead zero fill the ifg from 2 to 4 cm manually
%      % Interpolate from npts25 at 0.25 cm^-1 to npts at 0.125 cm^-1
%      rwork = interpft(rwork25,npts);
%
%      % Do inverse fft of IASI data for current band
%      ifg = ifft([rwork; 0; flipud(rwork(2:npts))]);
%      % Note: the "0" is for rwork(npts+1), and output ifg is 2*npts
%%%
      ifg = ifft([rwork25; 0; flipud(rwork25(2:npts25))]);
      % Note: the "0" is for rwork(npts25+1), and output ifg is 2*npts25
      % Now zero pad the length from 2 cm to 4 cm
      ifg = [ifg(1:npts25); zeros(2*npts25,1); ifg((npts25+1):(2*npts25))];

      % Undo IASI apodization
      ifg(iok_iasi) = ifg(iok_iasi)./yapod_iasi(iok_iasi);

      % Apply the cris apodization
      % Note: the "0" below increases ifgc length to npts+1
      ifgc = ifg(1:npts+1) .* yapod_cris(:,ib);

      % Convert interferogram to spectrum
      rwork2 = real(fft([ifgc; flipud(ifgc(2:npts))]));


      % Pull out CrIS channels
      ind = ioffsetband(ib) + (1:ncrisband(ib));
      ind2 = iminchan(ib):idelchan(ib):imaxchan(ib);
      rad_cris(ind,iobs) = rwork2(ind2);

   end % Loop over bands

end % Loop over radiances

%%% end of function %%%
