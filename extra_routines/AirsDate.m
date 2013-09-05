function dd=AirsDate(rtime,asnum)
% function dd=AirsDate(rtime,asnum)
%
% Returns the date, in a nice text format, for the AIRS rtime field.
%
% rtime = seconds since 1993/1/1 - 0:0:0
%
% asnum (optional) - 0 return the date string
%                    1 return matlab time (default)
%                   -1 REVERSE procedure, rtime now is matlab time, dd is rtime.
%                      This is good up to 1e-5 seconds or so. 
%
% Breno Imbiriba - 2008.05.22.


  if(~exist('asnum','var'))
    asnum=1;
  end

  if(~(asnum<0))
    day1993=rtime*1.157407407407407e-05;

    tt=datenum(1993,1,1)+day1993;

    if(asnum==0)
      dd=datestr(double(tt)); 
    else
      dd=tt;
    end
  else
    % If asnum is negative, will REVERT from mtime to rtime.
    % So rtime now is mtime:
    day1993=(rtime-datenum(1993,1,1));
    dd=day1993./1.157407407407407e-05;
  end

end
