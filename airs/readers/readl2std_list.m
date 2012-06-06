function [ghead, gprof] = readl2std_list(fn,iatrack,ixtrack);

% function [ghead, gprof] = readl2std_list(fn,iatrack,ixtrack);
%
% Reads an AIRS level 2 Standard retrieval granule file and returns
% an RTP-like structure of retrieved profile & surface data.  Only
% returns those FOVs specified by (iatrack,ixtrack).
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%          'AIRS.2003.08.31.067.L2.RetStd.v3.1.9.0.A03261143158.hdf'
%    iatrack = [1 x n] desired along-track (1-45 scanline) indices
%    ixtrack = [1 x n] desired cross-track (1-30 footprint) indices
%
% Output:
%    ghead = (structure) RTP "head"-like structure
%    gprof = (structure) RTP "prof"-like structure. Returns RetQAFlag
%       in udef1.
%

% Created: 07 Mar 2006, S.Hannon - created based on readl2sup_list & readl2std
% Update: 17 Nov 2006, S.Hannon - rhoIRStd not in v5 so changed to (1-emis)/pi.
% Update: 28 Nov 2006, S.Hannon - add H2OMMRStd dimension check and if/then
%    block to handle v5 (14 levels) and also v4 (28 levels).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Granule dimensions
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;
nlevs = 28;


% Declare empty output vars
ghead = [];
gprof = [];


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error: bad fn: ' fn])
   return
end


% Check desired FOVs
d=size(iatrack);
if (length(d) ~= 2 | min(d) ~= 1)
   disp('Error: iatrack must be a [1 x n] vector')
   return
end
if (min(iatrack) < 1 | max(iatrack) > natrack)
   disp(['Error: iatrack must be within range 1-' num2int(natrack)]);
   return
end
n0=length(iatrack);
%
d=size(ixtrack);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n0)
   disp('Error: ixtrack must be the same length as iatrack')
   return
end
if (min(ixtrack) < 1 | max(ixtrack) > nxtrack)
   disp(['Error: ixtrack must be within range 1-' num2int(nxtrack)]);
   return
end
%
i0=round( ixtrack + (iatrack-1)*nxtrack );


% Open granule file
file_name=fn;
file_id  =hdfsw('open',file_name,'read');
%%%
% Uncomment the line below to see what swath names are found in file
% [NSWATH,SWATHLIST] = hdfsw('inqswath',fn)
%%%
swath_id = hdfsw('attach',file_id,'L2_Standard_atmospheric&surface_product');


% Read "RetQAFlag"
[junk,s]=hdfsw('readfield',swath_id,'RetQAFlag',[],[],[]);
if s == -1; disp('Error reading RetQAFlag');end;
retqaflag = reshape( double(junk), 1,nobs);
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
   disp('No pressStd; setting to default plevs')
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


% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk');


% Declare temporary variables for expansion
tmp_atrack=zeros(1,nobs);
tmp_xtrack=zeros(1,nobs);
tmp_zobs=zeros(1,nobs);


% Loop over along-track and fill in temporary variables
ix=1:nxtrack;
for ia=1:natrack
   iobs=nxtrack*(ia-1) + ix;
   %
   % Fill in cross-track
   tmp_atrack(iobs)=ia;
   tmp_xtrack(iobs)=ix;
   tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
end
%
clear ix ia iobs satheight


% Subset temporary variables and re-assign to gprof
gprof.atrack = tmp_atrack(i0);
gprof.xtrack = tmp_xtrack(i0);
gprof.zobs   = tmp_zobs(i0);
%
clear tmp_atrack tmp_xtrack tmp_zobs

%%%
%
%% Read granule start & end time (no per-FOV time)
%[junk,s]=hdfsw('readattr',swath_id,'start_Time');
%start_Time = double(junk(1));
%%
%[junk,s]=hdfsw('readattr',swath_id,'end_Time');
%end_Time = double(junk(1));
%
%
%% Compute approximate time for each FOV
%deltasec = (end_Time - start_Time);
%dtime = deltasec/(nobs - 1);
%time = zeros(nxtrack,natrack);
%indx = (1:nxtrack)';
%for ia = 1:natrack
%   time(:,ia)=start_Time + ((ia-1)*nxtrack + indx)*dtime; % approximate
%end
%junk2 = reshape( time, 1,nobs);
%gprof.ptime = junk2(i0);
%clear start_Time end_Time deltasec dtime indx time
%
%
%% Read the per FOV data
%%
%[junk,s]=hdfsw('readfield',swath_id,'latAIRS',[],[],[]);
%if s == -1; disp('Error reading latitude');end;
%junk2 = reshape( double(junk), 9,nobs);  % All 9 AIRS FOVS
%gprof.rlat = junk2(5,i0); % Center AIRS FOV
%gprof.plat = gprof.rlat;
%%
%[junk,s]=hdfsw('readfield',swath_id,'lonAIRS',[],[],[]);
%if s == -1; disp('Error reading longitude');end;
%junk2 = reshape( double(junk), 9,nobs); % All 9 AIRS FOVs
%gprof.rlon = junk2(5,i0); % Center AIRS FOV
%gprof.plon = gprof.rlon;
%%%


[junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
if s == -1; disp('Error reading Time');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.rtime = junk2(i0);
gprof.ptime = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.rlat = junk2(i0);
gprof.plat = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
if s == -1; disp('Error reading Longitude');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.rlon = junk2(i0);
gprof.plon = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satzen',[],[],[]);
if s == -1; disp('Error reading satzen');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.satzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satazi',[],[],[]);
if s == -1; disp('Error reading satazi');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.satazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solzen',[],[],[]);
if s == -1; disp('Error reading solzen');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.solzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solazi',[],[],[]);
if s == -1; disp('Error reading solazi');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.solazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'topog',[],[],[]);
if s == -1; disp('Error reading topog');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.salti =junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'landFrac',[],[],[]);
if s == -1; disp('Error reading landFrac');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.landfrac = junk2(i0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read surface emis/rho data
%
% numHingeSurf: [30x45 int16]
[junk,s]=hdfsw('readfield',swath_id,'numHingeSurf',[],[],[]);
if s == -1; disp('Error reading numHingeSurf');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.nemis = junk2(i0);
gprof.nrho  = junk2(i0);
maxnemis = max( gprof.nemis );
ie = 1:maxnemis;
%
% freqEmis: [100x30x45 single]
[junk,s]=hdfsw('readfield',swath_id,'freqEmis',[],[],[]);
if s == -1; disp('Error reading freqEmis');end;
junk = junk(ie,:,:);
junk2 = reshape( double(junk), maxnemis,nobs);
gprof.efreq = junk(:,i0);
gprof.rfreq = junk(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'emisIRStd',[],[],[]);
if s == -1; disp('Error reading emisIRStd');end;
junk = junk(ie,:,:);
junk2 = reshape( double(junk), maxnemis,nobs);
gprof.emis = junk(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'rhoIRStd',[],[],[]);
if (s == -1)
   disp('No rhoIRStd; will use (1-emis)/pi instead')
   gprof.rho = (1.0 - gprof.emis)/pi;
   % Plug in "nodata" where appropriate
   ii = find(gprof.emis < -998);
   gprof.rho(ii) = gprof.emis(ii);
   % Limit minimum rho
   ii = find(gprof.emis > 0.999);
   gprof.rho(ii) = 0.0003; % (1 - 0.999)/pi
else
   junk = junk(ie,:,:);
   junk2 = reshape( double(junk), maxnemis,nobs);
   gprof.rho = junk(:,i0);
end
%
clear maxnemis ie


%%%%%%%%%%%%%%%%%%%
% Read profile data
%
gprof.plevs = plevs*ones(1,length(i0));
%
[junk,s]=hdfsw('readfield',swath_id,'PSurfStd',[],[],[]);
if s == -1; disp('Error reading PSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.spres = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'TSurfStd',[],[],[]);
if s == -1; disp('Error reading TSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.stemp = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'nSurfStd',[],[],[]);
if s == -1; disp('Error reading nSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.nlevs = 29 - junk2(i0);  % reverse direction
%
[junk,s]=hdfsw('readfield',swath_id,'TAirStd',[],[],[]);
if s == -1; disp('Error reading TAirStd');end;
junk2 = reshape( double(junk), nlevs,nobs);
junk = junk2(:,i0);
gprof.ptemp = junk(ir,:); % reverse direction
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
gprof.gas_1 = junk(ir,:);  % reverse direction
%
[junk,s]=hdfsw('readfield',swath_id,'O3VMRStd',[],[],[]);
if s == -1; disp('Error reading O3VMRStd');end;
junk2 = reshape( double(junk), nlevs,nobs);
junk = junk2(:,i0);
gprof.gas_3 = junk(ir,:);  % reverse direction


% Declare udef array
gprof.udef=zeros(20,n0);


% Read total column water
[junk,s]=hdfsw('readfield',swath_id,'totH2OStd',[],[],[]);
if s == -1; disp('Error reading totH2OStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.udef(5,:) = junk2(i0);


%%%%%%%%%%%%%%%%%
% Read cloud info
[junk,s]=hdfsw('readfield',swath_id,'numCloud',[],[],[]);
if s == -1; disp('Error reading numCloud');end;
junk2 = reshape( double(junk), 1,nobs);
numcloud = junk2(i0);
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
gprof.cngwat = zeros(1,n0);
gprof.cngwat(ixcld) = junk2( i0(ixcld) );
gprof.udef(11,i2cld) = gprof.cngwat(i2cld);
%
[junk,s]=hdfsw('readfield',swath_id,'PCldTopStd',[],[],[]);
if s == -1; disp('Error reading PCldTopStd');end;
junk2 = reshape( double(junk), 2,nobs);
junk = junk2(:,i0);
gprof.cprtop = zeros(1,n0);
gprof.cprtop(i1cld) = junk(1,i1cld);
gprof.udef(13,i2cld) = junk(2,i2cld);
gprof.cprtop(i2cld) = junk(1,i2cld);
%
[junk,s]=hdfsw('readfield',swath_id,'CldFrcStd',[],[],[]);
if s == -1; disp('Error reading CldFrcStd');end;
junk2 = reshape( double(junk), 2*9,nobs);
junk = junk2(:,i0);
cfrac1 = mean( junk(1:9,:) );
cfrac2 = mean( junk(10:18,:) );
gprof.cfrac = zeros(1,n0);
gprof.cfrac(i1cld) = cfrac1(i1cld);
gprof.udef(15,i2cld) = cfrac2(i2cld);
gprof.cfrac(i2cld) = cfrac1(i2cld);


% AssignRetQAFlag to udef1
gprof.udef1 = retqaflag;


clear junk junk2 i0

% Close L2 Std Ret granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2');end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   disp('No good FOVs in L2ret granule file:')
   disp(fn)
   ghead=[];
   gprof=[];

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
