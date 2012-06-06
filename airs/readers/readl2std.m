function [ghead, gdata] = readl2std(fn, iQA);

% function [ghead, gdata] = readl2std(fn, iQA);
% OBSOLETE; use "readl2std_qa.m" & "readl2std_list.m" instead.
%
% Reads an AIRS level 2 Standard retrieval granule file and returns
% an RTP-like structure of retrieved profiles.
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%          'AIRS.2003.08.31.067.L2.RetStd.v3.1.9.0.A03261143158.hdf'
%    iQA = optional [1 x nQA] passing RetQAFlag values. Default=0.
%
% Output:
%    ghead = (structure) RTP "head" like structure
%    gdata = (structure) RTP "prof" like structure.  Returns RetQAFlag
%       in udef1.
%
% Note: if the granule contains no good data, the output variables
% are returned empty.
%

% Created: 01 October 2003, Scott Hannon - based on readl1b_all.m
% Update: 14 Dec 2004 S.Hannon - add iQA and input checks; add udef1
% Update: 15 Dec 2004 S.Hannon - add cloud parameters & total water column;
%    add default plevs; reverse profiles so output is top-of-atmos down;
%    replace output var meantime with ghead; add plat/plon.
% Update: 28 Nov 2006, S.Hannon - add H2OMMRStd dimension check and if/then
%    block to handle v5 (14 levels) and also v4 (28 levels).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;
nlevs=28;


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error, bad fn: ' fn])
   return
end

% Check iQA
if (nargin == 2)
   d = size(iQA);
   if (length(d) ~= 2 | min(d) ~= 1)
      disp('Error, bad iQA')
      return
   end
else
   % Set default iQA
   iQA = 0;
end
nQA = length(iQA);


% Open granule file
file_name = fn;
file_id   = hdfsw('open',file_name,'read');
%%%
% Uncomment the line below to see what swath names are found in file
% [NSWATH,SWATHLIST] = hdfsw('inqswath',fn)
%%%
swath_id  = hdfsw('attach',file_id,'L2_Standard_atmospheric&surface_product');

% Read "RetQAFlag" and find good FOVs
[junk,s]=hdfsw('readfield',swath_id,'RetQAFlag',[],[],[]);
if s == -1; disp('Error reading RetQAFlag');end;
retqaflag = reshape( double(junk), 1,nobs);


% Find FOVs with RetQAFlag in iQA
i0 = find( ismember(retqaflag,iQA) == 1);
%%% This following line of code was used before iQA was added
%i0=find( retqaflag == 0);  % Indices of "good" FOVs
%%%
n0=length(i0);
%
retqaflag = retqaflag(i0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (n0 > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
% Uncomment the line below to inquire about attribute names
% [NATTR,ATTRLIST] = hdfsw('inqattrs',swath_id)
%%%

% Read the std pressure levels
[junk,s]=hdfsw('readattr',swath_id,'pressStd');
if (s == -1)
   % pressStd is missing from file!
   disp('WARNING! HDF file is missing pressStd; setting to default plevs')
   % defaut 28 pressure levels (reverse direction compared to DAAC doc)
   ir = 28:-1:1; % indices used to reverse profile direction
   plevs = zeros(28,1);
   plevs(28) = 1100.0;
   plevs(27) = 1000.0;
   plevs(26) =  925.0;
   plevs(25) =  850.0;
   plevs(24) =  700.0;
   plevs(23) =  600.0;
   plevs(22) =  500.0;
   plevs(21) =  400.0;
   plevs(20) =  300.0;
   plevs(19) =  250.0;
   plevs(18) =  200.0;
   plevs(17) =  150.0;
   plevs(16) =  100.0;
   plevs(15) =   70.0;
   plevs(14) =   50.0;
   plevs(13) =   30.0;
   plevs(12) =   20.0;
   plevs(11) =   15.0;
   plevs(10) =   10.0;
   plevs( 9) =    7.0;
   plevs( 8) =    5.0;
   plevs( 7) =    3.0;
   plevs( 6) =    2.0;
   plevs( 5) =    1.5;
   plevs( 4) =    1.0;
   plevs( 3) =    0.5;
   plevs( 2) =    0.2;
   plevs( 1) =    0.1;
else
   plevs = double(junk);
end


% Head structure
ghead.ptype = 0; % levels
ghead.pfields = 1; % profile info only
ghead.ngas = 2;
ghead.glist = [1; 3];
ghead.gunit = [20; 12];
ghead.nchan = 0;


% Read the date/time fields
[junk,s]=hdfsw('readattr',swath_id,'start_year');
l2.start_year = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_month');
l2.start_month = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_day');
l2.start_day = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_hour');
l2.start_hour = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_minute');
l2.start_minute = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_sec');
l2.start_sec = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'start_Time');
l2.start_Time = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'end_Time');
l2.end_Time = double(junk(1));


% Compute approximate time for each FOV
deltasec=(l2.end_Time - l2.start_Time);
dtime=deltasec/(nobs - 1);
time=zeros(nxtrack,natrack);
indx=(1:nxtrack)';
for ia=1:natrack
   time(:,ia)=l2.start_Time + ((ia-1)*nxtrack + indx)*dtime; % approximate
end
meantime=(0.5*deltasec + l2.start_sec)/3600 + l2.start_minute/60 + ...
   l2.start_hour;
%
clear l2 deltasec dtime indx


% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk');


% Declare temporary variables for expansion
tmp_atrack=zeros(1,nobs);
tmp_xtrack=zeros(1,nobs);
tmp_rtime=zeros(1,nobs);
tmp_zobs=zeros(1,nobs);


