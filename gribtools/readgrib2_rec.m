function [gribd] = readgrib2_rec(file,irec);

% function [gribd] = readgrib2_rec(file,irec);
%
% Read the specified record from a GRIB file.  This is basically
% just a MATLAB wrapper for the "wgrib" program.
%
% Input:
%    file : {string} name of an NCEP/ECMWF model grib file
%    irec : [1 x 1] record number
%
% Output:
%    gribd : [1 x N] {double} the requested grib data
%          
% Requires:  wgrib2 in your path.  wgrib2 is a program run via the
%	     shell that pull fields out of the grib2 file in a format
%            that can be read by Matlab.
%

% Created: 15 Mar 2006, Scott Hannon
% Update: 24 Sep 2008, S.Hannon - wgrib2 version created
% Update: 24 Mar 2009, S.Hannon - use "mktemp" for tmp filename and rename
%    "dump" file to recfile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


d = dir(file);
recfile = mktemp(['rec_' d.name]);

% Run wgrib2 and create temporary binary file
eval(['! wgrib2 -no_header -bin ' recfile ' -d ' num2str(irec) ' ' file ' > /dev/null']);

% Read temporary binary file
fid = fopen(recfile,'r');
gribd = fread(fid,'single')';   
junk = fclose(fid);

% Remove temporary binary file
eval(['! rm ' recfile])

%%% end of function %%%
