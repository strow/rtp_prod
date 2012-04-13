function [calnum, cstr] = data_to_calnum_l1b2(freq, nen, ...
   calchansummary, calflag, rtime, granule_number);

% function [calnum, cstr] = data_to_calnum_l1b2(freq, nen, ...
%    calchansummary, calflag, rtime, granule_number);
%
% Convert various AIRS calibration data into an 8-bit number.
% WARNING: v5 l1b_cal_subset files lack calflag; should appear in v6
% version "2" for speed testing
%
% Input:
%    freq           - [2378 x 1] nominal channel freqs
%    nen            - [2378 x ng] noise equivalent radiance
%    calchansummary - [2378 x ng] granule channel summary
%    calflag        - [2378 x nobs] scanline calibration flags
%    rtime          - [1  x nobs] observation time {sec since 0z 01 Jan 1993}
%    granule_number - [1 x nobs] granule number {0-240}
%       Note: l1bcm "ng" is always 241 with granule numbers 0:240
%       since it has two partial granules at 0z and 24z.
%
% Output
%    calnum         - [2378 x nobs] 8-bit calibration number
%                        bits1-4 = NEdT(@250K) lookup table index-1 {0-15}
%                        bit5    = A side detector {0=off, 1=on}
%                        bit6    = B side detector {0=off, 1=on}
%                        bits7-8 = calflag/calchansummary
%                           {0=OK, 1=DCR, 2=moon, 3=other}
%    cstr           - [string] character string describing calnum
%
% Hint: calnum <= 63 are OK, calnum <= 127 are DCR-only,
%       calnum =< 191 are moon-only, calnum >= 192 are other
% 

%%%
% old
%                        bit7    = calflag <> 0 {0=false, 1=true}
%                        bit8    = calchansummary <> 0 {0=false, 1=true}
%%%

% Created: 02 Jun 2010, Scott Hannon
% Update: 12 Nov 2010, S.Hannon - change bits 7 & 8 from two binary
%    flags to one 2-bit number. Rename routine (was *_l1bcm).
%  Update: 14 Jun 2011, S.Hannon - bug fix for NEdT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Spectral calibration filename and TAI time when A/B weight changes
caldir = '/asl/matlab/airs/utils';
calfiles = {'airs_cal_prop_2002_08_30.txt', ...
            'airs_cal_prop_2003_01_10.txt', ...
            'airs_cal_prop_2003_11_19.txt'};
caltimes = [304853040, 316342920, 343376580]; % start times


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NeDT lookup table table; 16th value for no-data or greater than max
%           1    2    3    4    5    6    7    8   9  10  11  12  13  14  15
lutable = [0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7 0.8 1.0 2.0 4.0];
%
% Note: cstr must include the substring "NEdT[" followed by 16 numbers.
cstr =[ 'bits1-4=NEdT[0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7' ...
  ' 0.8 1.0 2.0 4.0 nan]; bit5=Aside[0=off,1=on]; bit6=Bside[0=off,1=on];' ...
  ' bits7-8=calflag&calchansummary [0=OK, 1=DCR, 2=moon, 3=other]' ];
%%% old
%  ' bit7=calflag[0=0,1=not0]; bit8=calchansummary[0=0,1=not0]' ];
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 6)
   error('Unexpected number of input arguments')
end
d = size(freq);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= 1)
   error('Unexpected dimensions for argument "freq"');
end
d = size(nen);
if (length(d) ~= 2 | d(1) ~= 2378)
   error('Unexpected dimensions for argument "nen"');
end
ng = d(2);  % always 241 if l1bcm
d = size(calchansummary);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= ng)
   error('Unexpected dimensions for argument "calchansummary"');
end
d = size(calflag);
if (length(d) ~= 2 | d(1) ~= 2378)
   error('Unexpected dimensions for argument "calflag"');
end
nobs = d(2);
d = size(rtime);
if (length(d) ~= 2 | max(d) ~= nobs | min(d) ~= 1)
   error('Unexpected dimensions for argument "rtime"');
end
d = size(granule_number);
if (length(d) ~= 2 | max(d) ~= nobs | min(d) ~= 1)
   error('Unexpected dimensions for argument "granule_number"');
end


% Create output array
calnum = zeros(2378,nobs);


% Convert granule_number to nobs index
if (ng == 241)
   gind = round(granule_number + 1); % exact integer 1:241
else
   if (ng == 1)
      gind = ones(1,nobs);
   else
      error('Unexpected value of "ng"; unsure how to match data indices')
   end
end


% Convert nen to nedt
ibad = find(nen < 0);
nen(ibad) = 1;
r250 = ttorad(freq,250);
nedt = radtot(freq,r250*ones(1,ng)+nen) - 250;
nedt(ibad ) = 100; % bigger than last lookup table value
nedt = nedt(:,gind); % convert [2378 x ng] to [2378 x nobs]


% Convert nedt to lookup table index-1
for ii=15:-1:1
   ind = find(nedt < lutable(ii));
%wrong   calnum(ind) = ii;
   calnum(ind) = ii-1;
end
ind = find(nedt > lutable(15));
calnum(ind) = 15;
clear r250 nedt ibad xnen


% Set A/B detector bits
mtime = mean(rtime);
ind = 0;
for ii=1:length(caltimes)
   if (mtime > caltimes(ii))
      ind = ii;
   end
end
calprop = load([caldir '/' calfiles{ii}]);
ab = calprop(:,4); % 0=opt, 1=A, 2=B
%
% Default is opt
calnum = calnum + 48; % opt = A+B = 16+32
% Find A-only
ii = find(ab == 1);
calnum(ii,:) = calnum(ii,:) - 32;
% Find B-only
ii = find(ab == 2);
calnum(ii,:) = calnum(ii,:) - 16;
clear ab


% Assign bits7-8 calflag&calchansummary
% Values: OK={b7=0,b8=0}, DCR={b7=1,b8=0}, moon={b7=0,b8=1}, other={b7=1,b8=1}
bit7 =  64*ones(2378,nobs); % 2^6
bit8 = 128*ones(2378,nobs); % 2^7
ix = find(calchansummary(:,gind) == 0); % no calchansummary problems
i0 = ix( find(calflag(ix) == 0) );  % no problems
if (length(i0) > 0)
   bit7(i0) = 0;
   bit8(i0) = 0;
end
i0 = ix( find(calflag(ix) == 8) );  % DCR-only
if (length(i0) > 0)
   bit8(i0) = 0;
end
i0 = ix( find(calflag(ix) == 4) );  % moon-only
if (length(i0) > 0)
   bit7(i0) = 0;
end
calnum = calnum + bit7 + bit8;
clear bit7 bit8 ix i0
%
calnum = uint8( round(calnum) );


%%% old
%% Assign calflag
%bit7 = zeros(2378,nobs);
%ii = find(calflag > 0);
%bit7(ii) = 64;
%calnum = calnum + bit7;
%clear bit7
%
%% Assign calchansummary
%bit8 = zeros(2378,nobs);
%xcalchansummary = calchansummary(:,gind);
%ii = find(xcalchansummary > 0);
%bit8(ii) = 128;
%calnum = calnum + bit8;
%clear bit8
%%
%calnum = uint8( round(calnum) );
%%%

%%% end of file %%%
