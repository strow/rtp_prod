function [year, month, day, hour] = readgrib2_time(file);

% function [year, month, day, hour] = readgrib2_time(file);
%
% Read forecast time string from a GRIB file and convert to numbers.
% This is basically just a MATLAB wrapper for the "wgrib2" program.
% This version for grib2 files.
%
% Input:
%    file : {string} name of an NCEP/ECMWF model grib file
%
% Output:
%    year : [1 x 1] year
%    month: [1 x 1] month
%    day  : [1 x 1] day
%    hour : [1 x 1] hour of forecast

%          
% Requires:  wgrib in your path.  wgrib is a C program run via the
%	     shell that pull fields out of the grib file in a format
%            that can be read by Matlab.
%

% Created: 22 July 2011, Scott Hannon - based on readgrib_time.m
% Update: 12 Dec 2011, S.Hannon - change from time "-t" to verification
%    time "-verf"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


d = dir(file);
invfile = mktemp(['inv_' d.name]);

%%% old
%% Run wgrib and create temporary inventory file
%eval(['! /asl/opt/bin/wgrib2 -t -end ' file ' | cut -f3 -d":" > ' invfile]);
%
%% Read temporary text file "d=YYYYMMDDHH"
%[junk, year,month,day,hour] = textread(invfile,'%2c%4u%2u%2u%2u');
%%%

% Run wgrib and create temporary inventory file
eval(['! /asl/opt/bin/wgrib2 -verf -end ' file ' | cut -f3 -d":" > ' invfile]);

% Read temporary text file "vt=YYYYMMDDHH"
[junk, year,month,day,hour] = textread(invfile,'%3c%4u%2u%2u%2u');

% Remove temporary files
eval(['! rm ' invfile])

%%% end of function %%%
