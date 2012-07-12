function [dat levels lats lons era_str] = getdata_era(time, field, level)
%function [dat levels lats lons era_str] = getdata_era(time, field, level)
%
% Input:
%
% time  = Time (in matlab format) for the desired profiles
% field = Name (string) of the desired field
%         3D field names - T, Q, O3, CLWC, CIWC, CC
%         2D field names - TCC, SP, SKT, CI, 10V, 10U
%
% level = ( optional )  Pressure (in mbar) of the desired level to get.
%         This variable can be an array of pressures.
%
% Output:
%       dat       =  2D or 3D array of data
%       levels    =  Data pressure levels (0 for surface data)
%       lats/lons = latitude and logitudes (calculated in the code)
%       era_str   = a string with data file information
%
% Breno Imbiriba - 2012.07.12 
% (based on Paul Schou's routines)


  % ERA Number of data records per day (hours of the day: 0, 6, 12, 18)
  rec_per_day = 4;

  % Check if data is 2D or 3D and Get file name
  is2d=strcmp(field, {'TCC', 'SP', 'SKT', 'CI', '10V', '10U'});
  is3d=strcmp(field, {'T', 'Q', 'O3', 'CLWC', 'CIWC', 'CC'});
  
  if(any(is3d)) 
    sourcename = ['/asl/data/era/' datestr(time,'yyyy/mm') '/' datestr(time,'yyyymmdd') '_lev.grib'];
  elseif(any(is2d))
    sourcename = ['/asl/data/era/' datestr(time,'yyyy/mm') '/' datestr(time,'yyyymmdd') '_sfc.grib'];
  else
    error(['Bad field name ' field '.']);
  end
  era_str=sourcename;


  % If not requesting a level, get them all
  if(nargin()<3)
    level=[];
  end


  %%%%%%%%%%%%%%%%%%%%%%%% 
  % Load Inventory file

  if(exist([sourcename '.inv']) & exist([sourcename]))
    [offset,param,glevels,gribdate] = readgrib_inv_data(sourcename);
    if(~( max(gribdate+0.5/rec_per_day) >= min(time) & min(gribdate-0.5/rec_per_day) < max(time) ))
      error(['GRIB file times out of range']);
      return
    end
  else
    error(['Needed GRIB Files do not exist: ' sourcename '*']);
  end


  %%%%%%%%%%%%%%%%%%%%%%%%
  % Read Data file

  fh = fopen(sourcename,'r','b');
  disp(['  opening grib 1 file ' sourcename]);

  % Find the Nearest record - Howard's trick
  ugribdate = unique(gribdate); 
  iugribdate = interp1(ugribdate, [1:numel(ugribdate)], time, 'nearest');
  irecs = find( gribdate == ugribdate(iugribdate));

  % Find the Nearest level 
  uglevels = unique(glevels);
  if(numel(level)>0)
    iuglevels = interp1(uglevels, [1:numel(uglevels)], level, 'nearest');
    thislevel = uglevels(iuglevels);
  else 
    thislevel=uglevels;
  end
 
  % Loop over and select the desired field - read data
  ik=0;
  for irec=irecs'
    if(strcmp(param{irec},field) & any(glevels(irec)==thislevel))
      ik=ik+1;
      dat(:,:,ik) = readgrib_offset_data(fh, offset(irec));
      levels(ik)   = glevels(irec);
    end
  end
  fclose(fh);

  if(all(levels==0))
    levels=0;
  end
  if(any(sort(levels)~=levels))
    warning('Levels are out of order');
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Compute latitudes and logitudes
  % Is it cell centered or node centered??
  % According to: http://www.ecmwf.int/products/data/archive/data_faq.html#fieldunits 
  % Question 22, it should be node centered.
  % Question 30, ERA-Interim uses the N128 grid (the model), but going to http://www.ecmwf.int/publications/library/ecpublications/_pdf/era/era_report_series/RS_1.pdf, PG.15 you see the 1.5ox1.5o mentioned, but reference to the start point.
  % As earlier the greenwitch and equator lines are mentioned, I'll assume that both occur in the data.

  nlons = size(dat,1);
  nlats = size(dat,2); % ERA has points at the poles
  dlon = 360/nlons; 
  dlat = 180/(nlats-1); 

  lat0 = 90; 
  lon0 =-180;
  
  lats = lat0 - ([1:nlats]-1)*dlat;
  lons = lon0 + ([1:nlons]-1)*dlon;

end

