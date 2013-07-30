function sdata = interp_sphere(lats, lons, data, tlats, tlons, method)
% function sdata = interp_sphere(lats, lons, data, tlats, tlons, method)
%
% Interpolate data assuming that base grid has S2-{N,S} topology (I'm not going to be careful with the poles! So I'll remove them for now.
%
% All the interpolation is done using interp2, but the grid is "massaged"
% so we have no invalid points and +-180 are the same. 
%
% lats(1,nlats)
% lons(1,nlons)
% data(nlons, nlats)
%
 
  % 1. Glue together -180 with +180 by adding a few extra datalines

  lon0 = min(lons);
  lon1 = max(lons);
  dlon = (lon1-lon0)/(numel(lons)-1);

  lat0 = min(lats);
  lat1 = max(lats);
  dlat = (lat1-lat0)/(numel(lats)-1);


  % Add enough meridians to pass +-180, and two extra points for the poles
  lon_left = -180-dlon; 
  nmeridle = ceil((lon0 - lon_left)/dlon);

  lon_righ = 180+dlon;
  nmeridri = ceil((lon_righ - lon1)/dlon);

  sized = size(data);
  data1 = NaN([sized(1)+nmeridle+nmeridri, sized(2)+2]);


  % Add core data
  data1(nmeridle+1:nmeridle+sized(1),1+1:1+sized(2)) = data;

  % Add side bands
  data1(1:nmeridle, 2:1+sized(2)) = data(sized(1)-nmeridle+1:sized(1), :);
  data1(nmeridle+sized(1)+1:nmeridle+sized(1)+nmeridri, 2:1+sized(2)) = data(1:nmeridri, :);

  % Add Poles as  the mean of the last latitude
  Npole = nanmean(data(:,sized(2)));
  Spole = nanmean(data(:,1));

  data1(:, 1) = Spole;
  data1(:, end) = Npole;


  % Compute new lats and lons

  lats1 = [lat0-dlat:dlat:lat1+dlat];
  lons1 = [lon0-dlon*nmeridle:dlon:lon1+dlon*nmeridri];

  %% 
  % Now Call interp2

  sdata = interp2(lats1, lons1, data1, tlats, tlons, method);



end

