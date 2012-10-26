function [yOUT,wT,wB,peakN,N,maxN,minN] = boxshape(yIN,rGaussianCutoff);

%% this takes in function y and returns a boxy approx "yOUT" to it, as well
%% as number of maxima, number of minima, location of max/min, index of 
%% boxy approx
%% input      yIN   vector containing function
%%     rGaussianCutOff = 0.250;   %% done for ages, till July 2012; might put cloud too high/wide
%%     rGaussianCutOff = 0.375;   %% done after July 2012, trying to put cloud little lower/thin
                                  %% and therefore closer to maxpart of cloud

%% output    yOUT   vector containing box approx
%%             wT   left  edge of box shapes
%%             wB   right edge of box shapes
%%          peakN   maxima of the box shapes

%%              N   number of maxima found
%%           maxN   posns of maxima
%%           minN   posns of minima

%% works best if everything is positive and is really designed for the 
%% ECMWF cloud --> RTP file

%% warning .. always make sure the cloud bottom (N) and cloud top (N+1)
%%            are separate
%%  if wT(jj) <= wB(jj-1)
%%    wT(jj) = wB(jj-1) + 1;
%%    end

global iDoPlot

%% example 
iExample = -1;
if iExample > 0
  dx = 2*pi/101;
  x = 0 : dx : 2*pi;
  y1 = x * 0.5;

  y = 2*ones(size(x));  %% this has no peak
  y = sin(0.5*x);         %% this has one peak
  y = (sin((0.35*x).^2)).^2; y = y.*x/10;  %% has 2 peaks
  y = (sin((0.35*x).^2)).^2; ;             %% has 2 peaks
  y = sin(x).^2;                %% has two peaks
  y = sin(x).^2; y = y.*x/10;   %% has two peaks
  y = sin(x).^2 + y1;           %% has two peaks

  y = (sin((0.5*x).^2)).^2; y = y.*x/10;         %% has 3 peaks
  y = (sin((0.5*x).^2)).^2; y = y.*x/10 + y1;    %% has 2 peaks
  y = (sin((0.5*x).^2)).^2; y = y.*x/10 + y1/2;  %% has 2 peaks

  y = (sin((0.55*x).^2)).^2; y = y.*x/10;         %% has 4 peaks
  y = (sin((0.55*x).^2)).^2; y = y.*x/10 + y1/3;  %% has 4 peaks
  yIN = y;

  plot(x,yIN)
  end

clear wT wB
peakN = [0 0 0];

if iDoPlot > 0
  clf; 
  plot(yIN); grid
  end

[maxN,minN] = localmaxmin(yIN);

%% get rid of edge effects
maxN0 = maxN;
minN0 = minN;

if maxN(1) == 1
  maxN(1) = 0;
  end
if maxN(length(maxN)) == 1
  maxN(length(maxN)) = 0;
  end
if minN(1) == 1
  minN(1) = 0;
  end
if minN(length(minN)) == 1
  minN(length(minN)) = 0;
  end

sumYmax = sum(maxN);
sumYmin = sum(minN);

yOUT = zeros(1,length(yIN)); 
zdiff = diff(yIN); zsum = sum(zdiff); zsumabs = sum(abs(zdiff));

iFound = -1;

if (zsum == zsumabs & zsum == 0)
  %% there are no max or min, so this is constant function!
  sumYmax = 0;
  N     = 0;
  wT    = [];
  wB    = [];
  peakN = [0];
  yOUT = ones(1,length(yIN)) * yIN(1); 
  iFound = +1;
  end

if sumYmax >= 6 & iFound < 0
  disp(' simplifying more than 5 maxima')
  if iDoPlot > 0
    plot(1:length(yIN),yIN); grid
    end
  end

if sumYmax == 1 
  N = 1;
  yOUT = zeros(1,length(yIN));

  %%% make sure you get half width on one side then the other side
  iM   = find(maxN == 1);
  haha = find(yIN <= rGaussianCutoff*yIN(iM));
  hahaT = haha(find(haha < iM)); wT = max(hahaT);  %pT = plevs(wT);
  hahaB = haha(find(haha > iM)); wB = min(hahaB);  %pB = plevs(wB);
    if length(wB) == 0
      wB = length(yIN);
      end
  peakN(1) = sum(yIN)/(wB-wT+1);
  yOUT(wT:wB) = yOUT(wT:wB) + peakN(1);
  iFound = +1;
  end

