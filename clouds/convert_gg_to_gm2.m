function [cngwat_sarta] = convert_gg_to_gm2(cT,cB,cngwat_ecmwf,rlevs,tlevs) 

%% changes the [cT,cB,cngwat_ecmwf,rlevs,tlevs] from ECMWF (in kg/kg) to g/m2
%% where cT,cB         = level number for cloud tops, cloud bottoms
%%        cngwat_ecmwf = cumulative cloud amt in ECMWF units (kg/kg)
%%        rlevs,tlevs  = pressure levels and level temps from ECMWF
%%        cngwat_sarta = cumulative cloud amt in SARTA units (g/m2)
%%        
%% see /asl/packages/klayersV204/Doc/mr_from_amount.txt
%% Values of important constants: 
%%   Loschmidt = 2.6867775E+19 molecules per cm^3 (at 1 atm and 273.15 K)
%%   kAvogadro = 6.022142E+26 molecules per kilomole
%%   T0 = 273.15 K
%% In the following discussion, all profile values are layer average values.  
%% For a homogeneous air path, the relationship between column density
%% and mixing ratio is:
%%    CD_i = PP_i/kAvogadro * dz *  T0/T * Loschmidt    where
%%      PP_i = MR_i * Ptotal 
%%      CD_i is the column density of gas "i" (kilomoles/cm^2)
%%      PP_i is the partial pressure of gas "i" (atm)
%%      dz is the pathlength (cm)
%%      T is the gas temperature (K)
%%      MR_i is the volume mixing ratio of gas "i" expressed as the
%%        number of gas "i" molecules per total number of molecules
%%        making up the air.
%%      Ptotal is the total air pressure (atm)

%% according to me, 
%%    CD_i = PP_i/P0 * dz *  T0/T * Loschmidt / kAvogadro 
%% proof : Po Vo = No k To  where Po, Vo, To = STP values
%%         Lo = loschmidt number = No/Vo = Po/(kTo) = 2.6867775E+19 mols/cm^3
%% also at level z, pV = N k T = n NN k T        N  = number of molecules
%%                                               NN = Avogadro number
%%                                               n  = number of moles
%%             thus  p(Adz) = n/1000 1000NA k T 
%%                   p(Adz) = n'     NN'    k T  n' = kilomoles
%%                                               NN'= kiloAvogadro
%%             thus n'/A = kilomoles/cm2 =  p dz/(NN' k T)
%% but Po Vo = No k To 
%%     p  V  = No k T  ==> 1/(kT) = No/(pV) = Lo Vo / (pV) = Lo/p Vo/V
%% Using Po Vo / To = p V / T we have  =  Vo/V = pTo/(PoT)

%% Thus 1   = Lo p To
%      ---    -------
%      kT      p Po T

%% which means n'     p dz     p dz  Lo p To    p   Lo  To  dz
%%             -- = ------- =  ---- --------  = -- ---- --
%%             A    NN' k T     NN' p  Po  T    Po  NN' T

%% Looking at /asl/packages/klayersV204/Src/toppmv.f
%% C               PPMV = MRgg*(MDAIR/MASSF)*1E+6      MDAIR=28.966 g/mol
%%                                                     MASSF=18     g/mol

Loschmidt = 2.6867775E+19; %molecules per cm^3 (at 1 atm and 273.15 K)
kAvogadro = 6.022142E+26;  %molecules per kilomole
T0 = 273.15;
P0 = 1013.5;

load airslevels.dat

MDAIR = 28.966; % g/mol
MASSF = 18;     % g/mol for both water and ice!

for ii = 1 : length(cT)

  %% WRONG as this is INTEGRATED amount
  %% mr = cngwat_ecmwf(ii);   

  %% CORRECT  : need to go back to "mr per layer"
  mr = cngwat_ecmwf(ii)/(cB(ii)-cT(ii)+1);

  tnew = interp1(log(rlevs),tlevs,log(airslevels),'spline','extrap');
  jjT = find(airslevels <= rlevs(cT(ii))); jjT = min(jjT);
  jjB = find(airslevels >= rlevs(cB(ii))); jjB = max(jjB);
  jj = [jjB : jjT];

  pB = rlevs(cB(ii));
  pT = rlevs(cT(ii));
  
  clear g_m2new sum_g_m2new
  g_m2new = 0;
  sum_g_m2new = 0.0;
  iDoSum = -1;
  if iDoSum > 0
    for jjind = 1 : length(jj)
      pB = airslevels(jj(jjind));
      pT = airslevels(jj(jjind)+1);
      pnew = (pB-pT)/log(pB/pT);

      tB = tnew(jj(jjind));
      tT = tnew(jj(jjind)+1);
      slope = (tB-tT)/(log(pB)-log(pT));
      Tnew = tB - slope*(log(pB)-log(pnew));

      hB = p2h(pB);
      hT = p2h(pT);
      dz = (hT - hB)*100;

      ppmv = mr * (MDAIR/MASSF)*1E+6;
      pp = ppmv/1e6 * pnew;  %%% use volume mix ratio rather than ppmv
      num_kmoles_percm2 = pp/P0 * Loschmidt/kAvogadro * T0/Tnew * dz;
      %%kilomoles -> moles, cm2 -> m2
      g_m2new(jjind) = num_kmoles_percm2*1000*MASSF*10000;  
      end
    end
  sum_g_m2new = sum(g_m2new);

  pB = rlevs(cB(ii));
  pT = rlevs(cT(ii));
  pold  = pB - (pB-pT)/2;
  pnew = (pB-pT)/log(pB/pT);
  [pT pB pold pnew];

  tB = tlevs(cB(ii));
  tT = tlevs(cT(ii));
  Told  = tB - (tB-tT)/2;
  slope = (tB-tT)/(log(pB)-log(pT));
  Tnew = tB - slope*(log(pB)-log(pnew));
  [tT tB Told Tnew];

  hB = p2h(pB);
  hT = p2h(pT);
  dz = (hT - hB)*100;

  ppmv = mr * (MDAIR/MASSF)*1E+6;
  pp = ppmv/1e6 * pold;  %%% use volume mix ratio rather than ppmv
  num_kmoles_percm2 = pp/P0 * Loschmidt/kAvogadro * T0/Told * dz;
  g_m2old = num_kmoles_percm2*1000*MASSF*10000; %%kilomoles -> moles, cm2 -> m2

  ppmv = mr * (MDAIR/MASSF)*1E+6;
  pp = ppmv/1e6 * pnew;  %%% use volume mix ratio rather than ppmv
  num_kmoles_percm2 = pp/P0 * Loschmidt/kAvogadro * T0/Tnew * dz;
  g_m2new = num_kmoles_percm2*1000*MASSF*10000; %%kilomoles -> moles, cm2 -> m2

  g_m2 = g_m2new;
  cngwat_sarta(ii) = g_m2;

  %format short e
  %[mr g_m2 g_m2new sum_g_m2new]
  %format 
  end
