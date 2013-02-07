function [rtime rtime_st] = rtpdate(head,hattr,prof,pattr)
%function [rtime rtime_st] = rtpdate(head,hattr,prof,pattr)
% - or -  [rtime rtime_st] = rtpdate(prof,pattr)
%
%  rtime    - Matlab date number from the rtp structure from rtime
%  rtime_st - Start time used for the rtime seconds
%
%  Get the matlab time for a given rtp structure

%  Written by Paul Schou 2011

% if we only have 2 inputs instead of 4 inputs
if nargin == 2
  prof = head;
  pattr = hattr;
end

% Check the rtime field to see if it is valid
rtime_str = get_attr(pattr,'rtime');
%if debug; disp(['rtime str = ' rtime_str]); end
if length(rtime_str) >= 4
  st_year = str2num(rtime_str(end-4:end));
  if st_year < 1900
    error('Invalid start year in rtime attribute.')
  end
else
  if isfield(prof,'robs1') & size(prof.robs1,1) == 2378
    disp('Warning: using airs start year for prof.rtime.  Try pattr=set_attr(pattr,''rtime'',''Seconds since 1993'');')
    st_year = 1993;
  else
    error('Missing start year in rtime attribute.  Try pattr=set_attr(pattr,''rtime'',''Seconds since 1993'');')
  end
end
rtime = datenum(st_year,1,1,0,0,prof.rtime);
rtime_st = datenum(st_year,1,1,0,0,0);

end
