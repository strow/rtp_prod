function [h0 ha px pxa] = driver_gentemann_dsst(h0,ha,p0,pa);
% function [h0 ha px pxa] = driver_gentemann_dsst(h0,ha,p0,pa);

%% copied from add_chelle_dsst.m in /home/sergio/MATLABCODE/DIURNAL_SST/POSH/subroutines/Unix_SUBR
%% will be put on my local git version of rtp_prod, under diurnal_sst
%% input 
%%   h0,ha,p0,pa  are the usual inputs from reading a rtp file
%% output
%%   p0 --> px where only stemp field is changed px.stemp = px.stemp + dsst, only over water


px = p0;

iaOcean = find(p0.landfrac <= 0.001);
if length(iaOcean) > 0
  [raY,raM,raD,raH] = tai2utc(p0.rtime);
  raJD = (raM-1)*30 + raD;
  [raLT,raJD1] = local_time(raH,raJD,p0.rlon);

  raY  = double(raY);
  raLT = double(raLT);
  raaJD1 = double(raJD1);
  raLon  = double(p0.rlon);
  raLat  = double(p0.rlat);
  raWSPD = double(p0.wspeed);

  %% this is a mex file
  dsst = zeros(size(p0.stemp));
  xdsst = get_diurnal_sst_sergioD(raY(iaOcean),raJD1(iaOcean),...
                           raLT(iaOcean),raLat(iaOcean),raLon(iaOcean),...
                           raWSPD(iaOcean));   
  dsst(iaOcean) = xdsst;

  %% find changes after adding dsst
  px.stemp(iaOcean) = px.stemp(iaOcean) + dsst(iaOcean);

  pxa = set_attr(pa,'sst','gentemann_dsst');


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  iPlot = -1;
  if iPlot > 0
    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,raH(iaOcean))
    title('raH'); disp('ret to continue'); pause

    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,raLT(iaOcean))
    title('raLT'); disp('ret to continue'); pause

    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,raWSPD(iaOcean))
    title('raWSPD'); disp('ret to continue'); pause

    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,raY(iaOcean))
    title('raY'); disp('ret to continue'); pause

    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,raJD1(iaOcean))
    title('raJD'); disp('ret to continue'); pause

    scatter(px.rlon(iaOcean),px.rlat(iaOcean),20,dsst(iaOcean))
    title('dsst');
  end

end
