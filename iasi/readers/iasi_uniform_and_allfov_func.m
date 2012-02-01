function [head,hattr,prof_out,pattr,s,isubset] = iasi_uniform_and_allfov_func(iasifile_mask, allfov)

% function [head,hattr,prof_out,pattr,s,isubset]=iasi_uniform_and_allfov_func(iasifile_mask,allfov);
%
% Read binary IASI L1C granule files and create a Cal_Subset RTP with
% clear/site/hicloud/random observation and ECMWF_ERA profile.
%
% Input:
%    iasifile_mask  - [string] name prefix of IASI granule files to read
%    allfov         - set this to 1 for all fovs to be returned [optional]
%
% Output:
%    head     - [structure] RTP header structure
%    hattr    - [cell strings] RTP header attribute strings
%    prof_out - [structure] RTP profiles structure
%    pattr    - [cell strings] - RTP profiles attribute strings
%    s        - [structure] summary structure with info on all FOVs
%    isubset  - [vector] list of subset fovs
%

% Created: 12 April 2007, Scott Hannon - created as
%    "iasi_uniform_clear_binary_template.m"
% Update: 18 April 2007, S.Hannon - binary variant created; allow arbitrary
%    natrack.
% Update: 19 April 2007, S.Hannon - added latmaxhicloud
% Update: 23 April 2007, S.Hannon - fix flag reset to 0 for ibad
% Update: 01 June 2007, S.Hannon - added all fov test results summary file
% Update: 08 June 2007, S.Hannon - version3 spectral clear test
% Update: 03 August 2007, S.Hannon - revise radiance quality check
% Update: 23 October 2007, S.Hannon - assign Scan_Direction to prof.udef2
% Update: 15 Jan 2008, S.Hannon - change "id_offset" from 140 to 0; remove
%    version suffix string from "spectral_clear" function name
% Update: 07 Nov 2008, S.Hannon - minor update for rtpV201, and add ecmwfdate
% Update: 17 Nov 2008, S.Hannon - assign clrflag
% Update: 13 Jan 2008, S.Hannon - assign co2ppm
% Update: 12 Feb 2009, P.Schou/B.Imbiriba - convert template to function
% Update: 27 Feb 2009, P.Schou - bug fix for nkeep=0 and empty structure
% Update: 27 Feb 2009, S.Hannon - add imager_uniform_ifov test for land
% Update: 03 Mar 2009, P.Schou - bug fix
% Update: 01 Apr 2010, S.Hannon - x757 variant, and replace imager_uniform_ifov
%    with with imager_uniform2
% Update: 28 Apr 2010, S.Hannon - added imager, filemask & gzip capabilities
% Update: 03 May 2010, S.Hannon - always do imager_uniform2 and save subL
%    results in summary file; remove stddev check for high clouds; switch
%    from bt/std sub to subL for high clouds; allow coastal high cloud; call
%    imager_compress and assign output to calflag; fix ibadq
% Update: 24 May 2010, P.Schou - change 690 to maxfov; more system/BEAT
%    error checking for IASI file
% Update: 26 May 2010, S.Hannon - bug fix for calflag/imagez indices
% Update: 24 Sep 2010, S.Hannon - replace "readl1c_binary_all" with
%   "readl1c_epsflip_all"; add data.Avhrr1B* to RTP udef if they exist;
%   add state_vector_time to RTP udef; replace rtest with rtest[123];
%   bug fix: change Test6 "ii" indices to "ihicloud" so Test7 "ii" is
%   still land index from Test5b as intended
% Update: 1 Oct 2010, S.Hannon / P.Schou - specunflag changed to spectunflag
% Update: 10 Aug 2011, P.Schou - added a rlat quality check for values less
%    than -1000
% Update: 18 Nov 2011, S.Hannon - use Avhrr1BCldFrac to help select which
%    clear FOVs to save. Add reason AVHRR=16.  Increase yield of random 3x.
%    Delete most old commented out code. Add sea ice from ECMWF.  Remove
%    cloudfrac from summary and add modseaice100, modcld100, avhrrcld100, &
%    avhrrflag.
% Update: 28 Nov 2011, S.Hannon - subset AVHRR-only clear to reduce file size.
% Update: 06 Dec 2011, S.Hannon - bug fix: ikeep_avhrr only if use_avhrr
% Update: 22 Dec 2011, P.Schou - added all fov flag to return all fov points 
%    and subset list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set paths and assign constants


RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));

% IASI channel info
fchan = (645:0.25:2760)'; %' [8461 x 1]
indpt1 = 1:4231;
indpt2 = 4232:8461;
id_offset = 0; % offset for index to fast model ID conversion

% Expected/required data dimensions
maxfov = 690;   % max number of atrack*xtrack per granule
nxtrack = 30;   % number of cross track (xtrack)
npixfov = 4;    % number of IASI "pixels" per FOV (ie 2x2 = 4)
nimager = 4096; % number of IASI Imager pixels (64 x 64)
nchan   = 8461; % number of IASI channels

% Default CO2ppm
default_co2ppm = 385.0;

% Max allowed AVHRR cloud fraction
max_cfrac_avhrr = 0.02;

% AVHRR-only clear random subsetting fraction
avhrronly_clearocean_fraction = 0.1; % Keep 10% of the FOVs
avhrronly_clearland_fraction = 0.3; % Keep 30% of the FOVs

% high cloud max BT and std dev and |latitude|
btmaxhicloud = 220;
%no longer used: stdmaxhicloud = 2;
latmaxhicloud = 60;

% imager_uniform arguments
drnoise = 2;
dbtmaxall = 7;
dbtmaxsub = 2;
nminall = 4055; % of 4096
nminsub = 1587; % of 1600
stdmaxall = 1.7;
stdmaxsub = 0.5;

% imager_uniform2 arguments for Land
dbtmaxallL = 14;
dbtmaxsubL = 4;
nminallL = 1568; % of 1600
nminsubL =  217; % of 221
stdmaxallL = 3.4;
stdmaxsubL = 1;

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

% Value for "no data"
nodata = -999;

% Random yield adjustment factor
%randadjust = 0.1;
randadjust = 0.3;

% Fixed site range (in km)
range_km = 55.5;

% Minimum landfrac for land; max landfrac for sea
minlandfrac_land = 0.99;
maxlandfrac_sea = 0.01;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executable code

if nargin == 1
  allfov = 0;
end

% Determine number of IASI files to be processed
iasifiles = findfiles(iasifile_mask);
disp(['Found ' int2str(length(iasifiles)) ' IASI files'])

clear all_profiles;
nkeep_total = 0;
pattr={};

% Declare the summary file
% Summary file suffix; full filename=<rtpfile><summary_suffix>.mat
disp('allocating memory for summary')
summary_suffix='_allfov_summary';
st = 1;
en = 0;
% Note: granules contain up to 690 x 4 FOVs.
%maxfov = 300; % tighten this down for the clear subset (an approximation)
s.findex = uint16(zeros(maxfov*length(iasifiles),npixfov));
s.qualflag    = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.GQisFlagQual= uint8(zeros(maxfov*length(iasifiles),npixfov));
s.coastflag   = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.reason      = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.clearflag   = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.siteflag    = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.hicloudflag = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.randomflag  = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.avhrrflag   = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.imageunflag = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.spectunflag = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.modseaice100= uint8(zeros(maxfov*length(iasifiles),npixfov));
s.modcld100   = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.avhrrcld100 = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.nsubL       = uint8(zeros(maxfov*length(iasifiles),npixfov));
s.btsubL  = single(zeros(maxfov*length(iasifiles),npixfov));
s.stdsubL = single(zeros(maxfov*length(iasifiles),npixfov));
s.dbtq    = single(zeros(maxfov*length(iasifiles),npixfov));
s.dbt820  = single(zeros(maxfov*length(iasifiles),npixfov));
s.dbt960  = single(zeros(maxfov*length(iasifiles),npixfov));
s.retsst  = single(zeros(maxfov*length(iasifiles),npixfov));
s.modsst  = single(zeros(maxfov*length(iasifiles),npixfov));
s.landfrac= single(zeros(maxfov*length(iasifiles),npixfov));
s.rlat    = single(zeros(maxfov*length(iasifiles),npixfov));
s.rlon    = single(zeros(maxfov*length(iasifiles),npixfov));
s.rtime = double(zeros(maxfov*length(iasifiles),npixfov));

