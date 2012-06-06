function [ghead, gprof] = readl2sup_list(fn,iatrack,ixtrack);

% function [ghead, gprof] = readl2sup_list(fn,iatrack,ixtrack);
%
% Reads an AIRS level 2 support products granule file and returns
% an RTP-like structure of retrieved profile & surface data.  Only
% returns those FOVs specified by (iatrack,ixtrack).
% Note: returns the pseudo-levels profile but not any radiances
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%          'AIRS.2003.09.01.074.L2.RetSup.v3.1.9.0.A03261142940.hdf'
%    iatrack = [1 x n] desired along-track (1-45 scanline) indices
%    ixtrack = [1 x n] desired cross-track (1-30 footprint) indices
%
% Output:
%    ghead = (structure) RTP "head"-like structure
%    gprof = (structure) RTP "prof"-like structure. Returns RetQAFlag
%       in udef1.
%

% Created: 19 oct 2004, Scott Hannon - based on readl2sup.m
% Update: 14 Dec 2004, S.Hannon - add udef1
% Update: 19 May 2005, S.Hannon - minor changes to index checks; change
%    "error" messages to "disp"/"return" messages.
% Update: 07 Nov 2005, S.Hannon - prof.udef changed to [20 x n] from [5 x n]
% Update: 12 Dec 2006, S.Hannon - made a few minor changes for PGE v5
% Update: 29 may 2008, S.Hannon - add granule number
% Update: 23 Feb 2009, S.Hannon - add olr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Granule dimensions
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;


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
swath_id =hdfsw('attach',file_id,'L2_Support_atmospheric&surface_product');

% Read granule number
[junk,s]=hdfsw('readattr',swath_id,'granule_number');
gnum = double(junk(1));

%% Read "RetQAFlag"
[junk,s]=hdfsw('readfield',swath_id,'RetQAFlag',[],[],[]);
if s == -1; disp('Error reading RetQAFlag');end;
retqaflag = reshape( double(junk), 1,nobs);
retqaflag = retqaflag(i0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (n0 > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk'); %'


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


% Read the per FOV data
%
[junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.rtime = junk2(i0);
meantime=mean(gprof.rtime);
%
[junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.plat = junk2(i0);
gprof.rlat = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
if s == -1; disp('Error reading Longitude');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.plon = junk2(i0);
gprof.rlon = junk2(i0);
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read surface emis/rho data
[junk,s]=hdfsw('readfield',swath_id,'numHingeSurf',[],[],[]);
if (s == -1)
   disp('No numHingeSurf data; skipping e/rfreq, emis,& rho');
else
   junk2 = reshape( double(junk), 1,nobs);
   gprof.nemis = junk2(i0);
   gprof.nrho = gprof.nemis;
   maxnemis = max(gprof.nemis);
   ii = 1:maxnemis;

   [junk,s]=hdfsw('readfield',swath_id,'freqEmis',[],[],[]);
   if (s == -1)
      disp('No freqEmis data');
   else
      junk2 = reshape( double(junk(ii,:,:)), maxnemis,nobs);
      gprof.efreq = junk2(:,i0);
      gprof.rfreq = gprof.efreq;
   end

   [junk,s]=hdfsw('readfield',swath_id,'emisIRStd',[],[],[]);
   if (s == -1)
      disp('No emisIRStd data');
   else
      junk2 = reshape( double(junk(ii,:,:)), maxnemis,nobs);
      gprof.emis = junk2(:,i0);
   end

   [junk,s]=hdfsw('readfield',swath_id,'Effective_Solar_Reflectance',[],[],[]);
   if (s == -1)
      disp('No Effective_Solar_Reflectance data');
   else
      junk2 = reshape( double(junk(ii,:,:)), maxnemis,nobs);
      gprof.rho = junk2(:,i0);
   end
   %
   clear maxnemis ii
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Read profile data
[junk,s]=hdfsw('readfield',swath_id,'PSurfStd',[],[],[]);
if s == -1; disp('Error reading PSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.spres = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'nSurfSup',[],[],[]);
if s == -1; disp('Error reading nSurfSup');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.nlevs = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'TSurfStd',[],[],[]);
if s == -1; disp('Error reading TSurfStd');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.stemp = junk2(i0);
%
% Note: the L2 pressure grid is not specified in the v5 files
gprof.plevs = set_plevs100_l2()*ones(1,n0);
%
[junk,s]=hdfsw('readfield',swath_id,'TAirSup',[],[],[]);
if s == -1; disp('Error reading TAirSup');end;
junk2 = reshape( double(junk), 100,nobs);
gprof.ptemp = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'H2OCDSup',[],[],[]);
if s == -1; disp('Error reading H2OCDSup');end;
junk2 = reshape( double(junk), 100,nobs);
gprof.gas_1 = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'O3CDSup',[],[],[]);
if s == -1; disp('Error reading O3CDSup');end;
junk2 = reshape( double(junk), 100,nobs);
gprof.gas_3 = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'COCDSup',[],[],[]);
if s == -1; disp('Error reading COCDSup');end;
junk2 = reshape( double(junk), 100,nobs);
gprof.gas_5 = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'CH4CDSup',[],[],[]);
if s == -1; disp('Error reading CH4CDSup');end;
junk2 = reshape( double(junk), 100,nobs);
gprof.gas_6 = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'CO2ppmv',[],[],[]);
if s == -1; disp('Error reading CO2ppmv');end;
junk2 = reshape( double(junk), 1,nobs);
gprof.co2ppm = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'olr',[],[],[]);
if s == -1; disp('Error reading olr');end;
junk2 = reshape( double(junk), 1,nobs);
olr = junk2(i0);
%
gprof.findex = gnum*ones(1,n0);

clear junk junk2 i0


% Close L2sup granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2sup');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2sup');end;


% Assign ghead
ghead.ptype=2;   % AIRS pseduo-level profile
ghead.pfields=1; % profile data only
ghead.ngas=4;
ghead.glist=[1; 3; 5; 6];
ghead.gunit=[1; 1; 1; 1];
ghead.nchan=0;


% Calculate total water column
gprof.udef = -9999*ones(20,n0);
gprof.udef(5,:) = mmwater_rtp(ghead,gprof);


% Assign RetQAFlag to udef1
gprof.udef1 = retqaflag;


% Assign olr to udef2
gprof.udef2 = olr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   disp('No good FOVs in L2sup granule file:')
   disp(fn)
   ghead=[];
   gprof=[];

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
