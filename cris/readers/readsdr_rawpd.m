function [pd] = readsdr_rawpd(hfile);

% function [pd] = readsdr_rawpd(hfile);
%
% Read a CrIS HDF5 SDR "Product_Data" file and return the entire
% contents in a structure
% Note: see "readsdr_rawgeo.m" for CrIS HDF5 SDR "Geolocation" file.
%
% Input:
%    hfile : [string] name of CrIS HDF5 SDR "Product_Data" file
%
% Output:
%    pd   : [structure] CrIS SDR Product_Data with 28 fields
%

% Created: 20 January 2011, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = dir(hfile);
if (length(d) ~= 1)
   hfile
   error('bad filename')
end

% Get info about file contents
info = hdf5info(hfile);
nfields = length(info.GroupHierarchy.Groups(1).Groups(1).Datasets);

% Read all fields
pd =[];
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(1).Groups(1).Datasets(ii).Name);
   eval(['pd.' fname '=hdf5read(info.GroupHierarchy.Groups(1).Groups(1).' ...
      'Datasets(ii));'])
end

%%% end of function %%%
