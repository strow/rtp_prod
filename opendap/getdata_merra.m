function [dat levels lats lons merra_str] = getdata_merra(time, field, level)
%function [dat levels lats lons merra_str] = getdata_merra(time, field, level)
%
%
%  Inputs:
%	time  - matlab time
%	field - fields to be requested
%	level - data level, level field has dimensions: 1:17
% 	        Note, if level field is omitted or empty then 
%               all levels are retrieved
% 
%       merra_str - a string with data file information
%
% 3D Fields available are:
%	h geopotential height 
%	o3 ozone mixing ratio 
%	qv specific humidity 
%	ql cloud liquid water mixing ratio 
%	qi cloud ice mixing ratio 
%	rh relative humidity 
%	t air temperature 
%	u eastward wind component 
%	v northward wind component 
%	epv ertel potential vorticity 
%	omega vertical pressure velocity
% 2D Fields available are:
%	slp sea-level pressure 
%	ps surface pressure 
%	phis surface geopotential 
%
% 2D Fields at the hourly files:
%       ts surface temperature


% Original location: /home/imbiriba/git/prod_mat/opendap/getdata_merra.m

% 3Hr files:
%	http://goldsmr3.sci.gsfc.nasa.gov/dods/MAI3CPASM/
% 1Hr files for surface skin temperature
%	http://goldsmr2.sci.gsfc.nasa.gov/opendap/MERRA/MAT1NXSLV.5.2.0/YYYY/MM/MERRA300.prod.assim.tavg1_2d_slv_Nx.YYYYMMDD.hdf



  switch field
    case {'ts','u2m','v2m'}
      % Call for the surface skin temperature 
      dattime_1h = round(  (time(1) - datenum(1979,1,1,0,30,0))*24 );
      filename = ['/asl/data/merra/' datestr(time(1),'yyyy/mm/dd') '/MAT1NXSLV_' field '_' datestr(round(time(1)*24)/24,'yyyymmdd-HHMMSS') '.mat'];

    otherwise
      % Call for other field variables
      dattime = round((time(1) - datenum(1979,1,1,0,0,0)) * 8);
      filename = ['/asl/data/merra/' datestr(time(1),'yyyy/mm/dd') '/MAI3CPASM_' field '_' datestr(round(time(1)*8)/8,'yyyymmdd-HHMMSS') '.mat'];
  end

  try
    mkdirs(dirname(filename));
  catch
    disp(['Cannot create ' dirname(filename)]);
    return
  end


  merra_str = filename;
  if exist(filename,'file')
      levels = [];
      load(filename)
      if nargin == 2 || length(level) == 0
	return
      end
      dat = dat(:,:,level);
      return
  end


  switch field
    case {'ts','u2m','v2m'}
      [dat x lats lons] = getdata_opendap('http://goldsmr2.sci.gsfc.nasa.gov/dods/MAT1NXSLV',[field '[' num2str(dattime_1h) ':1:' num2str(dattime_1h) '][0:360][0:539]']);

      % NOTE: The returned time can be converted to matlab time by doing this:
      % mtimes = times+365;  % i.e. it is one year 
      % mtimes = x + 365;
      levels=[];
      save(filename,'dat','lats','lons');
   
    case {'slp','ps','phis'}
      [dat x lats lons]=getdata_opendap('http://goldsmr3.sci.gsfc.nasa.gov/dods/MAI3CPASM', ...
	[field '[' num2str(dattime) ':1:' num2str(dattime) '][0:1:143][0:1:287]']);
      levels = [];
      save(filename,'dat','lats','lons');

    otherwise
      [dat x levels lats lons]=getdata_opendap('http://goldsmr3.sci.gsfc.nasa.gov/dods/MAI3CPASM', ...
	[field '[' num2str(dattime) ':1:' num2str(dattime) '][0:1:41][0:1:143][0:1:287]']);
      save(filename,'dat','levels','lats','lons');

      if nargin == 2 || length(level) == 0
	return
      end
      dat = dat(:,:,level);


  end


end
