function [head,hattr,prof,pattr,s,isubset] = iasi_uniform_clear(head, hattr, prof, pattr);
% function [head,hattr,prof,pattr,s,isubset] = iasi_uniform_clear(head, hattr, prof, pattr);
%
%   Apply a clear algorithm top the provided IASI RTP structure. 
%   Based on iasi_uniform_and_allfov_func.m
%
% Output:
%    head     - [structure] RTP header structure
%    hattr    - [cell strings] RTP header attribute strings
%    prof_out - [structure] RTP profiles structure
%    pattr    - [cell strings] - RTP profiles attribute strings
%    s        - [structure] summary structure with info on all FOVs
%    isubset  - [vector] list of subset fovs
%
% Breno Imbiriba - 2012.08.03


  rn='iasi_uniform_clear';
  greetings(rn);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1. Setup 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 2. Compute Clear flags
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

  % Imager Test
  imageunflag = iasi_imager_test(prof);



  % Mark FoVs close to "fixed sites"
  sitenum = set_fixed_sites(prof.rlat, prof.rlon, range_km); %not really used

  % 
  hicloudflag = iasi_high_clouds(prof); % Not really used


  coastflag = set_coast(prof);


  [spectunflag spectunflagL] =  iasi_spectral_uniform(coastflag, imageunflag);

  avhrr_clear = iasi_avhrr_clear(coastflag);


end




function imageunflag = iasi_imager_test(prof)

  % imager_uniform arguments
  drnoise = 2;		% imager delta R noise (1.0)
  dbtmaxall = 7;	% max delta BT for entire FOV uniformity test(8.0)
  nminall = 4055; % of 4096 - min # of imager pixels within dbtmaxall+noise (4075)
  stdmaxall = 1.7; 	% max std dev of entire imager pixels
  dbtmaxsub = 2;	% max delta BT for sub FOV uniformity test (3.0)
  nminsub = 1587; % of 1600 - min # of imager pixels within dbtmaxsub+noise (1588)
  stdmaxsub = 0.5;	% max std dev of subset imager pixels

  % imager_uniform2 arguments for Land
  dbtmaxallL = 14;
  nminallL = 1568; % of 1600
  stdmaxallL = 3.4;
  dbtmaxsubL = 4;
  nminsubL =  217; % of 221
  stdmaxsubL = 1;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Test #5: Imager uniformity
  % -- Test depends on Imager data. Can be called from anywhere
  % -- but it makes sense to call it from the reader

  % This routine was writen to use IASI data in the 2x2 FoR format, 
  % hence we reformat the relevant structures to this shape:

  % Make a list of FoRs (which is 4-times repeated) 
  xFoR = [prof.atrack' prof.xtrack'];

  % Select 
  [~, ifor] = unique(xFoR,'rows');

  % Imager: We need only one image per FoR:
  % Uncompress Image from "calflag"
  [IASI_Image Im_Lat Im_Lon] = uncompress_imager(prof.calflag);

  IASI_Image_for = IASI_Image(:,ifor)';


  % Test of 64x64 (all) and corner 40x40 (sub) imager pixels
  [imageunflag, btall, btsub, nall, nsub, stdall, stdsub] = imager_uniform(...
     IASI_Image_for, drnoise, dbtmaxall, dbtmaxsub, nminall, nminsub, ...
     stdmaxall, stdmaxsub);

  % uflag  = [n x 4] uniform flag (0=not, 1=uniform)
  % btall  = [n x 1] mean BT of all imager pixels
  % btsub  = [n x 4] mean BT of subset imager pixels
  % nall   = [n x 1] number of imager pixels within dbtmaxall+noise of mean
  % nsub   = [n x 4] number of imager pixels within dbtmaxsub+noise of mean
  % stdall = [n x 1] std dev of entire IASI Imager
  % stdsub = [n x 4] std dev of subset IASI Imager

  % Test of central 40 x 40 (all) and circular (sub) imager pixels
  [imageunflagL, btallL, btsubL, nallL, nsubL, stdallL, stdsubL] = ...
     imager_uniform2( IASI_Image_for, drnoise, dbtmaxallL, dbtmaxsubL, ...
     nminallL, nminsubL, stdmaxallL, stdmaxsubL);

  % uflag  = [n x 4] uniform flag (0=not, 1=uniform)
  % btall  = [n x 1] mean BT of all imager pixels
  % btsub  = [n x 4] mean BT of subset imager pixels
  % nall   = [n x 1] number of imager pixels within dbtmaxall+noise of mean
  % nsub   = [n x 4] number of imager pixels within dbtmaxsub+noise of mean
  % stdall = [n x 1] std dev of all fovs IASI Imager
  % stdsub = [n x 4] std dev of each fov IASI Imager


  % Replace Land results that are actually over land:
  % If all four fovs are over land, replace by over-land calculations
 
  % Make a over-land logical array - same 1st dimention as xFoR
  lland = (prof.landfrac>.99)';
  llandall = zeros(size(lland));
  llandany = zeros(size(lland));

  % For each FoR, see if all FoVs are over land
  for iatrack = unique(prof.atrack)
    for ixtrack = unique(prof.xtrack)
      iFoR = find(prof.xtrack == ixtrack & prof.atrack == iatrack);
      llandall(iFoR) = all(lland(iFoR));
      llandany(iFoR) = any(lland(iFoR));
      nFoRcnt(iFoR) = numel(iFoR); 
    end
  end

  % If llandcnt is not 4 means that we have missing FoR data 
  % either this is NOT an allfovs RTP structure or there's missing
  % data.
  if(any(nFoRcnt~=4))
    disp('Some 2x2 FoVs are missing - or this is not an AllFovs RTP structure.');
  end


  ii = find(lland);
  iiall = find(llandall == 1);
  if (length(ii) > 0)

     % Update standard variables for land
     imageunflag(ii) = imageunflagL(ii);
     % FoV 
     btsub(ii) = btsubL(ii);
     nsub(ii) = nsubL(ii);
     stdsub(ii) = stdsubL(ii);
     % FoR
     btall(iiall) = btallL(iiall);
     nall(iiall) = nallL(iiall);
     stdall(iiall) = stdallL(iiall);
  end

