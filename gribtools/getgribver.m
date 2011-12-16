function ver = getgribver(fname)
%function ver = getgribver(fname)
%
%  Get the grib version number from a Grib file.
%

% Written 14 June 2011 - Paul Schou

if ~exist(fname,'file')
  error(['Missing file ' fname])
end
fh = fopen(fname,'r');
if fh < 1
  error(['Error opening file ' fname])
end
fseek(fh,7,-1);
ver = fread(fh,1,'uint8');
fclose(fh);
