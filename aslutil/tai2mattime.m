function dateout = tai2mattime(datein)
%function dateout = tai2mattime(datein)
%  Airs to matlab time conversion
% See also:  iasi2mattime, mattime2tai, mattime2iasi


dateout = datenum(1993,1,1,0,0,double(datein));
