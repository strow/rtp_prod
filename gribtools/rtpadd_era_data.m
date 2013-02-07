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
%               default:  {'SP','SKT','10U','10V','TCC','CI','T','Q','O3'} - from rtpadd_grib_data.m
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
  rn='rtpadd_era_data';
  greetings(rn);

  if ~exist('fields','var')
    fields = [];
  end

  [rtime rtime_st] = rtpdate(head,hattr,prof,pattr);

  rec_per_day = 4;

  days_to_test = unique(sort(floor(rtime * rec_per_day + .5) / rec_per_day));
  for d = days_to_test
    say(['reading era file for: ' datestr(d)])
    ename_lev = ['/asl/data/era/' datestr(d,'yyyy/mm') '/' datestr(d,'yyyymmdd') '_lev.grib'];
    ename_sfc = ['/asl/data/era/' datestr(d,'yyyy/mm') '/' datestr(d,'yyyymmdd') '_sfc.grib'];
    say(['  ' ename_lev])
    say(['  ' ename_sfc])
    if ~exist(ename_lev,'file')
      error(['Missing era file: ' ename_lev])
    end
    if ~exist(ename_sfc,'file')
      error(['Missing era file: ' ename_sfc])
    end

    [head, hattr, prof, pattr] = rtpadd_grib_data(ename_lev,head,hattr,prof,pattr,fields,rec_per_day,180);

    [head, hattr, prof, pattr] = rtpadd_grib_data(ename_sfc,head,hattr,prof,pattr,fields,rec_per_day,180);

    pattr = set_attr(pattr,'profiles','ERA','profiles');
  end

  farewell(rn);

end
