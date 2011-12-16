function [prof, pattr] = readsdr_rtp(pdfile);

% function [prof, pattr] = readsdr_rtp(pdfile);
%
% Read a CrIS HDF5 SDR "Product_Data" file and matching "Geolocation"
% file and return a RTP profiles structure and attributes for a
% subset of the data.
%
% Input:
%    pdfile  : [string] name of CrIS HDF5 SDR "Product_Data" file
%    Note: the first 37 char of the Geolocation basename is assumed
%    to be the same as pdfile except "SCRIS_" prefix replaced by "GCRSO_".
%
% Output:
%    prof    : [structure] RTPv201 "profiles" structure
%    pattr   : [cell array] attribute strings
%

% Created: 20 January 2011, Scott Hannon
% Update: 01 Mar 2011, S.Hannon - bug fix for ifov
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of seconds between 0z 1 Jan 1958 and 0z 1 Jan 2000 (excluding
% leap seconds).
seconds1958to2000 = 15340 * 24 * 3600;

% Note: nchan* includes 2 guards at each end of each band
nchanLW = 717;
nchanMW = 437;
nchanSW = 163;
nchan = round(nchanLW + nchanMW + nchanSW); % exact integer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 1)
   error('unexpected number of input arguments')
end

% Determine geofile from pdfile
junk = dirname(pdfile);
junk2 = basename(pdfile);
junk3 = strrep(junk2,'SCRIS_','GCRSO_');
geofile = [junk '/' junk3(1:37) '*.h5'];
d = dir(geofile);
if (length(d) == 1)
   geofile = [junk '/' d.name];
else
   pdfile;
   geofile;
   error('Unable to find matching geofile for pdfile')
end
clear junk junk2 junk3


% Read the Product_Data file
[pd] = readsdr_rawpd(pdfile);

% Read the Geolocation file
[geo] = readsdr_rawgeo(geofile);

% We have no means to check the match of pd and geo files but we
% can at least can check they have the same number of observations

% Create "prof" structure by subsetting data
prof = [];
%
if (isfield(geo,'Latitude'))
   junk = geo.Latitude;
   s = size(junk);
   nobs = round(prod(s)); % exact integer
   prof.rlat = reshape(junk,1,nobs);
else
   geo
   error('Missing required field Latitude')
end
%
if (isfield(geo,'Longitude'))
   junk = geo.Longitude;
   prof.rlon = reshape(junk,1,nobs);
else
   error('Missing required field Longitude')
end
%
if (isfield(geo,'FORTime'))
   % Convert IET1958 microseconds to TAI2000
   junk = double(geo.FORTime)*1E-6 - seconds1958to2000; % [30 x 4*n]
   s = size(junk);
   nx = round(prod(s)); % exact integer
   junk2 = reshape(junk,1,nx);
   prof.rtime = reshape(ones(9,1)*junk2,1,nobs);
else
   error('Missing required field FORTime')
end
%
if (isfield(geo,'SatelliteZenithAngle'))
   junk = geo.SatelliteZenithAngle;
   prof.satzen = reshape(junk,1,nobs);
else
   error('Missing required field SatelliteZenithAngle')
end
%
if (isfield(geo,'SatelliteAzimuthAngle'))
   junk = geo.SatelliteAzimuthAngle;
   prof.satazi = reshape(junk,1,nobs);
else
   error('Missing required field SatelliteAzimuthAngle')
end
%
if (isfield(geo,'SolarZenithAngle'))
   junk = geo.SolarZenithAngle;
   prof.solzen = reshape(junk,1,nobs);
else
   error('Missing required field SolarZenithAngle')
end
%
if (isfield(geo,'SolarAzimuthAngle'))
   junk = geo.SolarAzimuthAngle;
   prof.solazi = reshape(junk,1,nobs);
else
   error('Missing required field SolarAzimuthAngle')
end
%
%%%
% Unsure about "Height" (is it supposed to be zobs or salti?)
if (isfield(geo,'Height'))
   junk = geo.Height;
   prof.zobs = reshape(junk,1,nobs);
else
   error('Missing required field Height')
end
%%%
prof.pobs = zeros(1,nobs);
prof.upwell = ones(1,nobs);
iobs = 1:nobs;
prof.atrack = 1 + floor((iobs-1)/270);
prof.xtrack = 1 + mod(floor((iobs-1)/9),30);
%wrong prof.ifov = 1 + mod(iobs,9);
prof.ifov = 1 + mod(iobs-1,9);

%
if (isfield(pd,'ES_RealLW'))
   junk = pd.ES_RealLW;
   s = size(junk);
   if (s(1) ~= nchanLW)
      error('unexpected number of LW channels')
   end
   nobs_pd = round(prod(s(2:end))); % exact integer
   if (nobs_pd ~= nobs)
      error('Product_Data and Geolocation data have different nobs')
   end
   prof.robs1 = zeros(nchan,nobs);
   ic = 1:nchanLW;
   prof.robs1(ic,:) = reshape(junk,nchanLW,nobs);
else
   error('Missing required field ES_RealLW')
end
%
if (isfield(pd,'ES_RealMW'))
   junk = pd.ES_RealMW;
   s = size(junk);
   if (s(1) ~= nchanMW)
      error('unexpected number of MW channels')
   end
   ic = nchanLW + (1:nchanMW);
   prof.robs1(ic,:) = reshape(junk,nchanMW,nobs);
else
   error('Missing required field ES_RealMW')
end
%
if (isfield(pd,'ES_RealSW'))
   junk = pd.ES_RealSW;
   s = size(junk);
   if (s(1) ~= nchanSW)
      error('unexpected number of SW channels')
   end
   ic = nchanLW + nchanMW + (1:nchanSW);
   prof.robs1(ic,:) = reshape(junk,nchanSW,nobs);
else
   error('Missing required field ES_RealSW')
end


% Assign non-standard fields
prof.udef=zeros(20,nobs);
%
% Interpolate X,Y,Z at MidTime to rtime
if (isfield(geo,'SCPosition') & isfield(geo,'MidTime'))
   xyz = geo.SCPosition; % [3 x 4*n]
   mtime = double(geo.MidTime)*1E-6 - seconds1958to2000; % [1 x 4*n]
   prof.udef(10,:) = interp1(mtime,xyz(1,:),prof.rtime,'linear','extrap');
   prof.udef(11,:) = interp1(mtime,xyz(2,:),prof.rtime,'linear','extrap');
   prof.udef(12,:) = interp1(mtime,xyz(3,:),prof.rtime,'linear','extrap');
end
%%%

pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 2000'}, ...
         {'profiles' 'udef(10,:)' 'spacecraft X coordinate {X}'}, ...
         {'profiles' 'udef(11,:)' 'spacecraft Y coordinate {Y}'}, ...
         {'profiles' 'udef(12,:)' 'spacecraft Z coordinate {Z}'}, ...
        };

%%% end of function %%%
