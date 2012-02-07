function [offset,param,level,date] = readgrib_inv_data(fname,savename)
%function [offset,param,level,date] = readgrib_inv_data(fname,savename)
%function [offset,param,level,date] = readgrib_inv_data(fname)
%
%  Read a GRIB file and return arrays of the invetory.
%
%  INPUTS:
%     fname    - grib file name
%     savename - path to save a copy of the inventory file (optional)
%                (by default the function tries to save a cached .inv 
%                 file in original file location)
%
%  OUTPUTS:
%     offset - needed for reading bytes
%     param  - text string of field
%     level  - pressure level of data
%     date   - matlab dateval of the associated field

% Written by Paul Schou - 4 May 2011
%  updated  14 June 2011 - added grib 2 checks

grib_ver = 1;

if ~exist([fname],'file')
  error(['GRIB file does not exist ' fname])
end

if exist([fname '.inv'],'file')
  %disp('Found inv file')
  d = dir([fname '.inv']);
  if d.bytes < 1000
    %disp('  Bad inv file')
    unlink([fname '.inv'])
  end
end

% check to see if inventory file exists
if ~(exist([fname '.inv'],'file'))
  % if it doesn't, lets make one and read it into memory
  tmpfile = mktemp(['inv_' basename(fname)]);
  %tmpfile = [fname '.inv']);
  grib_ver = getgribver(fname);
  if grib_ver == 1
    eval(['! /asl/opt/bin/wgrib -v ' fname ' > ' tmpfile]);
    [offset,date,param,kpds,fcst] = textread(tmpfile,'%*n%n%s%s%*s%s%s%*[^\n]','delimiter',':');
  else
    eval(['! /asl/opt/bin/wgrib2 -v ' fname ' > ' tmpfile]);
    [offset,date,param,kpds,fcst] = textread(tmpfile,'%*n%n%s%s%s%s%*[^\n]','delimiter',':');
  end
  %try; copyfile(tmpfile,[fname '.inv']); catch; end  % copy the temporary file into a useful place
  if nargin > 1
    try; copyfile(tmpfile,[savename '.inv']); catch; end  % save a copy to the savedir
  end
  try; copyfile(tmpfile,[fname '.inv']); catch; end  % save a copy to the location dir
  %unlink(tmpfile);  % delete inventory file
else
  % read in pre-created inventory file
  grib_ver = getgribver(fname);
  if grib_ver == 1
    [offset,date,param,kpds,fcst] = textread([fname '.inv'],'%*n%n%s%s%*s%s%s%*[^\n]','delimiter',':');
  else
    [offset,date,param,kpds,fcst] = textread([fname '.inv'],'%*n%n%s%s%s%s%*[^\n]','delimiter',':');
  end
  %[offset,date,param,kpds,fcst] = textread([fname '.inv'],'%*n%n%s%s%*s%s%s%*[^\n]','delimiter',':');
end

%if strcmp(getenv('USER'),'schou'); [fname '.inv']; keyboard; end

if grib_ver == 2
  for i = 1:length(param)
    param{i} = grib2param(param{i});
  end
end

% clean up the inventory fields
if nargout > 2
  if grib_ver == 1
    level = cellfun(@str2num,regexprep(kpds,'kpds=(\d*),(\d*),',''));
  else
    level = cellfun(@str2num,regexprep(kpds,' hybrid level',''));
  end
end

if nargout > 3
  date = datenum(regexprep(date,'[dD]=',''),'yyyymmddHH');

  s = strcmp(fcst,'3hr fcst'); date(s) = date(s) + 3/24;
  s = strcmp(fcst,'3 hour fcst'); date(s) = date(s) + 3/24;
  s = strcmp(fcst,'6hr fcst'); date(s) = date(s) + 6/24;
  s = strcmp(fcst,'6 hour fcst'); date(s) = date(s) + 6/24;
  s = strcmp(fcst,'9hr fcst'); date(s) = date(s) + 9/24;
  s = strcmp(fcst,'9 hour fcst'); date(s) = date(s) + 9/24;
  s = strcmp(fcst,'12hr fcst'); date(s) = date(s) + 12/24;
  s = strcmp(fcst,'12 hour fcst'); date(s) = date(s) + 12/24;
end
