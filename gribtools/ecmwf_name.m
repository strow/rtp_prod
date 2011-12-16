function [name, ystr, mstr, dstr] = ecmwf_name(iyear, imonth, iday, ihour10);

% function [name, ystr, mstr, dstr] = ecmwf_name(iyear, imonth, iday, ihour10);
%
% Return ECMWF filename (without path) for the specified date/time.
%
% Input:   all values must be integers
%    iyear   = [1 x 1] year
%    imonth  = [1 x 1] month
%    iday    = [1 x 1] day of month{
%    ihour10 = [1 x 1] decimal hour times 10 {ie 0 to 240}
%
% Output:
%    name = [string] filename (without path) of closest ECMWF file
%    ystr = [string] year
%    mstr = [string] month
%    dstr = [string] day
%

% Created: 29 April 2005, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
d = size(iyear);
if (length(d) ~= 2 | max(d) ~= 1 | min(d) ~= 1)
   error('iyear must be a [1 x 1] integer')
end
if (abs(iyear - round(iyear)) ~= 0)
   error('iyear must be a [1 x 1] integer')
end
if (iyear < 1960 | iyear > 2100)
   error('iyear is outside the range of valid years')
end
%
d = size(imonth);
if (length(d) ~= 2 | max(d) ~= 1 | min(d) ~= 1)
   error('imonth must be a [1 x 1] integer')
end
if (abs(imonth - round(imonth)) ~= 0)
   error('imonth must be a [1 x 1] integer')
end
if (imonth < 1 | imonth > 12)
   error('imonth is outside the range of valid months')
end
%
d = size(iday);
if (length(d) ~= 2 | max(d) ~= 1 | min(d) ~= 1)
   error('iday must be a [1 x 1] integer')
end
if (abs(iday - round(iday)) ~= 0)
   error('iday must be a [1 x 1] integer')
end
if (iday < 1 | iday > 31)
   error('iday is outside the range of valid days')
end
%
d = size(ihour10);
if (length(d) ~= 2 | max(d) ~= 1 | min(d) ~= 1)
   error('ihour10 must be a [1 x 1] integer')
end
if (abs(ihour10 - round(ihour10)) ~= 0)
   error('ihour10 must be a [1 x 1] integer')
end
if (ihour10 < 0 | ihour10 > 240)
   error('ihour10 is outside the range of valid hours*10')
end


% Convert year/month/day to MATLAB date number and back
dnum = datenum(iyear,imonth,iday);
[year,month,day,hour,minute,second] = datevec(dnum);
junk = max( [abs(year - iyear), abs(month - imonth), abs(day - iday)] );
if (junk > 0.0001)
   error('invalid date (maybe a non-existant day of month?)')
end


% Determine which of the 9 ECMWF models is nearest
modnum = floor( (ihour10 + 14.0001)/30 ) + 1;


if (modnum == 9)
   % Next day
   [year,month,day,hour,minute,second] = datevec(dnum + 1);
end


% Convert date numbers to strings
ystr = int2str(year);
if (month < 10)
   mstr = ['0' int2str(month)];
else
   mstr = int2str(month);
end
if (day < 10)
   dstr = ['0' int2str(day)];
else
   dstr = int2str(day);
end


if (modnum == 1 | modnum == 9)
   name = ['UAD' mstr dstr '0000' mstr dstr '00001'];
end
if (modnum == 2)
   name = ['UAD' mstr dstr '0000' mstr dstr '03001'];
end
if (modnum == 3)
   name = ['UAD' mstr dstr '0600' mstr dstr '06001'];
end
if (modnum == 4)
   name = ['UAD' mstr dstr '0000' mstr dstr '09001'];
end
if (modnum == 5)
   name = ['UAD' mstr dstr '1200' mstr dstr '12001'];
end
if (modnum == 6)
   name = ['UAD' mstr dstr '1200' mstr dstr '15001'];
end
if (modnum == 7)
   name = ['UAD' mstr dstr '1800' mstr dstr '18001'];
end
if (modnum == 8)
   name = ['UAD' mstr dstr '1200' mstr dstr '21001'];
end

%%% end of function %%%