end
     


function coastflag = set_coast(prof)
  %%%%%%%%%%%%%%%%%%
  % Test #3: Coastal
  % Minimum landfrac for land; max landfrac for sea
  minlandfrac_land = 0.99;
  maxlandfrac_sea = 0.01;


  nprof = numel(prof.rtime);

  coastflag = uint8(zeros(nprof));
  icoast = find( prof.landfrac > maxlandfrac_sea & ...
		 prof.landfrac < minlandfrac_land );
  if (length(icoast) > 0)
     coastflag(icoast) = 1;
  end
end


function sitenum = set_fixed_sites(rlat, rlon, range_km)

% Fixed site range (in km)
  range_km = 55.5;


  [sind, snum] = fixedsite(rlat1d(itest), rlon1d(itest), range_km);
      isiteind = itest( sind );
      siteflag(isiteind) = 1;
      sitenum(isiteind) = snum;
   
end



function hicloudflag = iasi_high_clouds(btsubL, rlat, nsubL, stdsubL)

  % high cloud max BT and std dev and |latitude|
  btmaxhicloud = 220;
  %no longer used: stdmaxhicloud = 2;
  latmaxhicloud = 60;


  %%%%%%%%%%%%%%%%%%%%%%
  % Test #6: high clouds
  %
  % Check BT and latitude
  %ihicloud = find(btsub <= btmaxhicloud & stdsub <= stdmaxhicloud & ...
  %   abs(rlat) < latmaxhicloud);
  ihicloud = find(btsubL <= btmaxhicloud & ...
     abs(rlat) < latmaxhicloud);
  hicloudflag(ihicloud) = 1;
  %
  if (length(ihicloud) > 0)
     % Update sub variables for hicloud
     btsub(ihicloud) = btsubL(ihicloud);
     nsub(ihicloud) = nsubL(ihicloud);
     stdsub(ihicloud) = stdsubL(ihicloud);
  end
  %
  % Apply quality flag to hicloudflag
  hicloudflag(ibadq) = 0;