% Declare tmp directory (for any files that need to be unzipped)
temp_dir = mktemp('dir','/dev/shm/IASI_L1C');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over the IASI files
disp('looping over files')
ifile = 1;
for ic = 1:length(iasifiles)
  iasifile = iasifiles{ic};

  disp(['File: ' iasifile])

  % Clear all used variables
  qualflag = [];
  randomflag = [];
  coastflag = [];
  siteflag = [];
  imageunflag = [];
  hicloudflag = [];
  spectunflag = [];
  clearflag = [];
  avhrrflag = [];
  dbtq = [];
  dbt820 = [];
  dbt960 = [];
  retsst = [];
  reason = [];
  rlat = [];
  rlon = [];
  landfrac = [];
  GQisFlagQual = [];


  % Read granule data
  disp('DELETE_ME: calling readl1c_epsflip_all')
  clear data
  try
     data = readl1c_epsflip_all(iasifile);
  catch
     fh = fopen('~/iasi_errors','a');
     fprintf(fh,['ERROR reading ' iasifile '\n']);
     fclose(fh);
     continue
  end
  if ~exist('data','var')
     disp(['NO DATA variable in ' ...
     '/asl/matlab/iasi/uniform/iasi_uniform_clear_func.m '])
     continue
  end


  % Window channel radiance to use for r>0 testing
  rtest1 = squeeze(data.IASI_Radiances(:,:,1265)); %  961.00 cm^-1 band1
  rtest2 = squeeze(data.IASI_Radiances(:,:,2345)); % 1231.00 cm^-1 band2
  rtest3 = max(data.IASI_Radiances(:,:,[5231,5273,5317]),[],3); % band3


  % Check data dimensions
  [nax,ii] = size(data.Latitude);
  if (ii ~= npixfov)
     error(['Unexpected npixfov returned by readl1c: expect ', ...
     int2str(npixfov) ', found ', int2str(ii)])
  end
  natrack = round( nax./nxtrack );
  ii = round( natrack * nxtrack );
  if (ii ~= nax)
     error('Non-integer number of scanlines returned by readl1c') 
  end
  nobs = round( nax*npixfov );     % exact integer


  % Compress imager data
  [ImageZ] = compress_imager(data.IASI_Image, data.ImageLat, data.ImageLon);


  % Reshape lat/lon to 1D for use with ECMWF reader
  rlat = data.Latitude;
  rlat1d = reshape(data.Latitude, 1,nobs);
  rlon1d = reshape(data.Longitude, 1,nobs);
  % Ensure rlon1d is on 0:360 grid
  ii = find(rlon1d < 0 & rlon1d > -180.0001);
  rlon1d(ii) = 360 + rlon1d(ii);


  % Get model surface termperature
  disp('Adding SKT, TCC, & CI from ECMWF');
  pattr = set_attr({},'rtime','Seconds since 2000','profiles');
  model = 'ECMWF';
  p = struct;
  p.rlat = data.Latitude(:)'; %'
  p.rlon = data.Longitude(:)'; %'
  p.rtime = data.Time2000(:)'; %'
  p.rtime(p.rtime == 0) = nan;
  p.rlat(abs(p.rlat) > 1000) = nan;
  p.rlon(abs(p.rlon) > 1000) = nan;
  %
  h.pfields = 0;
  try
    [h hattr p pattr] = rtpadd_ecmwf_data(h,{},p,pattr,{'SKT' 'TCC', 'CI'});
  catch
    disp(['Missing ECMWF data, using gfs'])
    [h hattr p pattr] = rtpadd_gfs(h,{},p,pattr);
  end
  %
  datestr(datenum(2000,1,1,0,0,[min(p.rtime) max(p.rtime)]))
