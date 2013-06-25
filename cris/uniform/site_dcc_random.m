function [iflags, isite] = site_dcc_random(head, prof, idtest);

% function [iflags, isite] = site_dcc_random(head, prof, idtest);
%
% Select CrIS FOVs for fixed sites, high clouds (aka Deep Convective
% Clouds) or random.
%
% Input:
%    head    - [structure] RTP header with required fields: (ichan, vchan)
%    prof    - [structure] RTP profiles with required fields: (robs1,
%                 rtime, ifov, atrack, xtrack, findex)
%    idtest  - [1 x ntest] ID of test channels for high clouds
%
% Output:
%    iflags  - [1 x nobs] bit flags for various tests:
%     <bit value>: <reason>
%               1: {not used; reserved for clear}
%               2: fixed site
%               4: high cloud (aka DCC)
%               8: random
%              16: coastal
%              32: bad quality
%    isite   - [1 x nobs] fix site ID number [0 if none]
%

% Created: 27 April 2011, Scott Hannon - partly based on uniform.m
% Update: 04 May 2011, S.Hannon - bug fixes; change iflags for compatiblity
%    with "reason"
% Update: 05 May 2011, S.Hannon - add random seed
%          2013.05.08, B.Imbiriba - Partial repeateability of random fovs: 
%                                   seed is the time of 1st fov in granule.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed

range_km = 55.5; % fixed site matchup max range

maxlandfrac_sea = 0.01; % max landfrac for a sea FOV
minlandfrac_land = 0.99; % min landfrac for a land FOV

btmaxhicloud = 210; % max BT for a high cloud FOV
latmaxhicloud = 60; % max |rlat| for a high cloud FOV

ixtrackrandom = 15; % xtrack for random FOV

randadjust = 0.1; % thinning factor for random FOV selection

% Required fields
hreq = {'ichan', 'vchan'};
preq = {'robs1', 'xtrack', 'rlat', 'rlon', 'landfrac'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 3)
   error('unexpected number of input arguments')
end
d = size(idtest);
if (length(d) ~=2 | min(d) ~= 1)
   error('unexpected dimensions for argument idtest')
end
ntest = length(idtest);
for ii=1:length(hreq)
   if (~isfield(head,hreq{ii}))
      error(['head is missing required field ' hreq{ii}])
   end
end
for ii=1:length(preq)
   if (~isfield(prof,preq{ii}))
      error(['prof is missing required field ' preq{ii}])
   end
end


% Determine indices of idtest in head.ichan
[idtestx,indtest,junk] = intersect(head.ichan,idtest);
if (length(idtestx) ~= ntest)
   error('did not find all idtest in head.ichan')
end


% Compute BT of test channels
ftest = head.vchan(indtest);
r = prof.robs1(indtest,:);
ibad = find(r < 1E-6);
r(ibad)=1E-6;
mbt = mean(radtot(ftest,r)); % [1 x nobs]
nobs = length(mbt);
clear r ftest


% Fixed sites (bit value 2)
bv2 = zeros(1,nobs);
[isiteind,isitenum] = fixedsite(prof.rlat,prof.rlon,range_km);
isite = zeros(1,nobs);
isite(isiteind) = isitenum;
bv2(isiteind) = 2;
clear isiteind isitenum


% High clouds/DCC (bit value 4)
bv4 = zeros(1,nobs);
ib = find(mbt <= btmaxhicloud & abs(prof.rlat) <= latmaxhicloud);
bv4(ib) = 4;


% Random FOVs (bit value 8)
% We want repeatability of randomness here - if I rerun this code again 
% I want the *same* random fovs - they are random so it doesn't matter
%
% For that we use int32(prof.rtime(1)) as the seed.
% 
% B.I.
random_seed = int32(prof.rtime(1));
rng(random_seed,'twister');

bv8 = zeros(1,nobs);
ind = find(prof.xtrack == ixtrackrandom);
nind = length(ind);
if (nind > 0)
  random01 = rand([1,nind]);
  randlimit = randadjust*cos(prof.rlat(ind)*pi/180);
  ib = ind(find(random01 <= randlimit));
end
bv8(ib) = 8;


% Coastal FOVs (bit value 16)
bv16 = zeros(1,nobs);
ib = find(prof.landfrac > maxlandfrac_sea & ...
          prof.landfrac < minlandfrac_land);
bv16(ib) = 16;


% Quality checks (bit value 32)
% WARNING! This section is incomplete: there is no
% obvious way to detect bad quality FOVs in the
% IASI-as-CrIS proxy data.  This section should
% be revised once real CrIS data is available.
bv32 = zeros(1,nobs);
junk = mean( prof.robs1(indtest,:), 1);
ib = find(junk < 1E-6); % bad robs1
bv32(ib) = 32;


% Compute iflags (as an exact integer)
iflags = round(bv2 + bv4 + bv8 + bv16 + bv32);


%%% end of routine %%%
