function [cN,cOUT,cT,cB,cPeak] = combine_clouds3t2(iN,iOUT,iT,iB,iPeak,plevs)

% this takes in ICE  parameters iN,iOUT,iT,iB,iPeak,plevs
% checks it ; if there are iN = 4, then it combines the four clouds to make
%   three clouds for [cN,cOUT,cT,cB,cPeak]
% where 
%   I/O
%       xN == number of clouds of type X (integer)
%    xPeak == max value of cloud(s) of type X
%    plevs == pressure levels
%       xT == top of clouds     (integer)
%       xB == bottom of clouds  (integer)
%     xOUT == box profile of cloud typ X (real)

% input can have upto 4 cloud, output is limited to total 3 clouds

global iDoPlot

if iN <= 3
  cN = iN;
  cOUT = iOUT;
  cT = iT;
  cB = iB;
  cPeak = iPeak;
  end

if iN == 4
  %% four ice clouds!, set to 3!!
  cN = 3;

  %% combine the two closest clouds
  diff12 = abs(p2h(plevs(iB(1))) - p2h(plevs(iT(2))));
  diff23 = abs(p2h(plevs(iB(2))) - p2h(plevs(iT(3))));
  diff34 = abs(p2h(plevs(iB(3))) - p2h(plevs(iT(4))));

  if ((diff12 <= diff23) & (diff12 <= diff34))
    %% clouds 1 and 2 are close
    cT = [iT(1) iT(3) iT(4)];
    cB = [iB(2) iB(3) iB(4)];

    %% better estimate for cT(1) and cB(1)
    cT(1) = iPeak(1)*iT(1)/(iPeak(1)+iPeak(2)) + ...
            iPeak(2)*iT(2)/(iPeak(1)+iPeak(2));
    cT(1) = floor(cT(1));
    cB(1) = iPeak(1)*iB(1)/(iPeak(1)+iPeak(2)) + ...
            iPeak(2)*iB(2)/(iPeak(1)+iPeak(2));
    cB(1) = ceil(cB(1));

    cngwat = [iPeak(1)+iPeak(2) iPeak(3)       iPeak(4)];
    xPeak = [cB(1)-cT(1)+1      cB(2)-cT(2)+1  cB(3)-cT(3)+1];
    cPeak = cngwat;
    cngwat = cngwat.*xPeak;
    cOUT  = zeros(size(iOUT));
    cOUT(cT(1):cB(1)) = cPeak(1);
    cOUT(cT(2):cB(2)) = cPeak(2);
    cOUT(cT(3):cB(3)) = cPeak(3);

  elseif  ((diff23 <= diff12) & (diff23 <= diff34))
    %%clouds 2 and 3 are close
    cT = [iT(1) iT(2) iT(4)];
    cB = [iB(1) iB(3) iB(4)];

    %% better estimate for cT(2) and cB(2)
    cT(2) = iPeak(2)*iT(2)/(iPeak(2)+iPeak(3)) + ...
            iPeak(3)*iT(3)/(iPeak(2)+iPeak(3));
    cT(2) = floor(cT(2));
    cB(2) = iPeak(2)*iB(2)/(iPeak(2)+iPeak(3)) + ...
            iPeak(3)*iB(3)/(iPeak(2)+iPeak(3));
    cB(2) = ceil(cB(2));

    cngwat = [iPeak(1)     iPeak(2)+iPeak(3) iPeak(4)];
    xPeak = [cB(1)-cT(1)+1 cB(2)-cT(2)+1     cB(3)-cT(3)+1];
    cPeak = cngwat;
    cngwat = cngwat.*xPeak;
    cOUT  = zeros(size(iOUT));
    cOUT(cT(1):cB(1)) = cPeak(1);
    cOUT(cT(2):cB(2)) = cPeak(2);
    cOUT(cT(3):cB(3)) = cPeak(3);

  elseif  ((diff34 <= diff12) & (diff34 <= diff12))
    %%clouds 3 and 4 are close
    cT = [iT(1) iT(2) iT(3)];
    cB = [iB(1) iB(2) iB(4)];

    %% better estimate for cT(3) and cB(4)
    cT(3) = iPeak(3)*iT(3)/(iPeak(3)+iPeak(4)) + ...
            iPeak(4)*iT(4)/(iPeak(3)+iPeak(4));
    cT(3) = floor(cT(3));
    cB(3) = iPeak(3)*iB(3)/(iPeak(3)+iPeak(4)) + ...
            iPeak(4)*iB(4)/(iPeak(3)+iPeak(4));
    cB(3) = ceil(cB(3));

    cngwat = [iPeak(1)     iPeak(2)          iPeak(3)+iPeak(4)];
    xPeak = [cB(1)-cT(1)+1 cB(2)-cT(2)+1     cB(3)-cT(3)+1];
    cPeak = cngwat;
    cngwat = cngwat.*xPeak;
    cOUT  = zeros(size(iOUT));
    cOUT(cT(1):cB(1)) = cPeak(1);
    cOUT(cT(2):cB(2)) = cPeak(2);
    cOUT(cT(3):cB(3)) = cPeak(3);

    end
  end

if iDoPlot > 0
  figure(3); clf
  plot(iOUT,plevs,cOUT,plevs,'r'); 
  title('4 clds in (B) 3 cld out (R)');
  set(gca,'ydir','reverse');
  pause
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