% Loop over along-track and fill in temporary variables
ix=1:nxtrack;
for ia=1:natrack
   iobs=nxtrack*(ia-1) + ix;
   %
   % Fill in cross-track
   tmp_atrack(iobs)=ia*3 - 1;  % convert AMSU index to AIRS center FOV
   tmp_xtrack(iobs)=ix*3 - 1;  % convert AMSU index to AIRS center FOV
   tmp_rtime(iobs)=time(:,ia);
   tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
end
%
clear ix ia iobs time satheight


% Subset temporary variables for state and re-assign to gdata
gdata.atrack = tmp_atrack(i0);
gdata.xtrack = tmp_xtrack(i0);
gdata.rtime  = tmp_rtime(i0);
gdata.zobs   = tmp_zobs(i0);
%
clear tmp_atrack tmp_xtrack tmp_rtime tmp_zobs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the per FOV instrument & geolocation data
%
[junk,s]=hdfsw('readfield',swath_id,'latAIRS',[],[],[]);
if s == -1; disp('Error reading latitude');end;
junk2 = reshape( double(junk), 9,nobs);  % All 9 AIRS FOVS
gdata.rlat = junk2(5,i0); % Center AIRS FOV
gdata.plat = gdata.rlat;
%
[junk,s]=hdfsw('readfield',swath_id,'lonAIRS',[],[],[]);
if s == -1; disp('Error reading longitude');end;
junk2 = reshape( double(junk), 9,nobs); % All 9 AIRS FOVs
gdata.rlon = junk2(5,i0); % Center AIRS FOV
gdata.plon = gdata.rlon;
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read retrieved profile data
%
gdata.plevs = plevs*ones(1,length(i0));
%
[junk,s]=hdfsw('readfield',swath_id,'PSurfStd',[],[],[]);
if s == -1; disp('Error reading PSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.spres = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'TSurfStd',[],[],[]);
if s == -1; disp('Error reading TSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.stemp = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'nSurfStd',[],[],[]);
if s == -1; disp('Error reading nSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.nlevs = 29 - junk2(i0);  % reverse direction
%
[junk,s]=hdfsw('readfield',swath_id,'TAirStd',[],[],[]);
if s == -1; disp('Error reading TAirStd');end;
junk2 = reshape( double(junk), nlevs,nobs);
junk = junk2(:,i0);
gdata.ptemp = junk(ir,:); % reverse direction
%
[junk,s]=hdfsw('readfield',swath_id,'H2OMMRStd',[],[],[]);
if s == -1; disp('Error reading H2OMMRStd');end;
d = size( junk );
if (d(1) == 14)
   % v5 only has the bottom 14 levels for H2OMMRStd
   junk2 = reshape( double(junk), 14,nobs);
   junk = 4.0 * 6.22E-4 * ones(nlevs,n0); % = 4 ppmv
   junk(1:14,:) = junk2(:,i0);
else
   if (d(1) == nlevs)
      junk2 = reshape( double(junk), nlevs,nobs);
      junk = junk2(:,i0);
   else
      disp('Error, unexpected size for H2OMMRStd');
   end
end
gdata.gas_1 = junk(ir,:);  % reverse direction
%
[junk,s]=hdfsw('readfield',swath_id,'O3VMRStd',[],[],[]);
if s == -1; disp('Error reading O3VMRStd');end;
junk2 = reshape( double(junk), nlevs,nobs);
junk = junk2(:,i0);
gdata.gas_3 = junk(ir,:);  % reverse direction


% Declare udef array
gdata.udef=zeros(20,n0);


% Read total column water
[junk,s]=hdfsw('readfield',swath_id,'totH2OStd',[],[],[]);
if s == -1; disp('Error reading totH2OStd');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(5,:) = junk2(:,i0);


% Read cloud info
[junk,s]=hdfsw('readfield',swath_id,'numCloud',[],[],[]);
if s == -1; disp('Error reading numCloud');end;
junk2 = reshape( double(junk), 1,nobs);
numcloud = junk2(:,i0);
i0cld = find(numcloud == 0);
i1cld = find(numcloud == 1);
i2cld = find(numcloud == 2);
ixcld = union(i1cld,i2cld);
clear numcloud
%
[junk,s]=hdfsw('readfield',swath_id,'totCldH2OStd',[],[],[]);
if s == -1; disp('Error reading totCldH2OStd');end;
junk2 = reshape( double(junk), 1,nobs);
% Note: retrieval returns only one water value; repeat for both clouds
gdata.cngwat(ixcld) = junk2(:,i0(ixcld));
gdata.udef(11,i2cld) = gdata.cngwat(i2cld);
%
[junk,s]=hdfsw('readfield',swath_id,'PCldTopStd',[],[],[]);
if s == -1; disp('Error reading PCldTopStd');end;
junk2 = reshape( double(junk), 2,nobs);
junk = junk2(:,i0);
gdata.cprtop(i1cld) = junk(1,i1cld);
gdata.udef(13,i2cld) = junk(2,i2cld);
gdata.cprtop(i2cld) = junk(1,i2cld);
%
[junk,s]=hdfsw('readfield',swath_id,'CldFrcStd',[],[],[]);
if s == -1; disp('Error reading CldFrcStd');end;
junk2 = reshape( double(junk), 2*9,nobs);
junk = junk2(:,i0);
cfrac1 = mean( junk(1:9,:) );
cfrac2 = mean( junk(10:18,:) );
gdata.cfrac(i1cld) = cfrac1(i1cld);
gdata.udef(15,i2cld) = cfrac2(i2cld);
gdata.cfrac(i2cld) = cfrac1(i2cld);


% AssignRetQAFlag to udef1
gdata.udef1 = retqaflag;


clear junk junk2 i0

% Close L2 Std Ret granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2');end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   disp('No good FOVs in L2 granule file:')
   disp(fn)

   meantime=[];
   f=[];
   gdata=[];

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
