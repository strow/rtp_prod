function lbl = grib2param(dis,cat,parm)
%function lbl = grib2param(dis,cat,parm)
%
%  Return the proper label for grib2 fields
%

% Written 14 June 2011 - Paul Schou

persistent d c p l
if isempty(d)
  [d c p l]=textread('grib2table.txt','%n%n%n%s%*[^\n]');
end

if isstr(dis)
  if length(dis) < 10
    lbl = dis;
    return;
  end
  t=regexp(dis,'var discipline=(\d+) master_table=(\d+) parmcat=(\d+) parm=(\d+)','tokens');
  dis = str2num(t{1}{1});
  cat = str2num(t{1}{3});
  parm = str2num(t{1}{4});
end

i = (dis == d & cat == c & parm == p);
if any(i)
  lbl = l{i};
else
  lbl = sprintf('%d,%d,%d',dis,cat,parm);
end