%%% uncomment for testing
%  sum(abs(p.rlat(:) <= 90) & abs(p.rlon(:) <= 360))
%  p
%%%
  modsst   = reshape(p.stemp,[],npixfov);
  modcld   = reshape(p.cfrac,[],npixfov);
  modseaice= reshape(p.udef(1,:),[],npixfov);
  % Force sea ice to values 0-1 and NaN
  ibadseaice = find(modseaice < 0 | modseaice > 1);
  modseaice(ibadseaice) = NaN;


  %%%%%%%%%%%%%%%%%%
  % Test #1: Quality
  %disp('DELETE_ME: starting Test#1')
  %
  GQisFlagQual=data.GQisFlagQual; % (0=OK, 1=bad)
  qualflag = uint8(zeros(nax, npixfov));
  % Note: GQisFlagQual is unreliable; check some variables
  %
  % Find bad latitude & longitude
  ibad = find( (abs(data.Latitude) + abs(data.Longitude)) < 1E-6 );
  qualflag(ibad) = 1;
  ibad = find( data.Latitude <= nodata | data.Longitude <= nodata );
  qualflag(ibad) = 1;
  ibad = find( isnan(data.Latitude) == 1 | data.Latitude < -1000 );
  qualflag(ibad) = 1;
  ibad = find( isnan(data.Longitude) == 1 );
  qualflag(ibad) = 1;
  %
  % Find observations with bad radiances in all channels
  junk = max(data.IASI_Radiances,3); % max over channels
  ibad = find( junk < 1E-6 );
  qualflag(ibad) = 1;
  % Check radiance of one particular channel
  ibad = find(rtest1 < 1E-6);
  qualflag(ibad) = 1;
  ibad = find(rtest2 < 1E-6);
  qualflag(ibad) = 1;
  ibad = find(rtest3 < 1E-6);
  qualflag(ibad) = 1;
  %
  % Find bad satzen
  ibad = find( data.Satellite_Zenith <= nodata );
  qualflag(ibad) = 1;
  ibad = find( isnan(data.Satellite_Zenith) == 1 );
  qualflag(ibad) = 1;
  %
  % Final bad quality indices
  ibadq = find(qualflag == 1);
  %
  disp(['DELETE_ME: # of bad qual=' int2str(length(find(qualflag==1)))])


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get landfrac/topography info
  %
  ibad = find( qualflag == 1 );
  rlat(ibad) = 0;
  rlat1d(ibad) = 0;
  rlon1d(ibad) = 0;
  %
  [salti, junk] = usgs_deg10_dem(rlat1d, rlon1d);
  %
  landfrac = reshape(junk, nax,npixfov);
  lsea = zeros(nax,npixfov);
  ii = find( landfrac < maxlandfrac_sea );
  lsea(ii) = 1;
  lland = zeros(nax,npixfov);
  ii = find( landfrac > minlandfrac_land );
  lland(ii) = 1;
  llandall = max(lland,[],2); % [nax,1]
  %
  disp(['DELETE_ME: # of lsea=' int2str(length(find(lsea==1)))])
  %
  %%% uncomment this block for a plot of land, sea, & coast
  %iland=find(landfrac > minlandfrac_land);
  %isea=find(landfrac < maxlandfrac_sea);
  %icoast=find(landfrac > maxlandfrac_sea & landfrac < minlandfrac_land);
  %landfrac1d=reshape(landfrac,1,nobs);
  %plot(rlon1d(isea),rlat1d(isea),'b*',rlon1d(iland),rlat1d(iland),'g*', ...
  %   rlon1d(icoast),rlat1d(icoast),'k*')
  %pause(1)
  %clear iland isea icoast landfrac1d
  %%%


  %%%%%%%%%%%%%%%%%
  % Test #2: Random
  %disp('DELETE_ME: starting Test#2')
  %
  randomflag = uint8(zeros(nax,npixfov));
  %
  % Restrict random selction to FOVs with cross-track=15 and not bad quality
  %ix15 = find(data.AMSU_FOV == 15 & qualflag == 0 & data.IASI_FOV == 1);
  ix15 = find(data.AMSU_FOV == 15 & qualflag == 0);
  nx15 = length(ix15);
  if (nx15 > 0)
     randnum01 = rand([nx15,1]);
     randlimit = randadjust .* cos( data.Latitude(ix15)*pi/180 );
     ir = find( randnum01 < randlimit );
     if (length(ir) > 0)
	randomflag(ix15(ir)) = 1;
     end
  end
  %
  disp(['DELETE_ME: # of random=' int2str(length(find(randomflag==1)))])


  %%%%%%%%%%%%%%%%%%
  % Test #3: Coastal
  %disp('DELETE_ME: starting Test#3')
  coastflag = uint8(zeros(nax,npixfov));
  icoast = find( landfrac > maxlandfrac_sea & landfrac < minlandfrac_land );
  if (length(icoast) > 0)
     coastflag(icoast) = 1;
  end
  %
  % Combine coastflag with qualflag
  badflag = qualflag;
  badflag(icoast) = 1;
  clear icoast
  %
  disp(['DELETE_ME: # of coast=' int2str(length(find(coastflag==1)))])


  % Declare remaining flag arrays
  siteflag    = uint8(zeros(nax,npixfov));
  sitenum     = zeros(nax,npixfov);
  imageunflag = uint8(zeros(nax,npixfov));
  hicloudflag = uint8(zeros(nax,npixfov));
  spectunflag = uint8(zeros(nax,npixfov));
  clearflag   = uint8(zeros(nax,npixfov));
  avhrrflag   = uint8(zeros(nax, npixfov));


  itest = find(badflag == 0);
  ibad = find(badflag == 1);
  if (length(itest) > 0) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%
    % Test #4: Fixed site
    %disp('DELETE_ME: starting Test#4')
    %
    [sind, snum] = fixedsite(rlat1d(itest), rlon1d(itest), range_km);
    isiteind = itest( sind );
    siteflag(isiteind) = 1;
    sitenum(isiteind) = snum;
    clear sind snum
    %
    disp(['DELETE_ME: # of site=' int2str(length(find(siteflag==1)))])


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test #5: Imager uniformity
    %disp('DELETE_ME: starting Test#5')
    %
    % Test of 64x64 (all) and corner 40x40 (sub) imager pixels
    [imageunflag, btall, btsub, nall, nsub, stdall, stdsub]=imager_uniform( ...
       data.IASI_Image, drnoise, dbtmaxall, dbtmaxsub, nminall, nminsub, ...
       stdmaxall, stdmaxsub);
    %
    % Test of central 40 x 40 (all) and circular (sub) imager pixels
    [imageunflagL, btallL, btsubL, nallL, nsubL, stdallL, stdsubL] = ...
       imager_uniform2( data.IASI_Image, drnoise, dbtmaxallL, dbtmaxsubL, ...
       nminallL, nminsubL, stdmaxallL, stdmaxsubL);
    %
    if (max(max(nsubL)) > 255)
      error('nsubL too big to save as uint8')
    end
    %
    % Apply quality & coast flag to imageunflag
    imageunflag(ibad) = 0;
    %
    disp(['DELETE_ME: # of imageun =' int2str(length(find(imageunflag==1)))])
    disp(['DELETE_ME: # of imageunL=' int2str(length(find(imageunflagL==1)))])
    %
    % Test #5b: Imager uniformity over land
    ii = find(lland == 1);
    iiall = find(llandall == 1);
    if (length(ii) > 0)
       % Update standard variables for land
       imageunflag(ii) = imageunflagL(ii);
       btall(iiall) = btallL(iiall);
       btsub(ii) = btsubL(ii);
       nall(iiall) = nallL(iiall);
       nsub(ii) = nsubL(ii);
       stdall(iiall) = stdallL(iiall);
       stdsub(ii) = stdsubL(ii);
    end


    %%%%%%%%%%%%%%%%%%%%%%
    % Test #6: high clouds
    %disp('DELETE_ME: starting Test#6')
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
    %
    disp(['DELETE_ME: # of hicloud=' int2str(length(find(hicloudflag==1)))])


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test #7: spectral uniformity
    %disp('DELETE_ME: starting Test#7')
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
    disp(['DELETE_ME: # of spectun=' int2str(length(find(spectunflag==1)))])


    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Test #8: spectral clear
    %disp('DELETE_ME: starting Test#8')
    %
    [clearflag, retsst, dbtq, dbt820, dbt960, dbtsst] = spectral_clear( ...
       data.IASI_Radiances, data.Satellite_Zenith, lsea, modsst, ...
       spectunflag, dbtqmin, dbt820max, dbt960max, dbtsstmax);
    %
    disp(['DELETE_ME: # of clear=' int2str(length(find(clearflag==1)))])
    %
    %%% Uncomment to ignore spectral clear test flag
    % clearflag = spectunflag;
    %%%


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
    disp(['DELETE_ME: # of AVHRR clear=' int2str(length(iavhrr))])

  else %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Declare "nodata" dbtq, dbt820, dbt960, dbtsst for summary file
    dbtq  =nodata*ones(nax,npixfov);
    dbt820=nodata*ones(nax,npixfov);
    dbt960=nodata*ones(nax,npixfov);
    dbtsst=nodata*ones(nax,npixfov);

  end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
  disp(['  nkeep=' int2str(nkeep)])


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
disp(['length of bad modseaice100 = ' int2str(length(ibadseaice))])
    s.modseaice100(st:en,:) = junk;
    s.modcld100(st:en,:) = uint8(round(100*modcld));
    if (use_avhrr == 1)
       junk = data.Avhrr1BCldFrac;
       ibad = find(junk < 0 | junk > 1);
       ibad2 = find(data.Avhrr1BQual > 0);
       ibad = union(ibad,ibad2);
       junk = uint8(round(100*junk));
       junk(ibad) = 255;
