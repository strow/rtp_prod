function [head, hattr, prof, pattr] = rtpadd_ecmwf_data(head, hattr, prof, pattr, fields);

% function [head, hattr, prof, pattr] = rtpadd_ecmwf_data(head, hattr, prof, pattr, fields);
%
% Routine to read in a 37, 60, or 91 level ECMWF file and return a
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
% Sequence
% 
% 0.1 Setup - rec_per_day - this is set in more than one place!!! This is inconsistent!
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  rn='rtpadd_ecmwf_data';
  greetings(rn);

  new_file = [];
  rec_per_day = 8;

  if ~exist('fields','var')
    fields = [];
  end
  [rtime rtime_st] = rtpdate(head,hattr,prof,pattr);

  rtime = rtime(~isnan(rtime));

  for d = unique(sort(round([rtime(:)-.003 rtime(:) rtime(:)+.003] * rec_per_day) / rec_per_day))';
    say(['reading ecmwf file for: ' datestr(d)])
    [Y M D h m s]= datevec(d);
    ename = ['/asl/data/ecmwf/' datestr(d,'yyyy/mm/') ecmwf_name(Y, M, D, h*10+m/6)];
    
    if(numel(dir([ename '*']))>=0)
      [head, hattr, prof, pattr] = rtpadd_grib_data(ename,head,hattr,prof,pattr,fields,8,0);
      pattr = set_attr(pattr,'profiles','ECMWF','profiles');
    else
      error(['File Not Found: ' ename '.']);
    end
  end

  farewell(rn);
end
