function [cT,cB,cOUT,cngwat,cTYPE,iFound] = combine_clouds(...
              iN,iOUT,iT,iB,iPeak,wN,wOUT,wT,wB,wPeak,plevs,rlevs)

% this takes in ICE  parameters iN,iOUT,iT,iB,iPeak
%          and WATER parameters wN,wOUT,wT,wB,wPeak
% and combines it for [cT,cB,cOUT,cngwat,cTYPE,iFound] 
% where 
%   input
%       xN == number of clouds of type X (integer)
%    xPeak == max value of cloud(s) of type X
%    plevs == "smoothed" pressure levels (56,87 levs after 2 pt smoothing)
%    rlevs == "raw"      pressure levels (60,91 levs)
%   I/O
%       xT == top of clouds     (integer)
%       xB == bottom of clouds  (integer)
%     xOUT == box profile of cloud typ X (real)
%
%   output
%    cTYPE == 0 for no cloud, +1 for water, +2 for ice
%   iFound == WXYZ  = 0000 for no clds, 
%                     20 for one ice cld, 22 for two ice clds
%                     223Z for 3 ice clouds combined to 2 (way 1,way 2)
%                     10 for one water cld, 11 for two water clds
%                     113Z for 3 water clouds combined to 2 (way 1,way 2)
%   cngwat == integrated total cloud amount per cloud type

% input can have upto 2 clouds per type, output is limited to total 2 clouds

iFound = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iN == 0 & wN == 0
  %% no clouds!
  cT    = [];
  cB    = [];
  cngwat = [0 0];
  cOUT  = zeros(size(iOUT));
  cTYPE = [0 0];
  cTYPE = [ ];
  iFound = 0;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ICE CLDS
if iN == 1 & wN == 0
  %% one ice cloud!
  cT    = iT;
  cB    = iB;
  cngwat = iPeak*((cB-cT)+1);
  cOUT  = iOUT;
  cTYPE = [2];
  cTYPE = ['I'];
  iFound = 20;
  end

if iN == 2 & wN == 0
  %% two ice clouds!
  cT    = iT;
  cB    = iB;
  cngwat = [iPeak(1) iPeak(2)];
  xPeak = [((cB(1)-cT(1))+1) ((cB(2)-cT(2))+1)];
  cngwat = cngwat.*xPeak;
  cTYPE = [2 2];
  cTYPE = ['II'];
  iFound = 22;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% WATER CLDS
if iN == 0 & wN == 1
  %% one water cloud!
  cT    = wT;
  cB    = wB;
  cngwat = wPeak*((cB-cT)+1);
  cTYPE = [1];
  cTYPE = ['W'];
  iFound = 10;
  end

if iN == 0 & wN == 2
  %% two water clouds!
  cT    = wT;
  cB    = wB;
  cngwat = [wPeak(1) wPeak(2)];
  xPeak = [((cB(1)-cT(1))+1) ((cB(2)-cT(2))+1)];
  cngwat = cngwat.*xPeak;
  cTYPE = [1 1];
  cTYPE = ['WW'];
  iFound = 11;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ICE and WATER CLDS
if iN == 1 & wN == 1
  %% one ice and one water cloud!
  icol = iPeak*((iB-iT)+1);
  wcol = wPeak*((wB-wT)+1);
  if ((wcol < 1e-6) & (icol/wcol > 2))
    %%ice is much stronger than water
    cT    = iT;
    cB    = iB;
    cngwat = iPeak*((cB-cT)+1);
    cTYPE = [2];
    cTYPE = ['I'];
    iFound = 112;
  elseif ((icol < 1e-6) & (wcol/icol > 2))
    %%water is much stronger than ice
    cT    = wT;
    cB    = wB;
    cngwat = wPeak*((cB-cT)+1);
    cTYPE = [1];
    cTYPE = ['W'];
    iFound = 111;
  else
    %%combine them, make sure they do not overlap
    ice_extent   = iB : -1 : iT;
    water_extent = wB : -1 : wT;
    [C,iAA,iBB] = intersect(ice_extent,water_extent);
    if length(C) < 1
      %%no overlap ... 
      cT = [iT wT];
      cB = [iB wB];
      cngwat = [iPeak*((iB-iT)+1) wPeak*((wB-wT)+1)];
      cTYPE = [2 1];
      cTYPE = ['IW'];
      iFound = 1100;
    else
      %%overlap; put stuff into ice and then water
      xx = floor((max(wB,iB) + min(wT,iT))/2);
      cT = [min(wT,iT)          xx];
      cB = [xx          max(wB,iB)];
      if (wT < iT)
        %%water on top of ice wow!
        cngwat = [wPeak*((wB-wT)+1) iPeak*((iB-iT)+1)];     
        cTYPE = [1 2];
        cTYPE = ['WI'];
        iFound = 1121;
      else
        %%water on top of ice wow!
        cngwat = [iPeak*((iB-iT)+1) wPeak*((wB-wT)+1)];     
        cTYPE = [2 1];
        cTYPE = ['IW'];
        iFound = 1112;
        end
      end
    end
  end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iFound < 0
  error('oops did not set final cloud types!!');
  end

%%%%%% make cOUT

cOUT = zeros(size(rlevs));
for ii = 1 : length(cT)
  xT = cT(ii);
  xB = cB(ii);
  xPeak = cngwat(ii)/(xB(1)-xT(1)+1);
  pT = plevs(xT); jj = find(rlevs <= pT); xT = jj(length(jj)); 
  pB = plevs(xB); jj = find(rlevs >= pB); xB = jj(1);
  cOUT(xT:xB) = xPeak;
  end
