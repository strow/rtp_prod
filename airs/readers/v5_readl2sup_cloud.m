function [cloud] = readl2sup_cloud(fn,iatrack,ixtrack);

% function [cloud] = readl2sup_cloud(fn,iatrack,ixtrack);
%
% Reads an AIRS level 2 Support products granule file and returns
% a structure containing the full 3x3 two cloud retrieval info for
% each specified AMSU FOV. Also dust & SO2 info.
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%       'AIRS.2003.05.27.168.L2.RetSup.v5.0.3.0.Focus.T06344105956.hdf'
%    iatrack = [1 x n] desired along-track (1-45 scanline) indices
%    ixtrack = [1 x n] desired cross-track (1-30 footprint) indices
%
% Output:
%    cloud = structure with the following fields:
%       atrack         = [1 x n] AMSU FOV along-track index
%       xtrack         = [1 x n] AMSU FOV cross-track index
%       Qual_Cloud_OLR = [1 x n] quality flaq {0=best, 1=okay, 2=bad}
%       numCloud       = [1 x n] number of clouds {0-2}
%       totCldH2OStd   = [1 x n] all clouds total liquid water [kg/m^2]
%       TCldTopStd     = [2 x n] Cloud top temperarure [Kelvin]
%       PCldTopStd     = [2 x n] Cloud top pressure [hPa]
%       CldFrcStd      =[18 x n] cloud fraction (index 1-9=cloud#1, 10-18=#2)
%       numHingeCloud  = [1 x n] cloud number of emis/rho/freq points (max="m")
%       cldFreq        = [m x 2 x n] cloud emis/rho freq pts [cm^-1]
%       CldEmis        = [m x 2 x n] cloud emissivity pts
%       CldRho         = [m x 2 x n] cloud reflectivity pts
%       latAIRS        = [9 x n] AIRS FOV latitude
%       lonAIRS        = [9 x n] AIRS FOV longitude
%       dust_flag      = [9 x n] dust flag
%       dust_score     = [9 x n] dust score
%       BT_diff_SO2    = [9 x n] 2 channel BT difference due to dust
%

% Created: 12 Dec 2006, S.Hannon - created based on readl2std_cloud
% Update: 10 Jan 2007, S.Hannon - add comments for emis/rho info above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;
maxcloud = 2;


% Declare empty output structure
cloud = [];


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
swath_id = hdfsw('attach',file_id,'L2_Support_atmospheric&surface_product');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (n0 > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
% Uncomment the line below to inquire about attribute names
% [NATTR,ATTRLIST] = hdfsw('inqattrs',swath_id)
%%%


cloud.atrack = iatrack;
cloud.xtrack = ixtrack;


% Read Qual_Cloud_OLR
[junk,s] = hdfsw('readfield',swath_id,'Qual_Cloud_OLR',[],[],[]);
if s == -1; disp('Error reading Qual_Cloud_OLR');end;
junk2 = reshape( double(junk), 1,nobs);
cloud.Qual_Cloud_OLR = junk2(i0);


% Read number of clouds
[junk,s]=hdfsw('readfield',swath_id,'numCloud',[],[],[]);
if s == -1; disp('Error reading numCloud');end;
junk2 = reshape( double(junk), 1,nobs);
cloud.numCloud = junk2(i0);

%%%
%i0cld = find(numcloud == 0);
%i1cld = find(numcloud == 1);
%i2cld = find(numcloud == 2);
%ixcld = union(i1cld,i2cld);
%%%

% Read total clouds liquid water
[junk,s]=hdfsw('readfield',swath_id,'totCldH2OStd',[],[],[]);
if s == -1; disp('Error reading totCldH2OStd');end;
junk2 = reshape( double(junk), 1,nobs);
% Note: retrieval returns only one water value
cloud.totCldH2OStd = junk2(i0);


% Read cloud top temperature
[junk,s]=hdfsw('readfield',swath_id,'TCldTopStd',[],[],[]);
if s == -1; disp('Error reading TCldTopStd');end;
junk2 = reshape( double(junk), 2,nobs);
cloud.TCldTopStd = junk2(:,i0);


% Read cloud top pressure
[junk,s]=hdfsw('readfield',swath_id,'PCldTopStd',[],[],[]);
if s == -1; disp('Error reading PCldTopStd');end;
junk2 = reshape( double(junk), 2,nobs);
cloud.PCldTopStd = junk2(:,i0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read cloud emis & rho
% Note: for v5 this is always(?) emis=1 and rho=0 (or -9999)

% Read number of cloud emis/rho points
[junk,s]=hdfsw('readfield',swath_id,'numHingeCloud',[],[],[]);
if s == -1; disp('Error reading numHingeCloud');end;
junk2 = reshape( double(junk), 1,nobs);
cloud.numHingeCloud = junk2(i0);
nmax = max(cloud.numHingeCloud);
ii = 1:nmax;

% Read emis/rho freq points
[junk,s]=hdfsw('readfield',swath_id,'cldFreq',[],[],[]);
if s == -1; disp('Error reading cldFreq');end;
junk2 = reshape( double(junk(ii,:,:,:)), nmax,2,nobs);
cloud.cldFreq = junk2(:,:,i0);

% Read emis points
[junk,s]=hdfsw('readfield',swath_id,'CldEmis',[],[],[]);
if s == -1; disp('Error reading CldEmis');end;
junk2 = reshape( double(junk(ii,:,:,:)), nmax,2,nobs);
cloud.CldEmis = junk2(:,:,i0);

% Read rho points
[junk,s]=hdfsw('readfield',swath_id,'CldRho',[],[],[]);
if s == -1; disp('Error reading CldRho');end;
junk2 = reshape( double(junk(ii,:,:,:)), nmax,2,nobs);
cloud.CldRho = junk2(:,:,i0);

clear nmax ii

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Read cloud fractions for 3x3 AIRS FOVs
[junk,s]=hdfsw('readfield',swath_id,'CldFrcStd',[],[],[]);
if s == -1; disp('Error reading CldFrcStd');end;
% Note: junk is dimensioned 2 x [3 x 3] x [30 x 45]
junk2 = reshape( double(junk), 2,9,nobs);
cloud.CldFrcStd = zeros(18,n0);
cloud.CldFrcStd(1:9,:) = junk2(1,:,i0);
cloud.CldFrcStd(10:18,:) = junk2(2,:,i0);


% Read AIRS FOV dust flag
[junk,s]=hdfsw('readfield',swath_id,'dust_flag',[],[],[]);
if s == -1; disp('Error reading dust_flag');end;
junk2 = reshape( double(junk), 9,nobs);
cloud.dust_flag = junk2(:,i0);

% Read AIRS FOV dust score
[junk,s]=hdfsw('readfield',swath_id,'dust_score',[],[],[]);
if s == -1; disp('Error reading dust_score');end;
junk2 = reshape( double(junk), 9,nobs);
cloud.dust_score = junk2(:,i0);


% Read AIRS FOV SO2
[junk,s]=hdfsw('readfield',swath_id,'BT_diff_SO2',[],[],[]);
if s == -1; disp('Error reading BT_diff_SO2');end;
junk2 = reshape( double(junk), 9,nobs);
cloud.BT_diff_SO2 = junk2(:,i0);


% Read AIRS FOV lat and lon
[junk,s]=hdfsw('readfield',swath_id,'latAIRS',[],[],[]);
if s == -1; disp('Error reading latAIRS');end;
junk2 = reshape( double(junk), 9,nobs);
cloud.latAIRS = junk2(:,i0);
%
[junk,s]=hdfsw('readfield',swath_id,'lonAIRS',[],[],[]);
if s == -1; disp('Error reading lonAIRS');end;
junk2 = reshape( double(junk), 9,nobs);
cloud.lonAIRS = junk2(:,i0);


clear junk junk2 i0


% Close L2 Std Ret granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2');end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   disp('No valid FOVs in L2ret granule file:')
   disp(fn)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
