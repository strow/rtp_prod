function [rtime rtime_st] = rtpdate(varargin)
%function [mtime mtime_st] = rtpdate(head,hattr,prof,pattr)
%         [mtime mtime_st] = rtpdate(prof,pattr)
%         [mtime mtime_st] = rtpdate(rtime,year0)
%
%  Converts instrument "rtime" into matlab time, from a RTP sub-structure
%   
%  Althoug the routine can be called in three ways, there are only two 
%  arguments that are read:
%  
%  rtime - (prof.rtime, rtime): vector or instrument rtimes 
%                               (seconds since start year)
%
%  year0 - Starting year (AIRS: 1993, IASI/CrIS: 2000)
%          This number comes usually as an attribute:
%          pattr{}={'profiles','rtime','Seconds since YYYY'}; 
%          (YYYY = year0).
%          You can create this attribute with set_attr:
%          pattr = set_attr('profiles','rtime','Seconds since YYYY');
%
%  Written by 
%  Paul Schou 2011
%  Breno Imbiriba 2013.02.07

% Check input arguments - two of four inputs
if(nargin == 2)
  if(isstruct(varargin{1}))
    prof = varargin{1};
    pattr = varargin{2};
  else
    prof.rtime = varargin{1};
    pattr = set_attr('profiles','rtime',['Seconds since ' num2str(varargin{2})]);
  end
else
  prof = varargin{3};
  pattr = varargin{4};
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