end

function [spectunflag spectunflagL] =  iasi_spectral_uniform()

  % spectral_uniform757 arguments
  dbtmax757u  = [2, 1];
  dbtmax820u  = [2, 1];
  dbtmax960u  = [2, 1];
  dbtmax1231u = [2, 1];
  dbtmax2140u = [3, 2];

  % spectral_uniform757 arguments for Land
  dbtmax757uL  = [3, 0.5];
  dbtmax820uL  = [4, 1.5];
  dbtmax960uL  = [4, 1.5];
  dbtmax1231uL = [4, 1.5];
  dbtmax2140uL = [5, 3];

  % spectral_clear arguments
  % note: modsst from ECMWF

  %%% Nominal
  %dbtqmin = 0.3;
  %dbt820max = 3;
  %dbt960max = 2;
  %dbtsstmax = 5;
  %%% 20% tighter than nominal
  dbtqmin = 0.36;
  dbt820max = 2.4;
  dbt960max = 1.6;
  dbtsstmax = 5.0;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Test #7: spectral uniformity 
  % -- These depend on the IASI 2x2 FoV structure
  % -- Must be called from the reader
  % 
  % For clear testing set all pixels bad if any are coastal
  junk = max(coastflag')'; % [nax x 1];
  iax = find(junk == 1);
  if (length(iax) > 0)
     for jj=1:npixfov
	ibad = iax + (npixfov-1)*nax;
	badflag(ibad) = 1;
     end
  end
  ibad = find(badflag == 1);
  %
  [spectunflag, dbt757u, dbt820u, dbt960u, dbt1231u, dbt2140u] = ...
  spectral_uniform757(data.IASI_Radiances, imageunflag, dbtmax757u, ...
     dbtmax820u, dbtmax960u, dbtmax1231u, dbtmax2140u);
  %
  % Do land spectral uniformity test
  % Note: assumes ii is still land index from Test5b
  if (length(ii) > 0)
     [spectunflagL, dbt757u, dbt820u, dbt960u, dbt1231u, dbt2140u] = ...
     spectral_uniform757(data.IASI_Radiances, imageunflag, dbtmax757uL, ...
	dbtmax820uL, dbtmax960uL, dbtmax1231uL, dbtmax2140uL);
     spectunflag(ii) = spectunflagL(ii);
  end
  %
  % Apply quality & coast flag to spectunflag
  spectunflag(ibad) = 0;
  %
  %disp(['DELETE_ME: # of spectun=' int2str(length(find(spectunflag==1)))])

end

function clearflag = iasi_spectral_clear()

  %%%%%%%%%%%%%%%%%%%%%%%%%
  % Test #8: spectral clear
  % -- These depend on the IASI 2x2 FoV structure
  % -- Must be called from the reader
  %
   [clearflag, retsst, dbtq, dbt820, dbt960, dbtsst] = spectral_clear( ...
     data.IASI_Radiances, data.Satellite_Zenith, lsea, modsst, ...
     spectunflag, dbtqmin, dbt820max, dbt960max, dbtsstmax);

end


function avhrr_clear = iasi_avhrr_clear()

  % Max allowed AVHRR cloud fraction
  max_cfrac_avhrr = 0.02;

  % AVHRR-only clear random subsetting fraction
  avhrronly_clearocean_fraction = 0.1; % Keep 10% of the FOVs
  avhrronly_clearland_fraction = 0.3; % Keep 30% of the FOVs


  %%%%%%%%%%%%%%%%%%%%%%
  % Test #9: AVHRR clear
  %disp('DELETE_ME: starting Test#9')
  %
  % Check Avhrr1B CldFrac & Qual
  if (isfield(data,'Avhrr1BCldFrac') & isfield(data,'Avhrr1BQual'))
     iavhrr = find(data.Avhrr1BCldFrac <= max_cfrac_avhrr & ...
	data.Avhrr1BQual == 0 & qualflag == 0 & coastflag == 0);
     avhrrflag(iavhrr) = 1;
     use_avhrr = 1;
     %
     % AVHRR-only clear land random sub-sample
     ii = iavhrr( find(clearflag(iavhrr) == 0 & landfrac(iavhrr) == 1 & ...
	abs(rlat(iavhrr)) <= 70) );
     jj = length(ii);
     iavhrr_land1 = ii( find(rand(jj,1) < avhrronly_clearland_fraction) );
     % AVHRR-only hi latitude clear land reduced random sub-sample
     ii = iavhrr( find(clearflag(iavhrr) == 0 & landfrac(iavhrr) == 1 & ...
	abs(rlat(iavhrr)) > 70) );
     jj = length(ii);
     iavhrr_land2 = ii( find(rand(jj,1) < avhrronly_clearland_fraction/5) );
     iavhrr_land = union(iavhrr_land1, iavhrr_land2);
     %
     % AVHRR-only clear ocean random sub-sample
     ii = iavhrr( find(clearflag(iavhrr) == 0 & landfrac(iavhrr) == 0) );
     jj = length(ii);
     iavhrr_ocean = ii( find(rand(jj,1) < avhrronly_clearocean_fraction) );
     %
     iavhrr_keep = union(iavhrr_land,iavhrr_ocean);
     use_avhrr = 1;
  else
     iavhrr = [];
     use_avhrr = 0;
  end
  %disp(['DELETE_ME: # of AVHRR clear=' int2str(length(iavhrr))])
end




    modsst   = reshape(p.stemp,[],npixfov);
    modcld   = reshape(p.cfrac,[],npixfov);
    modseaice= reshape(p.udef(1,:),[],npixfov);
    % Force sea ice to values 0-1 and NaN
    ibadseaice = find(modseaice < 0 | modseaice > 1);
    modseaice(ibadseaice) = NaN;

%
%
%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Get landfrac/topography info
%    %
%    ibad = find( p.qualflag == 1 );
%    rlat(ibad) = 0;
%    rlat1d(ibad) = 0;
%    rlon1d(ibad) = 0;
%    %
%    [salti, junk] = usgs_deg10_dem(rlat1d, rlon1d);
%    %
%    landfrac = reshape(junk, nax,npixfov);
%    lsea = zeros(nax,npixfov);
%    ii = find( landfrac < maxlandfrac_sea );
%    lsea(ii) = 1;
%    lland = zeros(nax,npixfov);
%    ii = find( landfrac > minlandfrac_land );
%    lland(ii) = 1;
%    llandall = max(lland,[],2); % [nax,1]
%    %
%    %disp(['DELETE_ME: # of lsea=' int2str(length(find(lsea==1)))])
%    %
%    %%% uncomment this block for a plot of land, sea, & coast
%    %iland=find(landfrac > minlandfrac_land);
%    %isea=find(landfrac < maxlandfrac_sea);
%    %icoast=find(landfrac > maxlandfrac_sea & landfrac < minlandfrac_land);
%    %landfrac1d=reshape(landfrac,1,nobs);
%    %plot(rlon1d(isea),rlat1d(isea),'b*',rlon1d(iland),rlat1d(iland),'g*', ...
%    %   rlon1d(icoast),rlat1d(icoast),'k*')
%%    %pause(1)
%    %clear iland isea icoast landfrac1d
%%    %%%


   %
    %disp(['DELETE_ME: # of random=' int2str(length(find(randomflag==1)))])







    % Determine indices to keep and note reason(s)
    irandom = find(randomflag == 1);
    nclear = length(irandom);
    %
    isite = find(siteflag == 1);
    nsite = length(isite);
    %
    ihicloud = find(hicloudflag == 1);
    nhicloud = length(ihicloud);
    %
    iclear = find(clearflag == 1);
    nclear = length(iclear);
    %
    % reason code numbers (bit flags):
    %    1=IASI clear
    %    2=calibration site
    %    4=high clouds
    %    8=randomly selected
    %   16=AVHRR clear
    %
    reason = zeros(nax,npixfov);
    reason(iclear) = 1;
    reason(isite) = reason(isite) + 2;
    reason(ihicloud) = reason(ihicloud) + 4;
    reason(irandom) = reason(irandom) + 8;
    reason(iavhrr) = reason(iavhrr) + 16;
    %
    ikeep = union(irandom, isite);
    ikeep = union(ikeep, ihicloud);
    ikeep = union(ikeep, iclear);
    if (use_avhrr == 1)
       ikeep = union(ikeep, iavhrr_keep); 
    end

    % this section will override the clear uniform reader to do allfov returns
    isubset = ikeep;
    if isequal(allfov, 1)
      ikeep = 1:nobs;
    end

    nkeep = length(ikeep);
    nkeep_total = nkeep_total + nkeep;
    %
    say(['  nkeep=' int2str(nkeep)])


    % Write summary file
    if exist('nsubL','var') & length(nsubL) > 0
      rlon = data.Longitude;
      en = st + length(qualflag) -1;
      s.findex(st:en,:) = ic;
      s.qualflag(st:en,:) = qualflag;
      s.GQisFlagQual(st:en,:) = GQisFlagQual;
      s.coastflag(st:en,:) = coastflag;
      s.reason(st:en,:) = reason;
      s.clearflag(st:en,:) = clearflag;
      s.siteflag(st:en,:) = siteflag;
      s.hicloudflag(st:en,:) = hicloudflag;
      s.randomflag(st:en,:) = randomflag;
      s.avhrrflag(st:en,:) = avhrrflag;
      s.imageunflag(st:en,:) = imageunflag;
      s.spectunflag(st:en,:) = spectunflag;
      junk = uint8(round(100*modseaice)); junk(ibadseaice) = 255;
      %disp(['length of bad modseaice100 = ' int2str(length(ibadseaice))])
      s.modseaice100(st:en,:) = junk;
      s.modcld100(st:en,:) = uint8(round(100*modcld));
      if (use_avhrr == 1)
	 junk = data.Avhrr1BCldFrac;
	 ibad = find(junk < 0 | junk > 1);
	 ibad2 = find(data.Avhrr1BQual > 0);
	 ibad = union(ibad,ibad2);
	 junk = uint8(round(100*junk));
	 junk(ibad) = 255;
         %disp(['length of bad avhrrcld100 = ' int2str(length(ibad))])
	 s.avhrrcld100(st:en,:) = junk;
      else
	 s.avhrrcld100(st:en,:) = 255;
      end
      s.nsubL(st:en,:) = uint8(nsubL);
      s.btsubL(st:en,:) = btsubL;
      s.stdsubL(st:en,:) = stdsubL;
      s.dbtq(st:en,:) = dbtq;
      s.dbt820(st:en,:) = dbt820;
      s.dbt960(st:en,:) = dbt960;
      s.retsst(st:en,:) = retsst;
      s.modsst(st:en,:) = modsst;
      s.landfrac(st:en,:) = landfrac;
      s.rlat(st:en,:) = rlat;
      s.rlon(st:en,:) = rlon;
      s.rtime(st:en,:) = data.Time2000;
      st = en + 1;
      clear rlon
    else
      s = struct;
    end


    %say(['process_verson = ' num2str(process_version)])



      % Use a structmerge function to combine datasets
      all_profiles(ifile) = prof;
      ifile = ifile + 1;
      clear prof

  if nkeep_total > 0
     prof_out = structmerge(all_profiles,2);
  else
     prof_out = [];
  end


  if en > 0
    % Trim summary structure to actual length
    s.findex = s.findex(1:en,:);
    if max(s.findex) <= 255
      s.findex = uint8(s.findex);
    end
    s.qualflag    = s.qualflag(1:en,:);
    s.GQisFlagQual= s.GQisFlagQual(1:en,:);
    s.coastflag   = s.coastflag(1:en,:);
    s.reason      = s.reason(1:en,:);
    s.clearflag   = s.clearflag(1:en,:);
    s.siteflag    = s.siteflag(1:en,:);
    s.hicloudflag = s.hicloudflag(1:en,:);
    s.randomflag  = s.randomflag(1:en,:);
    s.avhrrflag   = s.avhrrflag(1:en,:);
    s.imageunflag = s.imageunflag(1:en,:);
    s.spectunflag = s.spectunflag(1:en,:);
    s.modseaice100= s.modseaice100(1:en,:);
    s.modcld100   = s.modcld100(1:en,:);
    s.avhrrcld100 = s.avhrrcld100(1:en,:);
    s.nsubL       = s.nsubL(1:en,:);
    s.btsubL  = s.btsubL(1:en,:);
    s.stdsubL = s.stdsubL(1:en,:);
    s.dbtq    = s.dbtq(1:en,:);
    s.dbt820  = s.dbt820(1:en,:);
    s.dbt960  = s.dbt960(1:en,:);
    s.retsst  = s.retsst(1:en,:);
    s.modsst  = s.modsst(1:en,:);
    s.landfrac= s.landfrac(1:en,:);
    s.rlat    = s.rlat(1:en,:);
    s.rlon    = s.rlon(1:en,:);
    s.rtime = s.rtime(1:en,:);
  else
    say(['No files found for: ' iasifile_mask])
    head = [];
    prof = [];
  end


  if ~exist('model','var'); 
    pattr = {}; 
    hattr = {}; 
    isubset=[]; 
    s=[];
    head=[];
    prof_out=[];
    say('No Model variable. Returning...');
    farewell(rn);
    return; 
  end



  % Assign profile attribute strings
  if (use_avhrr == 0)
     pattr={ {'profiles' 'robs1' iasifile_mask}, ...
	     {'profiles' 'rtime' 'seconds since 0z, 1 Jan 2000'}, ...
	     {'profiles' 'robsqual' 'GQisFlagQual [0=OK,1=bad]'}, ...
	     {'profiles' 'calflag' 'imager data: Use uncompress_imager(calflag)'}, ...
	     {'profiles' 'iudef(1,:)' 'reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}'}, ...
	     {'profiles' 'iudef(2,:)' 'fixed site number {sitenum}'}, ...
	     {'profiles' 'iudef(3,:)' 'scan direction {scandir}'}, ...
	     {'profiles' 'iudef(4,:)' 'imager uniform test {nall}'}, ...
	     {'profiles' 'iudef(5,:)' 'imager uniform test {nsub}'}, ...
	     {'profiles' 'udef(6,:)'  'state_vector_time-rtime {orbittime}'}, ...
	     {'profiles' 'udef(7,:)'  'imager uniform test {btsub}'}, ...
	     {'profiles' 'udef(8,:)'  [model ' cloud fraction {cloudfrac}']}, ...
	     {'profiles' 'udef(9,:)'  [model ' sea ice fraction {seaice}']}, ...
	     {'profiles' 'udef(10,:)' 'imager uniform test {stdall}'}, ...
	     {'profiles' 'udef(11,:)' 'imager uniform test {stdsub}'}, ...
	     {'profiles' 'udef(12,:)' 'spectral uniform test all {dbt820u}'}, ...
	     {'profiles' 'udef(13,:)' 'spectral uniform test all {dbt960u}'}, ...
	     {'profiles' 'udef(14,:)' 'spectral uniform test all {dbt1231u}'}, ...
	     {'profiles' 'udef(15,:)' 'spectral uniform test all {dbt2140u}'}, ...
	     {'profiles' 'udef(16,:)' 'spectral clear test {retsst}'}, ...
	     {'profiles' 'udef(17,:)' 'spectral clear test {dbtsst}'}, ...
	     {'profiles' 'udef(18,:)' 'spectral clear test {dbtq}'}, ...
	     {'profiles' 'udef(19,:)' 'spectral clear test {dbt820} cirrus'}, ...
	     {'profiles' 'udef(20,:)' 'spectral clear test {dbt960} dust'} };
  else
     pattr={ {'profiles' 'robs1' iasifile_mask}, ...
	     {'profiles' 'rtime' 'seconds since 0z, 1 Jan 2000'}, ...
	     {'profiles' 'robsqual' 'GQisFlagQual [0=OK,1=band1bad,2=band2bad,4=band3bad]'}, ...
	     {'profiles' 'calflag' 'imager data: Use uncompress_imager(calflag)'}, ...
	     {'profiles' 'iudef(1,:)' 'reason [1=IASI clear,2=site,4=high cloud,8=random,16=AVHRR clear] {reason_bit}'}, ...
	     {'profiles' 'iudef(2,:)' 'fixed site number {sitenum}'}, ...
	     {'profiles' 'iudef(3,:)' 'scan direction {scandir}'}, ...
	     {'profiles' 'iudef(4,:)' 'imager uniform test {nall}'}, ...
	     {'profiles' 'iudef(5,:)' 'imager uniform test {nsub}'}, ...
	     {'profiles' 'iudef(6,:)' 'Avhrr1BCldFrac (percent) {Avhrr1BCldFrac100}'}, ...
	     {'profiles' 'iudef(7,:)' 'Avhrr1BLandFrac (percent) {Avhrr1BLandFrac100}'}, ...
	     {'profiles' 'iudef(8,:)' 'Avhrr1BQual bitflags {Avhrr1BQual}'}, ...
	     {'profiles' 'udef(6,:)'  'state_vector_time-rtime {orbittime}'}, ...
	     {'profiles' 'udef(7,:)'  'imager uniform test {btsub}'}, ...
	     {'profiles' 'udef(8,:)'  [model ' cloud fraction {cloudfrac}']}, ...
	     {'profiles' 'udef(9,:)'  [model ' sea ice fraction {seaice}']}, ...
	     {'profiles' 'udef(10,:)' 'imager uniform test {stdall}'}, ...
	     {'profiles' 'udef(11,:)' 'imager uniform test {stdsub}'}, ...
	     {'profiles' 'udef(12,:)' 'spectral uniform test all {dbt820u}'}, ...
	     {'profiles' 'udef(13,:)' 'spectral uniform test all {dbt960u}'}, ...
	     {'profiles' 'udef(14,:)' 'spectral uniform test all {dbt1231u}'}, ...
	     {'profiles' 'udef(15,:)' 'spectral uniform test all {dbt2140u}'}, ...
	     {'profiles' 'udef(16,:)' 'spectral clear test {retsst}'}, ...
	     {'profiles' 'udef(17,:)' 'spectral clear test {dbtsst}'}, ...
	     {'profiles' 'udef(18,:)' 'spectral clear test {dbtq}'}, ...
	     {'profiles' 'udef(19,:)' 'spectral clear test {dbt820} cirrus'}, ...
	     {'profiles' 'udef(20,:)' 'spectral clear test {dbt960} dust'} };
  end

  unlink(temp_dir);

  farewell(rn);

end
%%% end of program %%%
