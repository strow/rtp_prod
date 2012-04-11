%% called by readecmwf91_grid/nearest_gasNcloud.m
%%     "nlev" is set by readecmwf91_grid/nearest_gasNcloud
%%
%%%%%%%%%%%%%% will fail if iN or iW >= 6 at the smoothing  %%%%%%%%%%%%%%%%
%% first smooth plevs (P) , ice cloud profile (I) , water cloud profile (W)
%%   using iSmooth = 2
%% if num(maxN) = 5 or 6 after smoothing, boxshape dumps lowest M maxima
%%   so that there are 4 maxima at most
%% then take smoothed profiles and make them into boxshapes (N <= 4)
%% smooth 4 to 3 : if iN > 3 combines 4 clouds to 3
%%               : if iW > 3 combines 4 clouds to 3
%% smooth 3 to 2 : if iN > 2 combines 3 clouds to 2
%%               : if iW > 2 combines 3 clouds to 2
%% if we have total iN + iW > 2 then smooth 2 ice   clouds to 1
%%                                   smooth 2 water clouds to 1
%% finally combine the ice and water clouds
%%%%%%%%%%%%%% will fail if iN or iW >= 6 at the smoothing  %%%%%%%%%%%%%%%%
%% once it has changed the cloud profile into slabs, it calls "put_into_prof"
%% in that routine, the effective particle radii are preset .... eventually 
%% may make ice particle sizes vary with cloud top
%% ice_dme   = 60;
%% water_dme = 15;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nlev > 20
  iSmooth = 2;
else
  iSmooth = 1;
  end

global iDoPlot
iDoPlot = +1;   %% plot stuff .. ugh slow
iDoPlot = -1;   %% do not plot stuff

iPrint = +1;    %% do     print chirpy talky comments
iPrint = -1;    %% do not print chirpy talky comments

tic;

