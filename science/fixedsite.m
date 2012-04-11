function [isiteind, isitenum] = fixedsite(lat, lon, range_km);

% function [isiteind, isitenum] = fixedsite(lat, lon, range_km);
%
% Find lat/lon within range of fixed sites.
%
% Input:
%    lat      : [1 x n] latitude -90 to 90
%    lon      : [1 x n] longitude -180 to 360
%    range_km : [1 x 1] max range (km)
%
% Output:
%    isiteind : [1 x m] indices of lat/lon within range
%    isitenum : [1 x m] site number
%

% Created: 11 April 2007, Scott Hannon
% Update: 20 April 2007, S.Hannon - fix "dist" conversion to km (was mm)
% Update:  3 March 2011, Paul Schou - added extra sites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Fixed sites used by AIRS
SiteLatLon=[ ...
    27.12   26.10; %  1 = Egypt 1
   -24.50  137.00; %  2 = Simpson Desert
   -75.10  123.40; %  3 = Dome Concordia, 3200 m elevation
     1.50  290.50; %  4 = Mitu, Columbia / Brazil tropical forest
     3.50   14.50; %  5 = Boumba, S.E. Cameroon
    38.50  244.30; %  6 = Railroad Valley, NV
    36.60  262.50; %  7 = ARM-SGP (southern great plains), OK
    -2.00  147.40; %  8 = Manus, Bismarck Archipelago
    -0.50  166.60; %  9 = ARM-TWP (tropical western pacific) Nauru, Micronesia
    90.00    0.00; % 10 = north pole
   -90.00    0.00; % 11 = south pole
    61.15   73.37; % 12 = Siberian tundra (Surgut)
    23.90  100.50; % 13 = Hunnan rain forest
    71.32  203.34; % 14 = Barrow, Alaska/ARM-NSA (north slope alaska)
    70.32  203.33; % 15 = Atqusuk, Alaska
   -12.42  130.89; % 16 = Darwin, Australia
    36.75  100.33; % 17 = Lake Qinhai
    40.17   94.33; % 18 = Dunhuang, Gobi desert
   -15.88  290.67; % 19 = Lake Titicaca
    39.10  239.96; % 20 = Lake Tahoe, CA
    31.05   57.65];% 21 = LUT Desert

% include global view sites
load gvsites.mat
SiteLatLon(101:100+length(gv_lat),:)=[gv_lat gv_lon];

if nargin == 0
  isiteind = SiteLatLon(:,1);
  isitenum = SiteLatLon(:,2);
  return
end

nSite = length(SiteLatLon);

% Approximately 111 km per 1 degree latitude
range_deg = range_km/111;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Longitude on 0:360 grid
lon360 = lon;
ii = find(lon < 0 & lon > -180.0001);
lon360(ii) = 360 + lon360(ii);

% Longitude on -180:180 grid
lon180 = lon360;
ii = find(lon360 > 180);
lon180(ii) = lon360(ii) - 360;

% Make up temporary work arrays
nin = length(lat);
sind = zeros(1,nin);
snum = zeros(1,nin);

dlatmax = range_deg; % latitude range

% Loop over the fixed sites
s = ~isnan(lat);
for isite=1:nSite
   % skip over sites that are not assigned
   if isequal(SiteLatLon(isite,:),[0 0])
      continue;
   end

   % current fixed site
   slat = SiteLatLon(isite,1);
   slon360 = SiteLatLon(isite,2);
   if (slon360 > 180)
      slon180 = slon360 - 360;
   else
      slon180 = slon360;
   end

%   % current longitude range
%   if (abs(slat) < 89.99)
%      dlonmax = range_deg./cos( slat*pi/180 );
%   else
%      dlonmax = 360;
%   end
%
%   % Latitude distance
%   dlat = abs(lat - slat);
%
%   % Longitude distance. As the site or input lat/lon might be near
%   % the longitude grid boundary at 180 or 360, calculate the
%   % logitude difference on both grids and use the smaller value.
%   dlon180 = abs(lon180 - slon180);
%   dlon360 = abs(lon360 - slon360);
%   dlon = min( [dlon180; dlon360] );
%
%   % Find indices of lat/lon within range
%   ideg = find(dlat <= dlatmax & dlon <= dlonmax);
%   if (length(ideg) > 0)
%      dist = latlon2dist(lat(ideg),lon360(ideg),slat,slon360)/1000;
%      ikm = ideg( find(dist < range_km) );
%      if (length(ikm) >0)
%         sind(ikm) = 1;
%         snum(ikm) = isite;
%      end
%   end

   sel = distance(slat,slon360,lat(s),lon(s)) < range_deg;
%disp([num2str(isite) ' - ' num2str(sum(sel))])
   sind(sel) = 1;
   snum(sel) = isite;
   s(sel) = 0;

end % for nSite

% Assign output arrays
isiteind = find(sind == 1);
isitenum = snum(isiteind);

%%% end of function %%%
