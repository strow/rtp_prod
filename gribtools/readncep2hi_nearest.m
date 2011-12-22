function [head, prof] = readncep2hi_nearest(fname, fnameb, lat, lon);

% function [head, prof] = readncep2hi_nearest(fname, fnameb, lat, lon);
%
% Routine to read in the standard NCEP GFS 0.5x0.5 degree GRIB2 file
% plus the supplemental file, and return a 47 level RTP-like structure
% of GFS profiles that are the closest grid points to the specified
% lat/lon locations.
%
% Input:
%    fname  : [string] NCEP GFS 0.5x0.5 degree GRIB2 standard file
%    fnameb : [string] NCEP GFS 0.5x0.5 degree GRIB2 supplemental "b" file
%    lat    : [1 x nprof] latitudes (degrees -90 to +90)
%    lon    : [1 x nprof] longitudes (degrees, either 0 to 360 or -180 to 180)
%
% Output:
%    head : RTP "head" structure of header info with fields:
%       {ptype, pfields, ngas, glist, gunit, pmin, pmax}
%    prof : RTP "prof" structure of profile info with fields:
%       {ptime, plat, plon, rlat, rlon, stemp, spres, wspeed, cfrac, nlevs,
%        plevs, ptemp, gas_1, gas_3, udef}
%
% Notes:
%    prof.udef(1,:)=CICE, udef(2,:)=HGT, udef(3,:)=LAND
%    ptime is approximate TAI 2000.
%

% Created: 12 Dec 2011, Scott Hannon - based on readncep2_nearest.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Mininum allowed mixing ratios
min_gas_1 = 3.0;
min_gas_3 = 0.0269;

% Specific Humidity to ppmv conversion factor
H2O_kgkg_to_ppmv = 1E+6*28.966/18.0153;

% Ozone mass mixing ratio to ppmv conversion factor
O3_kgkg_to_ppmv = 1E+6*28.966/47.9982;

% Indices into udef for non-standard RTP fields
ind_udef_ICEC = 1;
ind_udef_HGT  = 2;
ind_udef_LAND = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check the NCEP GFS files exists
d = dir(fname);
if (length(d) ~= 1)
   disp(['did not find standard NCEP GFS file=' fname]);
   return
end
db = dir(fnameb);
if (length(db) ~= 1)
   disp(['did not find supplemental NCEP GFS file=' fnameb]);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size and specify grid resolution

if (d.bytes > 45E+6 & d.bytes < 62E+6)
   % Note: file size ~50-57 MB by Oct 2010
   % Number of ECMWF latitude points
   nlat = 361;  % -90:0.50:90
   nlon = 720;  %   0:0.50:359.50
   % pressure suffix string
   psuffixstr=' mb';
else
   disp('Unexpected standard NCEP GFS 0.5x0.5 degree file size; quitting')
   return
end
if (db.bytes < 38E+6)
   % Note: file size ~46 MB by Dec 2011
   disp('Unexpected supplemental NCEP GFS 0.5x0.5 degree file size; quitting')
   return
end

%%%%%%%%%%%%%%%%%%%
% Check lat and lon

nprof=length(lat);
if (length(lon) ~= nprof)
   disp('Error: lon and lat are different sizes!');
   return
end

% Latitude must be between -90 (south pole) and +90 (north pole)
ii=find(lat < -90 | lat > 90);
if (length(ii) > 0)
   disp('Error: latitude out of range!')
   ii
   lat(ii)
   return
end

% Note: longitude can be either 0 to 360=0 or 0 to 180=-180 to 0
ii=find(lon < -180 | lon > 360);
if (length(ii) > 0)
   disp('Error: longitude out of range!')
   ii
   lon(ii)
   return
end

% Convert any negative longitudes to positive equivalent
xlon =lon;
ii = find( lon < 0 );
xlon(ii) = 360 + lon(ii);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert (lat,lon) to fractional indices on a 2-D grid

halfnlatp1 = round( 0.5*(nlat-1) + 1 );
nlonp1 = nlon + 1;
latres = round( (nlat-1)/180 );
lonres = round( nlon/360 );

% Convert latitude
%%%
%glat = halfnlatp1 - latres*lat;
%%%
glat = halfnlatp1 + latres*lat;
ii = find(glat < 1);
glat(ii) = 1;
ii = find(glat > nlat); % impossible except for tiny precision errors
glat(ii) = nlat;

