function [shiftedx,shiftedy,smoothedy]=smooth1aa(x,y,m);

%% copied from /carrot/s1/strow/Tobin_home/Mfiles
%% copied from /home/sergio/MATLABCODE/SMOOTH/smooth1a.m

% declare m before invoking this - smoothing range
% I try to normalize in y=, but with a small number
% of points this isn't good enough, so divide by sum(y)

global iDoPlot

[mx,mn] = size(x);
[nx,nn] = size(y);

if (mx ~= 1)
  x = x';
  [mx,mn] = size(x);
  end

%thediff = sum(size(x)-size(y));
%if thediff ~= 0
%  error('x and y seem to be different sizes! smooth1aa error!');
%  end

if (mn ~= nn)
  error('oops might need to transpose y!!!!')
  end

i = -m:m;
gauss = exp(-i.*i/(2*m));
gauss = gauss/sum(gauss);
nn = length(x);
for jj = 1 : nx
  z = conv(y(jj,1:nn),gauss);
  smoothedy(jj,:) = z(2*m+1:nn);
  shiftedy(jj,:)  = y(jj,m+1:nn-m);   
  shiftedx        = x(m+1:nn-m);
  end

%iDoPlot = -1;
if iDoPlot > 0
  plot(x,y,shiftedx,smoothedy,'r'); pause(0.1)
  end
