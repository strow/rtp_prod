function [dat long] = mapshift(indata, inlong, beglon)
%function [dat long] = mapshift(indata, inlong, beglon)
%
% A simple function to shift the world map, if beglon is not given it does a simple
%   right to left and left to right shift.
%
% Inputs:
%   indata = data in grid format (ie: 720x361)
%   inlong = longitude values [optional]
%   beglon = point on which to begin longitude values (ie: 0 or 180 deg latitude) [optional]
%
% Outputs:
%   dat  = shifted map
%   long = modified longitude values
%
% See also:  wrapTo360, wrapTo180

% Written by Paul Schou (5 Aug 2009)

if nargin > 1
  if size(indata,1) ~= numel(inlong)
    error('mapshift requires longitude to be on the first dimension');
  end
end

if nargin == 2
  long = [reshape(inlong(end/2+1:end),1,[]) reshape(inlong(1:end/2),1,[])];
  beglon = mod(long(1),360);
  long = mod(long-beglon,360)+beglon;
  if size(inlong,2) == 1
    long = long';
  end
end

if nargin < 3
  dat = [indata(:,end/2+1:end,:),indata(:,1:end/2,:)];
else
  long = mod(inlong-beglon,360)+beglon;
  [long key] = sort(long);
   %find(mod(inlong,360) >= mod(beglon,360),1);
  dat = indata(key,:);
end

end