if sumYmax == 2
  N = 2;
  yOUT = zeros(1,length(yIN));

  iM = find(maxN == 1);

  %%% make sure you get the one minima in between the two maxima
  iO = find(minN == 1);
  if length(iO) > 1
    iX = find(iO > iM(1) & iO < iM(2));
    iO = iO(iX);
    end

  jj = 1;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj));               
    hahaT = haha(hahaT);
    wT(1) = max(hahaT);
  hahaB = find(haha > iM(jj) & haha <= iO);  
    if (length(hahaB) > 0)
      hahaB = haha(hahaB);
      wB(1) = min(hahaB);
    else
      wB(1) = iO;
      end
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 2;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO);  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(2) = max(hahaT);
    else
      wT(2) = iO;
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(2)  = length(yIN);
    else
      wB(2) = min(hahaB);
      end
  %wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);
  iFound = +1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if sumYmax == 3
  N = 3;
  yOUT = zeros(1,length(yIN));

  iM = find(maxN == 1);

  %%% make sure you get the two minima in between three maxima
  iO = find(minN == 1);
  if length(iO) > 2
    for jj = 1 : 2
      iX      = find(iO > iM(jj) & iO < iM(jj+1));
      iOO(jj) = iO(iX);
      end
    iO = iOO;
    end

  jj = 1;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj));               
    hahaT = haha(hahaT);
    wT(1) = max(hahaT);
  hahaB = find(haha > iM(jj) & haha <= iO(1));  
    if (length(hahaB) > 0)
      hahaB = haha(hahaB);
      wB(1) = min(hahaB);
    else
      wB(1) = iO(1);
      end
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 2;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(1));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(2) = max(hahaT);
    else
      wT(2) = iO(1);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(2) = length(yIN);
    else
      wB(2) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 3;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(2));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(3) = max(hahaT);
    else
      wT(3) = iO(2);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(3) = length(yIN);
    else
      wB(3) = min(hahaB);
      end
  %wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);
  iFound = +1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if sumYmax == 4
  N = 4;
  yOUT = zeros(1,length(yIN));

  iM = find(maxN == 1);

  %%% make sure you get the three minima in between four maxima
  iO = find(minN == 1);
  if length(iO) > 3
    for jj = 1 : 3
      iX      = find(iO > iM(jj) & iO < iM(jj+1));
      iOO(jj) = iO(iX);
      end
    iO = iOO;
    end

  jj = 1;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj));               
    hahaT = haha(hahaT);
    wT(1) = max(hahaT);
  hahaB = find(haha > iM(jj) & haha <= iO(1));  
    if (length(hahaB) > 0)
      hahaB = haha(hahaB);
      wB(1) = min(hahaB);
    else
      wB(1) = iO(1);
      end
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 2;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(1));
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(2) = max(hahaT);
    else
      wT(2) = iO(1);
      end
  hahaB = find(haha > iM(jj));
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(2) = length(yIN);
    else
      wB(2) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 3;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iO(2) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(3) = max(hahaT);
    else
      wT(3) = iO(2);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(3) = length(yIN);
    else
      wB(3) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 4;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(4) = max(hahaT);
    else
      wT(4) = iO(3);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(4) = length(yIN);
    else
      wB(4) = min(hahaB);
      end
  %wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);
  iFound = +1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sumYmax == 5
  disp('oh oh  .. too lazy to handle 5 maxima properly -- reset to 4')
  N = 4;
  yOUT = zeros(1,length(yIN));

  iM = find(maxN == 1);
  iN = find(minN == 1);
  tM = yIN(iM);

  [Y,I] = sort(tM);
  get_rid_of = I(1);     %%get rid of smallest

  maxN(iM(get_rid_of)) = 0;
  if (length(iN) >= get_rid_of)
    minN(iN(get_rid_of)) = 0;
    end

  iM = find(maxN == 1);
  iN = find(minN == 1);

  %%% make sure you get the three minima in between four maxima
  iO = find(minN == 1);
  if length(iO) > 3
    for jj = 1 : 3
      iX      = find(iO > iM(jj) & iO < iM(jj+1));
      iOO(jj) = iO(iX);
      end
    iO = iOO;
    end

  jj = 1;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj));               
    hahaT = haha(hahaT);
    wT(1) = max(hahaT);
  hahaB = find(haha > iM(jj) & haha <= iO(1));  
    if (length(hahaB) > 0)
      hahaB = haha(hahaB);
      wB(1) = min(hahaB);
    else
      wB(1) = iO(1);
      end
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 2;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(1));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(2) = max(hahaT);
    else
      wT(2) = iO(1);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(2) = length(yIN);
    else
      wB(2) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 3;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iO(2) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(3) = max(hahaT);
    else
      wT(3) = iO(2);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(3) = length(yIN);
    else
      wB(3) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 4;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(4) = max(hahaT);
    else
      wT(4) = iO(3);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(4) = length(yIN);
    else
      wB(4) = min(hahaB);
      end
  %wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);
  iFound = +1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sumYmax >= 6
  disp('oh oh  .. too lazy to handle >= 6 maxima properly -- reset to 4')
  N = 4;
  yOUT = zeros(1,length(yIN));

  iM = find(maxN == 1);
  iN = find(minN == 1);
  tM = yIN(iM);

  [Y,I] = sort(tM);
  maxnum = sumYmax - 4;
  get_rid_of = I(1:maxnum);     %%get rid of smallest

  for kk = 1 : length(get_rid_of)
    maxN(iM(get_rid_of(kk))) = 0;
    if (length(iN) >= get_rid_of(kk))
      minN(iN(get_rid_of(kk))) = 0;
      end
    end

  iM = find(maxN == 1);
  iN = find(minN == 1);

  %%% make sure you get the three minima in between four maxima
  iO = find(minN == 1);
  if length(iO) > 3
    for jj = 1 : 3
      iX      = find(iO > iM(jj) & iO < iM(jj+1));
      iOO(jj) = iO(iX);
      end
    iO = iOO;
    end

  jj = 1;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj));               
    hahaT = haha(hahaT);
    wT(1) = max(hahaT);
  hahaB = find(haha > iM(jj) & haha <= iO(1));  
    if (length(hahaB) > 0)
      hahaB = haha(hahaB);
      wB(1) = min(hahaB);
    else
      wB(1) = iO(1);
      end
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 2;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(1));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(2) = max(hahaT);
    else
      wT(2) = iO(1);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(2) = length(yIN);
    else
      wB(2) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 3;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iO(2) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(3) = max(hahaT);
    else
      wT(3) = iO(2);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(3) = length(yIN);
    else
      wB(3) = min(hahaB);
      end
  wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);

  jj = 4;
  haha = find(yIN <= rGaussianCutoff*yIN(iM(jj)));
  hahaT = find(haha < iM(jj) & haha >= iO(3));  
    if (length(hahaT) > 0)  
      hahaT = haha(hahaT);
      wT(4) = max(hahaT);
    else
      wT(4) = iO(3);
      end
  hahaB = find(haha > iM(jj));               
    hahaB = haha(hahaB);
    if length(hahaB) == 0
      wB(4) = length(yIN);
    else
      wB(4) = min(hahaB);
      end
  %wB(jj) = min(iO(jj),wB(jj));
  peakN(jj) = sum(yIN(wT(jj):wB(jj)))/(wB(jj)-wT(jj)+1);
  if wT(jj) <= wB(jj-1)
    wT(jj) = wB(jj-1) + 1;
    end
  yOUT(wT(jj):wB(jj)) = yOUT(wT(jj):wB(jj)) + peakN(jj);
  iFound = +1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iFound < 0

  %% sumYmax < 5 but nothing found .... 
  %% because we looked at maxN instead of maxN0
  %% probably means foggy cloud at ground! that was "turned off" by looking at
  %% maxN instead of maxN0

  if (sum(maxN0) == 1)
    %% aha .. yes there is a maximum at the ground!!!!!!!
    %%        as this is much more likely than maximum at TOA !!!!
    %% however, there is the odd profile where the ciwc or clwc field
    %% is of the form (A 0 0 0 0 0 0 0 ... 0) ie cld at TOA
    N = 1;
    yOUT = zeros(1,length(yIN));
    %%% make sure you get half width on one side then the other side
    iM   = find(maxN0 == 1);
    haha = find(yIN <= rGaussianCutoff*yIN(iM));
    hahaT = haha(find(haha < iM)); wT = max(hahaT);  %pT = plevs(wT);
    hahaB = haha(find(haha > iM)); wB = min(hahaB);  %pB = plevs(wB);
    if length(wB) == 0
      %%% account for cld at BOTTOM ie gnd
      wB = length(yIN);
      end
    if length(wT) == 0
      %%% account for cld at TOP ie toa
      wT = 1;
      end
    peakN(1) = sum(yIN)/(wB-wT+1);
    yOUT(wT:wB) = peakN(1);
    iFound = +1;

  elseif (sum(maxN0) == 0)
    %% odd mebbe we have something like [0 0 0 0 0   ... 0.25 0.50 1.00 1.00];
    mx = max(yIN);
    mn = min(yIN);
    yOUT = zeros(1,length(yIN));
    if mx > 0
      N = 1;
      wB = length(yIN);
      wT = find(yIN <= rGaussianCutoff*mx);
      wT = max(wT);
      peakN(1) = sum(yIN)/(wB-wT+1);
      yOUT(wT:wB) = peakN(1);
      iFound = +1;
      end

  elseif (sum(maxN0) == 2)
    %% odd mebbe we have something like [0 0 0 0 0   ... 0.0 1.00];
    mx = max(yIN);
    mn = min(yIN);
    yOUT = zeros(1,length(yIN));
    if mx > 0
      N = 1;
      wB = length(yIN);
      wT = find(yIN <= rGaussianCutoff*mx);
      wT = max(wT);
      peakN(1) = sum(yIN)/(wB-wT+1);
      yOUT(wT:wB) = peakN(1);
      iFound = +1;
      end
    end
  end

