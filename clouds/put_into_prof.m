% When two clouds are present, the meaning of cfrac1 and cfrac2
% are the total fraction of the FOV containing that cloud in
% any combination.  Along with cfrac12, these three fields are
% used to calcuate the following additional cloud fractions:
%   Fraction cloud1 exclusively = cfrac1 - cfrac12
%   Fraction cloud2 exclusively = cfrac2 - cfrac12
%   Fraction clear = 1.0 + cfrac12 - cfrac1 - cfrac2
% Note that we must have cfrac12 <= min(cfrac1,cfrac2)
% and individually cfrac1,cfrac2,cfrac12 must all be <= 1.0.

%%%%% same as put_into_pnew except we have pnew --> prof, p --> profX
%%%%%
%%%%% set cloud emissivities to 0
%%%%%
%%%%% use cfrac = profX.cfrac(ii) for cfrac1,cfrac2,cfrac12 instead of 1
%%%%% then totalCfrac = cfrac1 + cfrac2 - cfrac12 = cfrac
%%%%%   so eg if cfrac = 1.00, then totalCfrac = 1.00, and totalCclear = 0.00
%%%%%   so eg if cfrac = 0.25, then totalCfrac = 0.25, and totalCclear = 0.75

%% set these are effective particle radii .... eventually may make 
%% ice particle sizes vary with cloud top
ice_dme   = 60;
water_dme = 15;

cfrac = profX.cfrac(ii);

prof.plat(jj) = profX.plat(ii);
prof.plon(jj) = profX.plon(ii);
prof.cemis(jj)   = 0;
prof.udef(18,jj) = 0.0;

%%%%%%%%%%

if length(cTYPE) < 1
  %% NO CLDS

  prof.cngwat(jj) = 0.0;
  prof.cpsize(jj) = 0.0;
  prof.cprtop(jj) = 0.0;
  prof.cprbot(jj) = 0.0;
  prof.cfrac(jj)  = 0.0;  %%cfrac1
  prof.ctype(jj)  = -1;   %%ctype

  prof.udef(11,jj) = 0.0;
  prof.udef(12,jj) = 0.0;
  prof.udef(13,jj) = 0.0;
  prof.udef(14,jj) = 0.0;
  prof.udef(15,jj) = 0.0; %%cfrac2
  prof.udef(17,jj) = -1;  %%ctype

  prof.udef(16,jj) = 0.0;  %%cfrac12

  end

%%%%%%%%%%

if length(cTYPE) == 1
  %% ONE CLOUD

  icefound   = -1;
  waterfound = -1;
  %cc = convert_gg_to_gm2(cT,cB,cngwat,profX.plevs(:,ii),profX.ptemp(:,ii));
  cc = convert_gg_to_gm2(cT,cB,cngwat,plevs,ptemp);

  kk = 1;

  prof.cngwat(jj)  = cc(kk);
  if iLevsVers == 1
    prof.cprtop(jj)  = profX.plevs(cT(kk),ii);
    prof.cprbot(jj)  = profX.plevs(cB(kk),ii);
  elseif iLevsVers == 2
    prof.cprtop(jj)  = plevs(cT(kk));
    prof.cprbot(jj)  = plevs(cB(kk));
  end
  prof.cfrac(jj)   = cfrac;
  if cTYPE(kk) == 'I'
    prof.ctype(jj)  = 201;
    prof.cpsize(jj) = ice_dme;   %% typical ice particles
    icefound        = +1;
  elseif cTYPE(kk) == 'W'
    prof.ctype(jj)  = 101;
    prof.cpsize(jj) = water_dme;  %% typical water particles
    waterfound      = +1;
    end

  prof.udef(11,jj) = 0.0;
  prof.udef(12,jj) = 0.0;
  prof.udef(13,jj) = 0.0;
  prof.udef(14,jj) = 0.0;
  prof.udef(15,jj) = 0.0; %%cfrac2
  prof.udef(17,jj) = -1;  %%ctype

  prof.udef(16,jj) = 0.0;  %%cfrac12
  %prof.udef(16,jj) = min(prof.cfrac(jj),prof.udef(15,jj));  %%cfrac12

  end

%%%%%%%%%%

if length(cTYPE) == 2
  %% TWO CLOUDS

  icefound   = -1;
  waterfound = -1;
  %cc = convert_gg_to_gm2(cT,cB,cngwat,profX.plevs(:,ii),profX.ptemp(:,ii));
  cc = convert_gg_to_gm2(cT,cB,cngwat,plevs,ptemp);

  kk = 1;
  prof.cngwat(jj)  = cc(kk);
  if iLevsVers == 1
    prof.cprtop(jj)  = profX.plevs(cT(kk),ii);
    prof.cprbot(jj)  = profX.plevs(cB(kk),ii);
  elseif iLevsVers == 2
    prof.cprtop(jj)  = plevs(cT(kk));
    prof.cprbot(jj)  = plevs(cB(kk));
  end
  prof.cfrac(jj)   = cfrac;
  if cTYPE(kk) == 'I'
    prof.ctype(jj)  = 201;
    prof.cpsize(jj) = ice_dme;   %% typical ice particles
    icefound      = +1;
  elseif cTYPE(kk) == 'W'
    prof.ctype(jj) = 101;
    prof.cpsize(jj) = water_dme;  %% typical water particles
    waterfound      = +1;
    end

  kk = 2;
  prof.udef(11,jj)  = cc(kk);
  if iLevsVers == 1
    prof.udef(13,jj)  = profX.plevs(cT(kk),ii);
    prof.udef(14,jj)  = profX.plevs(cB(kk),ii);
  elseif iLevsVers == 2
    prof.udef(13,jj)  = plevs(cT(kk));
    prof.udef(14,jj)  = plevs(cB(kk));
  end
  prof.udef(15,jj) = cfrac; %%cfrac2
  if cTYPE(kk) == 'I'
    prof.udef(17,jj) = 201;
    prof.udef(12,jj) = ice_dme;   %% typical ice particles
    icefound         = +1;
  elseif cTYPE(kk) == 'W'
    prof.udef(17,jj) = 101;
    prof.udef(12,jj) = water_dme;  %% typical water particles
    waterfound       = +1;
    end

  prof.udef(16,jj) = 0.9999*cfrac;  %%cfrac12
  if prof.cfrac(jj) < 0.9999
    prof.udef(16,jj) = 0.9999*min(prof.cfrac(jj),prof.udef(15,jj));  %%cfrac12
  else  
    prof.udef(16,jj) = min(prof.cfrac(jj),prof.udef(15,jj));
    end
  end
