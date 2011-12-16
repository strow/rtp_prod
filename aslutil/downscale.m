%function dat = downscale(dat,scale)
%   where scale is [xn yn]
%
% Downscale a map data by a factor of yn and xn
%
% Example:
%   size(dat)
%     [360   180]
%   size(downscale(dat,[10 10]))
%     [36    18 ]
% 

% Written by Paul Schou - 23 Feb 2010
function dat = downscale(dat,scale)

if(length(scale) == 2)
  yn = scale(1); xn = scale(2);
elseif(length(scale) == 1)
  yn = scale; xn = 1;
else
  error('This version does not support more than 2 dims');
end

if mod(size(dat,1)/yn,1) ~= 0
  error('Error: rows are not divisible by yn');
end
if mod(size(dat,2)/xn,1) ~= 0
  error('Error: cols are not divisible by xn');
end

sx = size(dat,2);
sy = size(dat,1);
sz = size(dat);

% mean together on the y dimension
dat = nanmean(reshape(dat,[yn sy/yn sx sz(3:end)]),1);
% mean together on the x dimension
dat = nanmean(reshape(dat,[sy/yn xn sx/xn sz(3:end)]),2);

% clean up the final dimension
dat = reshape(dat,[sy/yn sx/xn sz(3:end)]);
