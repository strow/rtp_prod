function [rec,param,level] = readgrib2_inv(file);

% function [rec,param,level] = readgrib2_inv(file);
%
% Read an inventory of a GRIB file.  This is basically
% just a MATLAB wrapper for the "wgrib2" program.
%
% Input:
%    file : {string} name of an NCEP/ECMWF model grib file
%
% Output:
%    rec   : [1 x Nrec] record number
%    param : [1 x Nrec] {string cell} parameter name
%    level : [1 x Nrec] {string cell} type of level
%          
% Requires:  wgrib2 in your path.  wgrib is a program run via the
%	     shell that pull fields out of the grib2 file in a format
%            that can be read by Matlab.
%

% Created: 15 Mar 2006, Scott Hannon
% Update: 16 May 2006, Scott Hannon - change temporary inventory file
%    name from "dump" to "inv_<file>".
% Update: 24 Sep 2008, S.Hannon - wgrib2 version created
% Update: 24 Mar 2009, S.Hannon - use "mktemp" for tmp filename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


d = dir(file);
invfile = mktemp(['inv_' d.name]);

% Run wgrib and create temporary inventory file
eval(['! wgrib2 -s ' file ' | cut -f1,4,5 -d":" > ' invfile]);

% Read temporary text file
[rec,param,level] = textread(invfile,'%n%s%s\n','delimiter',':');

% Remove temporary inventory file
eval(['! rm ' invfile])

%%% end of function %%%
