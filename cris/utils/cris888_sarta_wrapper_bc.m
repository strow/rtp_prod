function [r888, KLAYERS, SARTA] = cris888_sarta_wrapper_bc(rtpin, nguard);

% function [r888, KLAYERS, SARTA ] = cris888_sarta_wrapper_bc(rtpin, nguard);
%
% Wrapper for running SARTA for CrIS 8/8/8 mm OPD. Uses the
% IASI RTA to calculate Guassian apodized IASI radiances.
% The IASI radiance is then unapodized and truncated to 8 mm
% OPD and cut at the CrIS spectral band edges.
% 
% Input:
%    rtpin - [string] name of input RTP with all the usual
%       required fields for a SARTA calculation.  May be
%       either a "level" or "layer" profile.
%    nguard - [1 x 1] integer: number of guard channels per
%       band edge {0 or 2}
%
% Output:
%    r888  - [nchan x nobs] single: "cris888" unapodized radiance.
%        The channel IDs match those in rtpin.
%

% Created: 09 Mar 2012, Scott Hannon
% Modified:14 Mar 2013, Breno Imbiriba 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

KLAYERS='/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
SARTA='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%addpath /asl/matlab/h4tools
%addpath /asl/matlab/iasi/utils

if (nargin ~= 2)
   error('unexpected number of input arguments');
end
d = dir(rtpin);
if (length(d) ~= 1)
   rtpin
   error('Unable to read rtpin')
end
if (nguard ~= 0 & nguard ~= 2 & nguard ~=4 )
   error('unexpected number of guard channels')
end


% "cris888" channel info
crisband_df = [0.625, 0.625, 0.625];
crisband_fstart = [ 650, 1210, 2155];
crisband_fend   = [1095, 1750, 2550];
%
f1g0 = crisband_fstart(1):crisband_df(1):crisband_fend(1);
f2g0 = crisband_fstart(2):crisband_df(2):crisband_fend(2);
f3g0 = crisband_fstart(3):crisband_df(3):crisband_fend(3);
%
n1g0 = length(f1g0);
n2g0 = length(f2g0);
n3g0 = length(f3g0);
%
id1g0 = (1:n1g0);
id2g0 = (1:n2g0) + n1g0;
id3g0 = (1:n3g0) + n1g0 + n2g0;
%
if (nguard == 0)
   f = [f1g0, f2g0, f3g0]'; %'
   nchan = length(f);
   id = int32([id1g0, id2g0, id3g0])'; %'
elseif (nguard == 2)
   crisband_fstart = [ 648.75, 1208.75, 2153.75];
   crisband_fend   = [1096.25, 1751.25, 2551.25];

   f1 = crisband_fstart(1):crisband_df(1):crisband_fend(1);
   f2 = crisband_fstart(2):crisband_df(2):crisband_fend(2);
   f3 = crisband_fstart(3):crisband_df(3):crisband_fend(3);

   f = [f1, f2, f3]'; %'

   nchang0 = n1g0 + n2g0 + n3g0;
   id1 = [nchang0 + ( 1:2), id1g0, nchang0 +   (3:4)];
   id2 = [nchang0 + ( 5:6), id2g0, nchang0 +   (7:8)];
   id3 = [nchang0 + (9:10), id3g0, nchang0 + (11:12)];
   id = int32([id1,id2,id3])'; %'
elseif (nguard == 4)
   crisband_fstart = [ 648.75, 1208.75, 2153.75]-1.25;
   crisband_fend   = [1096.25, 1751.25, 2551.25]+1.25;

   f1 = crisband_fstart(1):crisband_df(1):crisband_fend(1);
   f2 = crisband_fstart(2):crisband_df(2):crisband_fend(2);
   f3 = crisband_fstart(3):crisband_df(3):crisband_fend(3);

   f = [f1, f2, f3]'; %'

   nchang0 = n1g0 + n2g0 + n3g0;
   id1 = [nchang0+[1:4], id1g0, nchang0+[5:8]];
   id2 = [nchang0+[9:12], id2g0, nchang0+[13:16]];
   id3 = [nchang0+[17:20], id3g0, nchang0+[21:24]];
   id = int32([id1,id2,id3])'; %'
else 
  error('Wrong number of guard channels');
end

% Read rtpin and check channels
[head, hattr, prof, pattr] = rtpread(rtpin);
%
idout = int32(head.ichan);
%
idmin = min(head.ichan);
idmax = max(head.ichan);
%
if (idmin < 1 | idmin > max(id) | idmax > max(id))
   error('rtpin head.ichan contains unexpected values')
end
%
% Match "id" to "idout"
[tf,indout] = ismember(idout,id);
if (min(tf) < 1)
   error('unable to match IDs for all channels in rtpin')
end


% Run klayers if needed
jout = get_sys_random_name();
rtpop = get_sys_random_name();
% jout = mktemp();
% rtpop = mktemp();
if (head.ptype == 0)
   disp('running klayers')
   eval(['! ' KLAYERS ' fin=' rtpin ' fout=' rtpop ' > ' jout]);
else
  eval(['! cp ' rtpin ' ' rtpop]);
end

% Prepare RTP for IASI SARTA runs in two parts
[head, hattr, prof, pattr] = rtpread(rtpop);
%
% Remove CrIS channel dependent fields before doing IASI calc
if (isfield(head,'vchan'))
  head = rmfield(head,'vchan');
end
if (isfield(prof,'robs1'))
  prof = rmfield(prof,'robs1');
  head.pfields = head.pfields - 4;
end
if (isfield(prof,'rcalc'))
  prof = rmfield(prof,'rcalc');
  head.pfields = head.pfields - 2;
end
if (isfield(prof,'calflag'))
  prof = rmfield(prof,'calflag');
end
%
% part1
head.nchan = 4231;
head.ichan = (1:4231)'; %'
rtpwrite(rtpop,head,hattr,prof,pattr);
%rtprad=mktemp();
rtprad=get_sys_random_name();
disp('running SARTA for IASI channels 1-4231')
eval(['! ' SARTA ' fin=' rtpop ' fout=' rtprad ' > ' jout]);
[head, hattr, prof, pattr] = rtpread(rtprad);
rad_pt1 = prof.rcalc;
%
% part2
head.nchan = 4230;
head.ichan = (4232:8461)'; %'
rtpwrite(rtpop,head,hattr,prof,pattr);
disp('running SARTA for IASI channels 4232-8461')
eval(['! ' SARTA ' fin=' rtpop ' fout=' rtprad ' > ' jout]);
[head, hattr, prof, pattr] = rtpread(rtprad);
rad_pt2 = prof.rcalc;
%
rad_iasi = [rad_pt1; rad_pt2];
clear rad_pt1 rad_pt2


% Convert IASI to cris888
disp('converting IASI to cris888')
atype = 'boxcar';

[f_cris, rad_cris] = iasi_to_cris888_grid(rad_iasi, atype, crisband_fstart, crisband_df, crisband_fend); 

%if (nguard == 0)
%   [f_cris, rad_cris] = iasi_to_cris888_g2(rad_iasi, atype);
%end
%if (nguard == 2)
%   [f_cris, rad_cris] = iasi_to_cris888_g2(rad_iasi, atype);
%end
r888 = rad_cris(indout,:);


% Clean up
unlink(jout);
unlink(rtpop);
unlink(rtprad);

%%% end of function %%%
