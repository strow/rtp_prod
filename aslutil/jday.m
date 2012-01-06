%function jd = jday(mday)
% Returns the Julian day for given matlab day

% Written by Paul Schou
function jd = jday(mday)

if nargin == 0; jd = jday(now); return; end
dv = datevec(mday);
jd = floor(mday - datenum([dv(1) 0 0]));
