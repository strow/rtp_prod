function [head, hattr, prof, pattr] = rtpadd_era_data(head, hattr, prof, pattr, fields);

% function [head, hattr, prof, pattr] = rtpadd_era_data(head, hattr, prof, pattr, fields);
%
% Routine to read in a 37, 60, or 91 level ERA file and return a
% RTP-like structure of profiles that are the closest grid points
% to the specified (lat,lon) locations.
%
% Input:
%    head      : rtp header structure
%    hattr     : header attributes
%    prof.       profile structure with the following fields
%        rlat  : (1 x nprof) latitudes (degrees -90 to +90)
%        rlon  : (1 x nprof) longitude (degrees, either 0 to 360 or -180 to 180)
%        rtime : (1 x nprof) observation time in seconds
%    pattr     : profile attributes, note: rtime must be specified
%    fields    : list of fields to consider when populating the rtp profiles:
%                 {'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'}
%               default:  {'SP','SKT','10U','10V','TCC','CI','T','Q','O3'}
%
% Output:
%    head : (RTP "head" structure of header info)
%    hattr: header attributes
%    prof : (RTP "prof" structure of profile info)
%    pattr: profile attributes
%
% Note: uses external routines: p60_ecmwf.m, p91_ecmwf.m, readgrib_inv_data.m,
%    readgrib_rec_data.m, as well as the "wgrib" program.
%

% Created: 17 Mar 2006, Scott Hannon - re-write of old 60 level version
% Rewrite:  4 May 2011, Paul Schou - switched to matlab binary reader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

min_H2O_gg = 3.1E-7;  % 0.5 pppm
min_O3_gg = 1.6E-8;   % 0.01 ppm
new_file = [];

if ~exist('fields','var')
  fields = [];
%else
%  disp(fields)
end
[rtime rtime_st] = rtpget_date(head,hattr,prof,pattr);

disp('using rtpadd_era_data')
rec_per_day = 4;
for d = unique(sort(round([rtime-0.1 rtime rtime+0.1] * rec_per_day) / rec_per_day));
  disp(['reading era file for: ' datestr(d)])
  %ename = ['/asl/data/ecmwf/era/' datestr(d,'yyyymm') '_cld'];
  ename = ['/asl/data/era/' datestr(d,'yyyy/mm') '/' datestr(d,'yyyymmdd') '_lev.grib'];
  disp(['  ' ename])

  % If the file is empty, remove it
  %if exist(ename,'file')
  %  t = dir(ename);
  %  if t.bytes == 0
  %    unlink(ename);
  %  end
  %end

  % Uncomment this section if you want automatic era downloading to take place
  %if ~exist(ename,'file')
  %  system(['/asl/opt/bin/getera ' datestr(d,'yyyymmdd')])
  %end
  if ~exist(ename,'file')
    error(['Missing era file: ' ename])
  end

  [head, hattr, prof, pattr] = rtpadd_grib_data(ename,head,hattr,prof,pattr,fields,rec_per_day,180);
  ename = ['/asl/data/era/' datestr(d,'yyyy/mm') '/' datestr(d,'yyyymmdd') '_sfc.grib'];
  disp(['  ' ename])
  if ~exist(ename,'file')
    error(['Missing era file: ' ename])
  end
  [head, hattr, prof, pattr] = rtpadd_grib_data(ename,head,hattr,prof,pattr,fields,rec_per_day,180);
  pattr = set_attr(pattr,'profiles','ERA','profiles');
end
