function [salti, landfrac] = usgs_degN(lat, lon, deg_step);

% function [salti, landfrac] = usgs_degN(lat, lon, deg_step);
%
% Return surface altitude and land fraction for the nearest
% point in the 10 points per degree lookup table.
% Note: resolution is roughly 11 km near the equator.
%
% Input:
%    lat      : [1 x nobs ] latitude (degrees)
%    lon      : [1 x nobs ] longitude (degrees)
%    deg_step : [1 x 1 ] step size for grid (degrees)
%
% Output:
%    salti    : [1 x nobs] surface altitude (meters)
%    landfrac : [1 x nobs] land fraction
%
% Sources: elevation is based on USGS GTOPO30 data. Land fraction
% is based on UMD (College Park) GLCF 1 km land cover classification
% data.  The original data has been spatially averaged (12x12 points)
% from 1/120 of a degree to 1/10 of a degree by Breno Imbiriba, UMBC.
%

% Created: 05 Jun 2007, Scott Hannon - based on ecmwf_dem.m
% Modified: 04 Jun 2010, Paul Schou
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


dem_file='/asl/data/usgs/world_grid_deg10.mat';
% Note: dem_file must contain fields landfrac and salti
% Note: DEM is structured
%    Loop lon = 0.05 : 0.10 : 359.95
%       Loop lat = 89.95 : -0.10 : -89.95


% Load ECMWF Digital Elevation Map file
eval(['load ' dem_file]);
deg_step = round(deg_step*10)/10;
landfrac = downscale(landfrac,[deg_step*10 deg_step*10]);
salti = downscale(salti,[deg_step*10 deg_step*10]);

ilat = max(1,min(size(landfrac,1),round((90-lat)/deg_step)));
ilon = max(1,min(size(landfrac,2),round(wrapTo360(lon+deg_step/2)/deg_step)));

ii = sub2ind(size(landfrac),ilat,ilon);

landfrac = landfrac(ii);
salti = salti(ii);

% Code to verify this is functioning correctly:
% [la lo]=meshgrid(-90:90,-180:180);                 
% [a b]=usgs_degN(la(:),lo(:),2);                  
% simplemap(la(:),lo(:),b,1)