% Convert longitude
glon = 1 + lonres*xlon;
ii = find(glon < 1);
glon(ii) = 1;
ii = find(glon >= nlonp1);  % Note: nlonp1 is 360=0 degrees
glon(ii) = 1;

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the single nearest 2-D grid point

% Lon grid
iglon = floor( glon );
dg = glon - iglon;
ii = find( dg > 0.5);
iglon(ii) = iglon(ii) + 1;
ii = find(iglon == nlonp1);  % non-existant grid nlonp1 = grid 1 (0 deg)
iglon(ii) = 1;

% Lat grid
iglat = floor( glat );
dg = glat - iglat;
ii = find( dg > 0.5);
iglat(ii) = iglat(ii) + 1;
clear ii dg


%%%%%%%%%%%%%
% 1-D indices

% Note: in MATLAB, a 2-D (nrow, ncol) matrix is equivalent to a 1-D vector
% (nrow*ncol), with index translation 1-D index=irow + nrow*(icol-1).
%oldcode% i1D = iglat + nlat*(iglon - 1);
i1D = iglon + nlon*(iglat - 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NCEP GFS Pressure grids and data spans
%
% GFS pressure levels (standard + supplemental)
plevs_gfs = [  1   2   3   5   7  10  20  30  50  70 ...
             100 125 150 175 200 225 250 275 300 325 ...
             350 375 400 425 450 475 500 525 550 575 ...
             600 625 650 675 700 725 750 775 800 825 ...
             850 875 900 925 950 975 1000]'; %'
%
% Temperature "TMP" indices
ind_TMP_std = [6:10, 11:2:43, 44:47];
ind_TMP_sup = [1:5, 12:2:42];
%
%%% Ignore RH and use SPFH instead
%% Relative Humidity "RH" indices
%ind_RH_std = [6,8:10, 11:2:43, 44:47];
%ind_RH_sup = [12:2:42];
%% note: there is no RH for indices [1:5,7]
%%%
%
% Specific Humidity "SPFH" indices
% note: there is no SPFH data in the standard file
ind_SPFH_sup = [11:47];
% note: there is no SPFH for indices [1:10]; see AFGL SPFH data below
%
% Ozone mixing ratio "O3MR" indices
ind_O3MR_std = [6:11];
ind_O3MR_sup = [1:5];
% note: there is no O3MR for indices [12:47]; see AFGL O3MR data below


% Additional mixing ratio (ppmv) data from AFGL Model 6 US Standard
%
% O3MR for 125 to 1000 mb
ind_O3MR_afgl = [12:47];
O3MR_afgl = [0.6207 0.4601 0.3588 0.2912 0.2202 0.1628 0.1215 ...
             0.0986 0.0799 0.0637 0.0563 0.0519 0.0479 0.0442 ...
             0.0410 0.0397 0.0384 0.0372 0.0359 0.0347 0.0338 ...
             0.0336 0.0334 0.0332 0.0330 0.0327 0.0325 0.0322 ...
             0.0314 0.0307 0.0300 0.0293 0.0287 0.0281 0.0275 0.0269]'; %'
%
% SPFH for 1 to 70 mb
ind_SPFH_afgl = [1:10];
SPFH_afgl = [5.24 5.16 5.02 4.92 4.86 4.77 4.52 4.29 3.95 3.84]'; %'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get date from standard file and convert to TAI2000
[year, month, day, hour] = readgrib2_time(fname);
[ptime] = utc2tai2000(year, month, day, hour);
clear year month day hour

% Get an inventory of the standard GFS file
[rec,param,level] = readgrib2_inv(fname);

% Get an inventory of the supplemental GFS file
[recb,paramb,levelb] = readgrib2_inv(fnameb);


head = [];
head.ptype = int32(0);
head.pfields = int32(1);
head.ngas = int32(2);
head.glist = int32([1; 3]);  % 1=H2O, 3=O3
head.gunit = int32([10; 10]);  % 10 = ppmv
head.pmin = single(plevs_gfs(1));
head.pmax = single(plevs_gfs(47));


prof = [];
prof.plat = single( (iglat-1)/latres - 90 );
prof.plon = single( (iglon-1)/lonres );
prof.ptime = ptime*ones(1,nprof); % TAI2000
prof.rlat = single(lat);
prof.rlon = single(lon);
prof.udef = zeros(20,nprof,'single');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read surface fields from the standard GFS file

strlev = 'surface';
ilevel = strcmp(strlev,level);


% "TMP" temperature
iparam = strcmp('TMP',param);
ii = find( iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find sfc TMP in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.stemp = single(junk(i1D));


% "PRES" surface pressure
iparam = strcmp('PRES',param);
ii = find( iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find sfc PRES in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.spres = single(junk(i1D)/100); % convert Pa to hPa=mb


% Parameter "HGT" height
iparam = strcmp('HGT',param);
ii = find( iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find sfc HGT in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.udef(ind_udef_HGT,:) = single(junk(i1D));


% "LAND" land flag/fraction
iparam = strcmp('LAND',param);
ii = find(iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find LAND in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.udef(ind_udef_LAND,:) = single(junk(i1D));


% "ICEC" sea ice flag/fraction
iparam = strcmp('ICEC',param);
ii = find(iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find ICEC in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.udef(ind_udef_ICEC,:) = single(junk(i1D));


% 10 meter wind fields
strlev = '10 m above ground';
ilevel = strcmp(strlev,level);
%
% "UGRD" 10 meter u wind component
iparam = strcmp('UGRD',param);
ii = find(iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find 10 m above gnd UGRD in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
windu = junk(i1D);
%
% "VGRD" 10 meter v wind component
iparam = strcmp('VGRD',param);
ii = find(iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
   disp('did not find 10 m above gnd VGRD in GRIB inventory');
   return
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
windv = junk(i1D);
%
% Convert "u" and "v" wind velocities to total speed
prof.wspeed = single( sqrt(windu.^2 + windv.^2) );
%
%%% remove wsource for rtpV201
%% WARNING!: I am not sure the direction conversion is correct
%prof.wsource = -9999*ones(1,nprof);
%iun = find(windu < 0);
%ivn = find(windv < 0);
%iup = find(windu > 0);
%ivp = find(windv > 0);
%iu0 = find(windu == 0);
%iv0 = find(windv == 0);
%windu(iu0) = 1E-15;
%windv(iv0) = 1E-15;
%angle = atan( abs(windu)./abs(windv) )*180/pi;
%% from north (ie pointing south)
%ii = intersect(iu0,ivn);
%prof.wsource(ii) = 0;
%% from east
%ii = intersect(iun,iv0);
%prof.wsource(ii) = 90;
%% from south
%ii = intersect(iu0,ivp);
%prof.wsource(ii) = 180;
%% from west
%ii = intersect(iup,iv0);
%prof.wsource(ii) = 270;
%% from 0-90 (ie pointing 180-270)
%ii = intersect(iun,ivn);
%prof.wsource(ii) = angle(ii);
%% from 90-180 (ie pointing 270-360)
%ii = intersect(iun,ivp);
%prof.wsource(ii) = 180 - angle(ii);
%% from 180-270 (ie pointing 0-90)
%ii = intersect(iup,ivp);
%prof.wsource(ii)=180 + angle(ii);
%% from 270-360 (ie pointing 90-180)
%ii = intersect(iup,ivn);
%prof.wsource(ii) = 360 - angle(ii);
%%%
%
clear windu windv


% "TCDC" total cloud cover (%)
% Update 30 April 2007: TCDC may be "convect-cld layer" or "atmos col"
strlev = 'convective cloud layer';
ilevel = strcmp(strlev,level);
iparam = strcmp('TCDC',param);
ii = find(iparam == 1 & ilevel == 1);
if (length(ii) ~= 1)
%   strlev = 'convect-cld layer';
%   ilevel = strcmp(strlev,level);
%   ii = find(iparam == 1 & ilevel == 1);
%   if (length(ii) ~= 1)
      disp('did not find TCDC at 0-CCY in GRIB inventory');
      return
%   end
end
irec = rec(ii);
junk = readgrib2_rec(fname,irec);
prof.cfrac = single(junk(i1D)/100); % convert percent to fraction


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the pressure levels data

prof.nlevs = int32( 47*ones(1,nprof) );
ii = find(prof.spres < plevs_gfs(47));
yi = interp1(plevs_gfs, 1:47, prof.spres(ii), 'linear');
prof.nlevs(ii) = ceil( yi );


prof.plevs = single(plevs_gfs*ones(1,nprof));
prof.ptemp = zeros(47,nprof,'single');
prof.gas_1 = zeros(47,nprof,'single');
prof.gas_3 = zeros(47,nprof,'single');


% "TMP" temperature
%
% standard GFS file
iparam = strcmp('TMP',param);
for ii = 1:length(ind_TMP_std)
   il = ind_TMP_std(ii);
   strlev = [int2str( plevs_gfs(il) ) psuffixstr];
   ilevel = strcmp(strlev,level);
   ii = find( iparam == 1 & ilevel == 1);
   if (length(ii) ~= 1)
      disp(['did not find ' strlev ' TMP in standard GFS inventory']);
      return
   end
   irec = rec(ii);
   junk = readgrib2_rec(fname,irec);
   prof.ptemp(il,:) = single(junk(i1D));
end
%
% Find "TMP" records in supplemental GFS file
iparam = strcmp('TMP',paramb);
for ii = 1:length(ind_TMP_sup)
   il = ind_TMP_sup(ii);
   strlev = [int2str( plevs_gfs(il) ) psuffixstr];
   ilevel = strcmp(strlev,levelb);
   ii = find( iparam == 1 & ilevel == 1);
   if (length(ii) ~= 1)
      disp(['did not find ' strlev ' TMP in supplemental GFS inventory']);
      return
   end
   irec = recb(ii);
   junk = readgrib2_rec(fnameb,irec);
   prof.ptemp(il,:) = single(junk(i1D));
end


% "SPFH" specific humidity
iparam = strcmp('SPFH',paramb);
for ii = 1:length(ind_SPFH_sup)
   il = ind_SPFH_sup(ii);
   strlev = [int2str( plevs_gfs(il) ) psuffixstr];
   ilevel = strcmp(strlev,levelb);
   ii = find( iparam == 1 & ilevel == 1);
   if (length(ii) ~= 1)
      disp(['did not find ' strlev ' SPFH in supplemental GFS inventory']);
      return
   end
   irec = recb(ii);
   junk = readgrib2_rec(fnameb,irec);
   prof.gas_1(il,:) = single(junk(i1D)*H2O_kgkg_to_ppmv);
end
%
% AFGL additional data
for ii=1:length(ind_SPFH_afgl)
   il = ind_SPFH_afgl(ii);
   prof.gas_1(il,:) = single(SPFH_afgl(ii)*ones(1,nprof));
end


% "O3MR" ozone mixing ratio
%
% standard GFS file
iparam = strcmp('O3MR',param);
for ii = 1:length(ind_O3MR_std)
   il = ind_O3MR_std(ii);
   strlev = [int2str( plevs_gfs(il) ) psuffixstr];
   ilevel = strcmp(strlev,level);
   ii = find( iparam == 1 & ilevel == 1);
   if (length(ii) ~= 1)
      disp(['did not find ' strlev ' TMP in standard GFS inventory']);
      return
   end
   irec = rec(ii);
   junk = readgrib2_rec(fname,irec);
   prof.gas_3(il,:) = single(junk(i1D)*O3_kgkg_to_ppmv);
end
%
% supplemental GFS file
iparam = strcmp('O3MR',paramb);
for ii = 1:length(ind_O3MR_sup)
   il = ind_O3MR_sup(ii);
   strlev = [int2str( plevs_gfs(il) ) psuffixstr];
   ilevel = strcmp(strlev,levelb);
   ii = find( iparam == 1 & ilevel == 1);
   if (length(ii) ~= 1)
      disp(['did not find ' strlev ' TMP in supplemental GFS inventory']);
      return
   end
   irec = recb(ii);
   junk = readgrib2_rec(fnameb,irec);
   prof.gas_3(il,:) = single(junk(i1D)*O3_kgkg_to_ppmv);
end
%
% AFGL additional data
for ii=1:length(ind_O3MR_afgl)
   il = ind_O3MR_afgl(ii);
   prof.gas_3(il,:) = single(O3MR_afgl(ii)*ones(1,nprof));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Limit tiny mixing ratios

ii = find(prof.gas_1 < min_gas_1);
if (length(ii) > 0)
   prof.gas_1(ii) = min_gas_1;
end

ii = find(prof.gas_3 < min_gas_3);
if (length(ii) > 0)
   prof.gas_3(ii) = min_gas_3;
end


%%% end of function %%%
