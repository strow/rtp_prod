function [meantime, f, gdata] = readl2cc_list(fn, iatrack, ixtrack);

% function [meantime, f, gdata] = readl2cc_list(fn, iatrack, ixtrack);
%
% Reads an AIRS level 2 cloud-clear radiance granule file and returns
% an RTP-like structure of those FOVs specified by (iatrack,ixtrack).
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%            'AIRS.2003.10.18.023.L2.CC.v4.0.0.0.Focus.T04285042114.hdf'
%    iatrack = [1 x n] desired along-track (scanline) indices {1-45}
%    ixtrack = [1 x n] desired cross-track (footprint) indices {1-30}
%
% Output:
%    meantime = (1x 1) mean time of observations, in hours
%    f  = (nchan x 1) channel frequencies
%    gdata = (structure) RTP "prof" like structure with RetQAFlag
%       value returned in udef1
%

% Created: 19 May 2005, Scott Hannon - based on readl2cc.m
% Update: 08 Sep 2006, S.Hannon - add default freq
% Update: 17 Nov 2006, S.Hannon - minor change to "freq" error block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
nchan=2378;
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;

% Default f
load /asl/matlab/airs/readers/f_default_l1b.mat
f_default = f;

% Declare empty output vars
meantime = [];
f = [];
gdata = [];


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error: bad fn: ' fn])
   return
end


% Check along-track indices
d = size(iatrack);
if (length(d) ~= 2 | min(d) ~= 1)
   disp('Error: iatrack must be a [1 x n] vector')
   return
end
if (min(iatrack) < 1 | max(iatrack) > natrack)
   disp(['Error: iatrack must be within range 1-' num2int(natrack)]);
   return
end
n0 = length(iatrack);


% Check cross-track indices
d = size(ixtrack);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n0)
   disp('Error: ixtrack must be the same length as iatrack')
   return
end
if (min(ixtrack) < 1 | max(ixtrack) > nxtrack)
   disp(['Error: ixtrack must be within range 1-' num2int(nxtrack)]);
   return
end


% Open granule file
file_name=fn;
file_id  =hdfsw('open',file_name,'read');
swath_id =hdfsw('attach',file_id,'L2_Standard_cloud-cleared_radiance_product');


% Indices of desired FOVs
i0 = round( ixtrack + (iatrack-1)*nxtrack );


% Read "RetQAFlag"
[junk,s]=hdfsw('readfield',swath_id,'RetQAFlag',[],[],[]);
if s == -1; disp('Error reading RetQAFlag');end;
retqaflag = reshape( double(junk), 1,nobs);
retqaflag = retqaflag(i0);


% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk'); %'
%
% CalFlag (nchan x natrack)
[raw_calflag,s]=hdfsw('readfield',swath_id,'CalFlag',[],[],[]);
if s == -1; disp('Error reading CalFlag'); end;
% Do not reshape or convert to double yet


% Declare temporary variables for expansion
tmp_atrack=zeros(1,nobs);
tmp_xtrack=zeros(1,nobs);
tmp_zobs=zeros(1,nobs);
%
junk=blanks(nchan*nobs);
tmp_calflag=reshape(junk, nchan,nobs);  % large char array!
clear junk

% Loop over along-track and fill in temporary variables
ix=1:nxtrack;
for ia=1:natrack
   iobs=nxtrack*(ia-1) + ix;
   %
   % Fill in cross-track
   tmp_atrack(iobs)=ia;
   tmp_xtrack(iobs)=ix;
   tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
   for ii=1:nxtrack
      tmp_calflag(:,iobs(ii))=raw_calflag(:,ia);
   end
end
%
clear ix ia iobs satheight raw_calflag


% Subset temporary variables for state and re-assign to gdata
gdata.atrack = tmp_atrack(i0);
gdata.xtrack = tmp_xtrack(i0);
gdata.zobs   = tmp_zobs(i0);
gdata.calflag= double( tmp_calflag(:,i0) );
%
clear tmp_atrack tmp_xtrack tmp_zobs tmp_calflag


% Read in the channel freqs
[junk,s]=hdfsw('readfield',swath_id,'freq',[],[],[]);
if (s == -1)
   disp('No freq data; using default')
   f = f_default;
else
   f = double(junk);
end
% Note: the order of the following "if" test is apparently important;
% when the max test is first and f is empty, the max test is not true
% and the "or" length test is ignored!
if (length(f) == 0 | max(f) < -998)
   disp('WARNING! L2CC file contains bad freq; using default')
   f = f_default;
end


% Read in observed radiance, reshape, and subset for state.
% Note: this is a large array!
% observed radiance is stored as (nchan x nxtrack x natrack)
[junk,s]=hdfsw('readfield',swath_id,'radiances',[],[],[]);
if s == -1; disp('Error reading radiances');end;
% reshape but do not convert to double yet
junk2 = reshape(junk, nchan,nobs);
clear junk
% subset and convert to double
gdata.robs1=double( junk2(:,i0) );
clear junk2


% Read the per FOV data
%
[junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rtime = junk2(i0);
meantime=mean(gdata.rtime);
%
[junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rlat = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
if s == -1; disp('Error reading Longitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rlon = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'scanang',[],[],[]);
if s == -1; disp('Error reading scanang');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.scanang = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satzen',[],[],[]);
if s == -1; disp('Error reading satzen');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.satzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satazi',[],[],[]);
if s == -1; disp('Error reading satazi');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.satazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solzen',[],[],[]);
if s == -1; disp('Error reading solzen');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.solzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solazi',[],[],[]);
if s == -1; disp('Error reading solazi');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.solazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'topog',[],[],[]);
if s == -1; disp('Error reading topog');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.salti =junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'landFrac',[],[],[]);
if s == -1; disp('Error reading landFrac');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.landfrac = junk2(i0);
%
clear junk junk2 i0


% Assign RetQAFlag to udef1
gdata.udef1 = retqaflag;


% Close L2CC granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2CC');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2CC');end;

%%% end of function %%%