disp(['length of bad avhrrcld100 = ' int2str(length(ibad))])
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


  % Satellite etc info
  pltfidstr = data.spacecraft_id;
  instidstr = data.instrument_id;
  process_version = data.process_version;
  disp(['process_verson = ' num2str(process_version)])


  if (nkeep > 0) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Re-order ikeep so adjacent pixels are adjacent indices
    ind = reshape(1:nobs,npixfov,nax);
    ind1dt = reshape(ind',nax,npixfov); %'
    [junk,isort] = sort( ind1dt(ikeep) );
    ikeepout = ikeep(isort);
    nkeepout = length(ikeepout);


    % Create RTP structures for output
    %disp('DELETE_ME: creating RTP structures')
    head = struct;
    prof = struct;
    %
    % Add DEM info to prof
    prof.salti    = salti(ikeepout);
    junk = reshape(landfrac,1,nobs);
    prof.landfrac = junk(ikeepout);
    %
    % Assign clrflag
    junk = zeros(1,nobs);
    junk(iclear) = 1;
    prof.clrflag = junk(ikeepout);
    %
    % Add observation info to prof
    junk = reshape(data.Latitude,1,nobs);
    prof.rlat   = junk(ikeepout);
    junk = reshape(data.Longitude,1,nobs);
    prof.rlon   = junk(ikeepout);
    junk = reshape(data.Time2000,1,nobs);
    prof.rtime  = junk(ikeepout);
    junk = reshape(data.GQisFlagQual,1,nobs);
    prof.robsqual = junk(ikeepout);
    junk = reshape(data.Satellite_Zenith,1,nobs);
    prof.satzen = junk(ikeepout);
    junk = reshape(data.Satellite_Azimuth,1,nobs);
    prof.satazi = junk(ikeepout);
    junk = reshape(data.Solar_Zenith,1,nobs);
    prof.solzen = junk(ikeepout);
    junk = reshape(data.Solar_Azimuth,1,nobs);
    prof.solazi = junk(ikeepout);
    junk = reshape(data.Satellite_Height,1,nobs);
    prof.zobs   = junk(ikeepout);
    junk = reshape(data.Scan_Line,1,nobs);
    prof.atrack = junk(ikeepout);
    junk = reshape(data.AMSU_FOV,1,nobs);
    prof.xtrack = junk(ikeepout);
    % Note: IASI has no granule number (findex)
    junk = reshape(data.IASI_FOV,1,nobs); % pixel number
    prof.ifov = junk(ikeepout);
    %
    % Declare integer iudef array
    prof.iudef   = nodata*ones(10,nkeep);
    junk = reshape(reason,1,nobs);
    prof.iudef( 1,:) = junk(ikeepout);
    junk = reshape(sitenum,1,nobs);
    prof.iudef( 2,:) = junk(ikeepout);
    junk = reshape(data.Scan_Direction,1,nobs);
    prof.iudef( 3,:) = junk(ikeepout);
    junk = reshape(nall*ones(1,4),1,nobs);
    prof.iudef( 4,:) = junk(ikeepout);
    junk = reshape(nsub,1,nobs);
    prof.iudef( 5,:) = junk(ikeepout);
    %
    % Declare real udef array
    prof.udef   = nodata*ones(20,nkeep);
    % Save some uniform/clear test results in udef
    prof.udef( 6,:) = data.state_vector_time - prof.rtime;
    junk = reshape(btsubL,1,nobs);
    prof.udef( 7,:) = junk(ikeepout);
    junk = reshape(modcld,1,nobs);
    prof.udef(8,:) = junk(ikeepout); % cloud frac
    junk = reshape(modseaice,1,nobs);
    prof.udef(9,:) = junk(ikeepout); % sea ice
    junk = reshape(stdall*ones(1,4),1,nobs);
    prof.udef(10,:) = junk(ikeepout);
    junk = reshape(stdsub,1,nobs);
    prof.udef(11,:) = junk(ikeepout);
    junk = reshape(dbt820u(:,1)*ones(1,4),1,nobs);
    prof.udef(12,:) = junk(ikeepout);
    junk = reshape(dbt960u(:,1)*ones(1,4),1,nobs);
    prof.udef(13,:) = junk(ikeepout);
    junk = reshape(dbt1231u(:,1)*ones(1,4),1,nobs);
    prof.udef(14,:) = junk(ikeepout);
    junk = reshape(dbt2140u(:,1)*ones(1,4),1,nobs);
    prof.udef(15,:) = junk(ikeepout);
    junk = reshape(retsst,1,nobs);
    prof.udef(16,:) = junk(ikeepout);
    junk = reshape(dbtsst,1,nobs);
    prof.udef(17,:) = junk(ikeepout);
    junk = reshape(dbtq,1,nobs);
    prof.udef(18,:) = junk(ikeepout);
    junk = reshape(dbt820,1,nobs);
    prof.udef(19,:) = junk(ikeepout);
    junk = reshape(dbt960,1,nobs);
    prof.udef(20,:) = junk(ikeepout);
    %
    if (use_avhrr == 1)
       junk = round(reshape(data.Avhrr1BCldFrac,1,nobs)*100);
       prof.iudef( 6,:) = junk(ikeepout);
       junk = round(reshape(data.Avhrr1BLandFrac,1,nobs)*100);
       prof.iudef( 7,:) = junk(ikeepout);
       junk = reshape(data.Avhrr1BQual,1,nobs);
       prof.iudef( 8,:) = junk(ikeepout);
    end
    %
    %%%
    % Assign sea emissivity (even if land, for lack of anything better)
    %   [nemis, efreq, seaemis] = cal_seaemis(prof.satzen);
    %   [nemis, efreq, seaemis] = cal_seaemis2(prof.satzen, prof.wspeed);
    %   prof.nemis = nemis;
    %   prof.emis = seaemis;
    %   prof.efreq = efreq;
    %   prof.rho = (1.0 - seaemis)/pi;
    %   clear nemis seaemis efreq
    %%%
    %
    % Save ImageZ to calflag
    ix = reshape((1:nax)'*ones(1,npixfov),1,nobs); %'
    ixk = ix(ikeepout);
    prof.calflag = ImageZ(:,ixk);
    clear ImageZ ix ixk
    %
    % Assign default co2ppm
    prof.co2ppm = default_co2ppm*ones(1,nkeep);
    %
    % Pull out IASI radiances and then clear "data"
    rad = reshape(data.IASI_Radiances,nobs,nchan)'; %'
    prof.robs1 = rad(:,ikeepout);
    clear data
    %
    % Update header
    head.pfields = 4; % 1(prof) + 4(ir obs);
    head.ichan(:,1)=[1:nchan];
    head.vchan(:,1)=fchan;
    head.nchan=nchan;


    % Use a structmerge function to combine datasets
    all_profiles(ifile) = prof;
    ifile = ifile + 1;
    clear prof

  end % if nkeep %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end % loop over files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
  disp(['No files found for: ' iasifile_mask])
  head = [];
  prof = [];
end


if ~exist('model','var'); pattr = {}; hattr = {}; return; end


% Assign RTP attribute strings
hattr={ {'header' 'pltfid' pltfidstr}, ...
        {'header' 'instid' instidstr} };


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

%%% end of program %%%
