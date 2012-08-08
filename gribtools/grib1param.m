function lbl = grib2param(ctr,tbl,parm)
%function lbl = grib2param(dis,cat,parm)
%
%  Return the proper label for grib2 fields
%

% Written 14 June 2011 - Paul Schou

persistent d c p l
if isempty(d)
  [c t p l]=textread('grib1table.txt','%n%n%n%s%*[^\n]');
end

i = (ctr == c & tbl == t & parm == p);
if any(i)
  lbl = l{i};
else
  lbl = sprintf('%d,%d,%d',ctr,tbl,parm);
end
