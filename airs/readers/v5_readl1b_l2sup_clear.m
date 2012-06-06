function [head, prof] = v5_readl1b_l2sup_clear(fnl1b,fnl2sup,cfracmax);

% function [head, prof] = v5_readl1b_l2sup_clear(fnl1b,fnl2sup,cfracmax);
%
% Read AIRS L1b and L2sup HDF files and return data for
% clear FOVs.
%
% Input:
%    fnl1b    - [string] name of L1b file
%    fnl2sup  - [string] name of L2sup file
%    cfracmax - OPTIONAL [1 x 1] max allowed cloud fraction {default=0}
%
%
% Output:
%    head - [structure] RTP-like header structure
%    prof - [structure] RTP-like profiles structure
%

% Note: uses the following AIRS readers:
%    v5_readl2sup_qa     : checks Cloud_OLR, H2O, Surf, and Temp_Profile_Bot
%    v5_readl2sup_cloud
%    v5_readl2sup_list
%    readl1b_list
%
% Created: 22 Feb 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


head=[];
prof=[];


% Set QA variable limits
max_Cloud_OLR = 1;
max_H2O = 1;
max_Surf = 1;
max_Temp_Profile_Bot = 1;
%
if (nargin == 2)
   cfracmax = 0;
end


% Check files exist
d = dir(fnl1b);
if (length(d) ~= 1)
   error(['Bad fnl1b: ' fnl1b])
end
%
d = dir(fnl2sup);
if (length(d) ~= 1)
   error(['Bad fnl2su: ' fnl2sup])
end


% Check L2sup QA
[RetQAFlag,Qual] = v5_readl2sup_qa(fnl2sup);
iok = find(Qual.Cloud_OLR <= max_Cloud_OLR);
ii = find(Qual.H2O <= max_H2O);
iok = intersect(iok,ii);
ii = find(Qual.Surf <= max_Surf);
iok = intersect(iok,ii);
ii = find(Qual.Temp_Profile_Bot <= max_Temp_Profile_Bot);
iok = intersect(iok,ii);
nok = length(iok);
if (nok == 0)
   disp('No FOVs passed QA test')
   return
end
clear RetQAFlag Qual



% Convert indices to atrack,xtrack
[iatrack, ixtrack] = l2_ind2track(iok);


% Read cloud fraction info
[Cloud] = v5_readl2sup_cloud(fnl2sup,iatrack,ixtrack);
tcc = zeros(9,nok);
ii = find(Cloud.numCloud == 1);
tcc(:,ii) = Cloud.CldFrcStd(1:9,ii);
ii = find(Cloud.numCloud == 2);
tcc(:,ii) = Cloud.CldFrcStd(1:9,ii) + Cloud.CldFrcStd(10:18,ii);
%
iclear = find(tcc <= cfracmax);
nclear = length(iclear);
if (nclear == 0)
   disp('No clear FOVs')
   return
end
%
atrackl2 = reshape(ones(9,1)*iatrack, 9, nok);
xtrackl2 = reshape(ones(9,1)*ixtrack, 9, nok);
atrackl1b = atrackl2;
xtrackl1b = xtrackl2;
atrackl1b(1:3,:) = 3*(atrackl1b(1:3,:)) - 2;
atrackl1b(4:6,:) = 3*(atrackl1b(4:6,:)) - 1;
atrackl1b(7:9,:) = 3*(atrackl1b(7:9,:));
xtrackl1b([1,4,7],:) = 3*(xtrackl1b([1,4,7],:)) - 2;
xtrackl1b([2,5,8],:) = 3*(xtrackl1b([2,5,8],:)) - 1;
xtrackl1b([3,6,9],:) = 3*(xtrackl1b([3,6,9],:));
atrackl2 = atrackl2(iclear);
xtrackl2 = xtrackl2(iclear);
atrackl1b = atrackl1b(iclear);
xtrackl1b = xtrackl1b(iclear);
latAIRS=Cloud.latAIRS(iclear);
lonAIRS=Cloud.lonAIRS(iclear);
clear Cloud


% Read the L2sup profiles and L1b radiances
[head, pl2] = v5_readl2sup_list(fnl2sup,atrackl2,xtrackl2);
[eq_x_tai, f, prof] = readl1b_list(fnl1b,atrackl1b,xtrackl1b);


% Merge the l1b and l2 data
head.pfields = 5; % profile + robs
head.nchan = 2378;
head.ichan = (1:2378)'; %'
%
prof.plat  = pl2.plat;
prof.plon  = pl2.plon;
%
prof.nemis = pl2.nemis;
prof.efreq = pl2.efreq;
prof.emis  = pl2.emis;
prof.rho   = pl2.rho;
%
prof.spres = pl2.spres;
prof.stemp = pl2.stemp;
prof.nlevs = pl2.nlevs;
prof.plevs = pl2.plevs;
prof.ptemp = pl2.ptemp;
prof.gas_1 = pl2.gas_1;
prof.gas_3 = pl2.gas_3;
prof.gas_5 = pl2.gas_5;
prof.gas_6 = pl2.gas_6;
prof.co2ppm = pl2.co2ppm;
%
prof.iudef = zeros(10,nclear);
prof.iudef(1,:) = pl2.udef1; % RetQAFlag
prof.udef = zeros(20,nclear);
prof.udef(1,:) = eq_x_tai - prof.rtime;
%
prof.cfrac = tcc(iclear)'; %'
%
prof.udef(2,:) = latAIRS;
prof.udef(3,:) = lonAIRS;


%%% end of function %%%