iStep = 1;
jj = 0;
iiii = 1 : iStep : length(profX.plat);
%iiii = ix(1:10);
for iiiiA = 1:length(iiii)
  ii = iiii(iiiiA);
  jj = jj + 1;

  iSmoothX = iSmooth;
  blahW = profX.clwc(:,ii)/(max(profX.clwc(:,ii))+1e-16);
  blahI = profX.ciwc(:,ii)/(max(profX.ciwc(:,ii))+1e-16);
  numI = length(find(blahI > 0.25*blahI));
  numW = length(find(blahW > 0.25*blahW));
  iDo = -1;
  if nlev > 20
    if numI > 5 & numW > 5
      iSmoothX = iSmooth;
      iDo = +1;
    elseif numW > 5 & numI == 0
      iSmoothX = iSmooth;
      iDo = +1;
    elseif numI > 5 & numW == 0
      iSmoothX = iSmooth;
      iDo = +1;
    else
      iSmoothX = 0.5;
      iSmoothX = 2;
    end
  end

  if iDo > 0
    % lots of points
    [shiftedx,shiftedy,plevs]    = smooth1aa(1:nlev,profX.plevs(:,ii)',iSmoothX);
    [shiftedx,shiftedy,watercld] = smooth1aa(1:nlev,profX.clwc(:,ii)' ,iSmoothX);
    [shiftedx,shiftedy,icecld]   = smooth1aa(1:nlev,profX.ciwc(:,ii)' ,iSmoothX);

    %npoly = 1;    nframe = 3;
    %[sgplevs]    = sgolayfilt(double(profX.plevs(:,ii)') ,npoly,nframe);
    %[sgwatercld] = sgolayfilt(double(profX.clwc(:,ii)')  ,npoly,nframe);
    %[sgicecld]   = sgolayfilt(double(profX.ciwc(:,ii)')  ,npoly,nframe);
  else
    % few points
    plevs    = profX.plevs(:,ii);
    watercld = profX.clwc(:,ii);
    icecld   = profX.ciwc(:,ii);
  end

  [wOUT,wT,wB,wPeak,wN,wmaxN,wminN] = boxshape(watercld); newwater = wOUT;
  [iOUT,iT,iB,iPeak,iN,imaxN,iminN] = boxshape(icecld);   newice   = iOUT;

  if iPrint > 0
    poink = [ii wN iN wPeak iPeak];
    %fprintf(1,'%5i %3i %3i | %8.6e %8.6e %8.6e | %8.6e %8.6e %8.6e \n',poink);
    fprintf(1,'%5i %3i %3i | %8.6e \n',poink);
  elseif iPrint < 0 & mod(jj,1000) == 0
    tnow = toc;
    fprintf(1,' processed %5i in %8.6f minutes\n',ii,tnow/60);
    end

  if iN > 3
    [iN,iOUT,iT,iB,iPeak] = combine_clouds4t3(iN,iOUT,iT,iB,iPeak,plevs);
    end
  if wN > 3
    [wN,wOUT,wT,wB,wPeak] = combine_clouds4t3(wN,wOUT,wT,wB,wPeak,plevs);
    end

  if iN > 2
    [iN,iOUT,iT,iB,iPeak] = combine_clouds3t2(iN,iOUT,iT,iB,iPeak,plevs);
    end
  if wN > 2
    [wN,wOUT,wT,wB,wPeak] = combine_clouds3t2(wN,wOUT,wT,wB,wPeak,plevs);
    end

  if ((iN == 1 & wN == 2) | (iN == 2 & wN == 1) | (iN == 2 & wN == 2))
    if iN == 2
      [iN,iOUT,iT,iB,iPeak] = combine_clouds2t1(iN,iOUT,iT,iB,iPeak,plevs);
      end
    if wN == 2
      [wN,wOUT,wT,wB,wPeak] = combine_clouds2t1(wN,wOUT,wT,wB,wPeak,plevs);  
      end
    end

  [cT,cB,cOUT,cngwat,cTYPE,iFound] = combine_clouds(...
              iN,iOUT,iT,iB,iPeak,wN,wOUT,wT,wB,wPeak,plevs,profX.plevs(:,ii));

  %%%%%% put_into_pnew; nah!!!!!!
  %error('lkjalkjfa')
  put_into_prof;

  if iPrint > 0
    fprintf(1,' \n');
    if (length(cTYPE) >= 1)
      disp('type    toplev   botlev    cngwat*1000 kg/kg     cngwat g/m2');
      disp('-------------------------------------------------------------');
      for kk = 1 : length(cTYPE)
        if cTYPE(kk) == 'I'
          fprintf(1,'  I      %3i       %3i         %8.6f         %8.6f \n',cT(kk),cB(kk),cngwat(kk)*1000,cc(kk))
      else
          fprintf(1,'  W      %3i       %3i         %8.6f         %8.6f \n',cT(kk),cB(kk),cngwat(kk)*1000,cc(kk))
          end
        end
      disp('-------------------------------------------------------------');
    else
      fprintf(1,' no cld found \n');
      end
    fprintf(1,' \n');
    end

  if iDoPlot > 0
    figure(1);  clf
    plot(profX.ciwc(:,ii),profX.plevs(:,ii),'b',...
        icecld,plevs,'b--',newice,plevs,'bo-',...
        profX.clwc(:,ii),profX.plevs(:,ii),'r',watercld,plevs,'r--',...
                                      newwater,plevs,'ro-'); hold on
    plot(profX.ciwc(:,ii),profX.plevs(:,ii),'b',...
         profX.clwc(:,ii),profX.plevs(:,ii),'r',...
         cOUT,profX.plevs(:,ii),'k','LineWidth',3 )
    set(gca,'ydir','Reverse'); 
    grid
    hold off
    legend('Ice','SmoothIce','NewIce','Water','SmoothWater','NewWater',...
         'Location','NorthEast')
    pause(0.1);
    end
  end

