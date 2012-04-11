function [cN,cOUT,cT,cB,cPeak] = combine_clouds2t1(iN,iOUT,iT,iB,iPeak,plevs)

% this takes in ICE  parameters iN,iOUT,iT,iB,iPeak,plevs
% checks it ; if there are iN = 2, then it combines the two clouds to make
%   one cloud for [cN,cOUT,cT,cB,cPeak]
% where 
%   I/O
%       xN == number of clouds of type X (integer)
%    xPeak == max value of cloud(s) of type X
%    plevs == pressure levels
%       xT == top of clouds     (integer)
%       xB == bottom of clouds  (integer)
%     xOUT == box profile of cloud typ X (real)

% input can have upto 2 cloud, output is limited to total 1 cloud

global iDoPlot

%% two ice clouds!, set to 1!!
cN = 1;

%% combine the clouds

iPeak = [iPeak(1)     iPeak(2)];
xPeak = [iB(1)-iT(1)+1 iB(2)-iT(2)+1];
iPeak = iPeak.*xPeak;

%%cloud top and bot are weighted avgs
cT = iPeak(1)*iT(1)/(iPeak(1)+iPeak(2)) + iPeak(2)*iT(2)/(iPeak(1)+iPeak(2));
  cT = floor(cT);
cB = iPeak(1)*iB(1)/(iPeak(1)+iPeak(2)) + iPeak(2)*iB(2)/(iPeak(1)+iPeak(2));
  cB = ceil(cB);
cPeak = sum(iPeak)/(cB(1)-cT(1)+1);
cOUT = zeros(size(iOUT));
cOUT(cT:cB) = cPeak;

if iDoPlot > 0
  figure(3); clf
  plot(iOUT,plevs,cOUT,plevs,'r'); 
  title('2 clds in (B) 1 cld out (R)');
  set(gca,'ydir','reverse');
  pause
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
