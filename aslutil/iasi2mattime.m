function dateout = iasi2mattime(datein)
% Convert a iasi time to a matlab datenum
%
% See also:  tai2mattime, mattime2tai, mattime2iasi

dateout = datenum(2000,1,1,0,0,double(datein));