peakN = peakN(1:N);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% now make sure everythign is unique; else combine clouds 
%%% for example if we have two clouds 
%%%    iT = [50 70], iB = [60 80] and iPeak = [1e-2 3e-2]
%%%    then we expect yOUT(50:60) = 1e-2 and yOUT(70:80) = 3e-2
%%% for example if we have three clouds
%%%    iT = [53 77 84], iB = [68 87 87], iPeak = [0.46    0.42    0.34]
%%%    we expect yOUT(53:68) = 0.46 yOUT(77:87) = 0.42 yOUT(84:87) = 0.34
%%%    but we find yOUT(74:87) = 0.42+0.34 = 0.76
%%%    so we KNOW there is an error!!! also the iB were not unique!

yCHECK = zeros(size(yOUT));
for kk = 1 : N
  ind = wT(kk) : wB(kk);
  yCHECK(ind) = peakN(kk);
  end
thediff = abs(yCHECK - yOUT);
if (sum(thediff) > 0)
  disp('sum(thediff) > 0')
  wT
  wB
  if iDoPlot > 0
    h1 = subplot(211);
    plot(1:length(yIN),yIN,1:length(yIN),yOUT,'r',1:length(yIN),yCHECK,'m'); 
    grid
    title('in (b), out (r), check (m)');
    h2 = subplot(212);
    plot(1:length(yIN),yOUT - yCHECK,'m'); grid; title('check mismatch');
    pause;
    end

  disp('oops found some overlap inconsistency!!!!')
  [wTunique,wIT,wJT] = unique(wT,'first');
  [wBunique,wIB,wJB] = unique(wB,'first');

  if length(wB) ~= length(wBunique)
    disp('inconsistency in cld bottoms');
    [wBunique,wIB1,wJB1] = unique(wB,'first');
    [wBunique,wIB2,wJB2] = unique(wB,'last');
    Ccombine  = setxor(wIB1,wIB2);    %% combine these!!!!!!
    Cseparate = intersect(wIB1,wIB2); %% these are unique
    for mm = 1 : length(Cseparate)
      wTnew(mm) = wT(Cseparate(mm));
      wBnew(mm) = wB(Cseparate(mm));
      wPeaknew(mm) = peakN(Cseparate(mm));
      end
    for mm = 1 : length(Ccombine)/2
      mmm = [1 2] + (mm-1)*2;
      len = length(wTnew);
      len = len + 1;
      wTnew(len) = min(wT(Ccombine(mmm)));
      wBnew(len) = max(wB(Ccombine(mmm)));
      wPeaknew(len) = sum(peakN(Ccombine(mmm)));
      end
    end

  if length(wT) ~= length(wTunique)
    disp('inconsistency in cld tops');
    [wBunique,wIB1,wJB1] = unique(wT,'first');
    [wBunique,wIB2,wJB2] = unique(wT,'last');
    Ccombine  = setxor(wIB1,wIB2);    %% combine these!!!!!!
    Cseparate = intersect(wIB1,wIB2); %% these are unique
    for mm = 1 : length(Cseparate)
      wTnew(mm) = wT(Cseparate(mm));
      wBnew(mm) = wB(Cseparate(mm));
      wPeaknew(mm) = peakN(Cseparate(mm));
      end
    for mm = 1 : length(Ccombine)/2
      mmm = [1 2] + (mm-1)*2;
      len = length(wTnew);
      len = len + 1;
      wTnew(len) = min(wT(Ccombine(mmm)));
      wBnew(len) = max(wB(Ccombine(mmm)));
      wPeaknew(len) = sum(peakN(Ccombine(mmm)));
      end
    end

  N = N - length(Ccombine)/2;
  yNEW = zeros(size(yOUT));
  for kk = 1 : N
    ind = wTnew(kk) : wBnew(kk);
    yNEW(ind) = wPeaknew(kk);
    end
  if iDoPlot > 0
    clf
    plot(1:length(yIN),[yIN; yOUT; yCHECK; yNEW]); title('check new');
    pause(0.1);
    end

  wT = wTnew;
  wB = wBnew;
  yOUT = yNEW;
  peakN = wPeaknew;
  end   

if iDoPlot > 0
  plot(1:length(yIN),yIN,1:length(yIN),yOUT,'r'); grid
  end
