function [head, prof] = v5_readl2cc_l2sup(fnl2cc,fnl2sup);

% function [head, prof] = v5_readl2cc_l2sup(fnl2cc,fnl2sup);
%
% Read AIRS L2cc and L2sup HDF files and return RTP
%
% Input:
%    fnl2cc   - [string] name of L2cc file
%    fnl2sup  - [string] name of L2sup file
%
% Output:
%    head - [structure] RTP-like header structure
%    prof - [structure] RTP-like profiles structure
%

% Note: uses the following AIRS readers:
%    v5_readl2sup_qa     : check Cloud_OLR, H2O, Surf, and Temp_Profile_Bot
%    v5_readl2sup_cloud
%    v5_readl2sup_list
%    readl2cc_qa         : check CC_Rad
%    v5_readl2cc_list
%
% Created: 17 March Feb 2010, Scott Hannon - based on v5_readl1b_l2sup_clear.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


head=[];
prof=[];


% Set QA variable limits
max_CC = 1;
max_Cloud_OLR = 1;
max_H2O = 1;
max_Surf = 1;
max_Temp_Profile_Bot = 1;
%
if (nargin == 2)
   cfracmax = 0;
end


% Check files exist
d = dir(fnl2cc);
if (length(d) ~= 1)
   error(['Bad fnl2cc: ' fnl2cc])
end
%
d = dir(fnl2sup);
if (length(d) ~= 1)
   error(['Bad fnl2su: ' fnl2sup])
end


% Check L2cc QA
[RetQAFlag,Qual] = readl2cc_qa(fnl2cc);
iok = find(Qual.CC_Rad <= max_CC);
nok = length(iok);
if (nok == 0)
   disp('No FOVs passed L2cc QA test')
   return
end
%
% Check L2sup QA
[RetQAFlag,Qual] = v5_readl2sup_qa(fnl2sup);
ii = find(Qual.Cloud_OLR <= max_Cloud_OLR);
iok = intersect(iok,ii);
ii = find(Qual.H2O <= max_H2O);
iok = intersect(iok,ii);
ii = find(Qual.Surf <= max_Surf);
iok = intersect(iok,ii);
ii = find(Qual.Temp_Profile_Bot <= max_Temp_Profile_Bot);
iok = intersect(iok,ii);
nok = length(iok);
if (nok == 0)
   disp('No FOVs passed L2sup QA test')
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
% Convert 9 L1b FOV tcc into some estimate of CC FOV cloudiness
tcc = (min(tcc) + mean(tcc))/2; % dubious

% Read the L2sup profiles and L2cc radiances
[head, prof] = v5_readl2sup_list(fnl2sup,iatrack,ixtrack);
retqaflag = prof.udef1;
olr = prof.udef2;
prof = rmfield(prof,'udef1');
prof = rmfield(prof,'udef2');
[eq_x_tai, f, ccdata] = v5_readl2cc_list(fnl2cc,iatrack,ixtrack);


% Merge the l2cc and l2sup data
head.pfields = 5; % profile + robs
head.nchan = 2378;
head.ichan = (1:2378)'; %'
%
prof.robs1 = ccdata.robs1;
prof.calflag = ccdata.calflag;
prof.cfrac = tcc;
%
prof.iudef = zeros(10,nok);
prof.iudef(1,:) = retqaflag;
prof.udef = zeros(20,nok);
prof.udef(1,:) = eq_x_tai - prof.rtime;
prof.udef(2,:) = olr;

%%% end of function %%%
