function [head hattr prof pattr] = sdr2rtp(cfile,test_hack)
% function [head hattr prof pattr] = sdr2rtp(cfile)
%
%   Read SDR file cfile generated by Howard's CCAST code
%   and return an RTP structure.
%
%   This code accepts low resolution 842-type files and 
%   high resolution 888-type files.
%
%   INPUTS
%     cfile - input mat file genearted frmo the ccast code
%
%   OUTPUTS
%     [head hattr prof pattr] - standard RTP structure
%  
%   NOTE:
% 
%   
%
%   Breno Imbiriba - 2013.07.14
%   After Howard's readbc_rtp.m 



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % seconds between 1 Jan 1958 and 1 Jan 2000
  tdif = 15340 * 24 * 3600;
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Load data  

  if(~exist(cfile,'file'))
    error(['ccast SDR mat file ' cfile ' does not exist.']);
  end

  % load bcast SDR data
  load(cfile);


  % sanity check for bcast SDR fields
  if(~exist('scTime','var'))
    error(['Invalid ccast SDR mat file ' cfile '.']);
  end

  % sanity and existance check for geo fields
  badgeo=false;
  if(isnan(geo.FORTime(15,2)))
    warning(['Invalid or missing geo data for file ' cfile '.']);
    badgeo=true;
  end

  if(exist('test_hack','var'))
    badgeo=true;
  end

  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Check to see if it is a 842 or a 888 file

  % Number of Guard Channels = 4
  ngc=4;

  dw1 = unique(diff(vLW));
  dw2 = unique(diff(vMW));
  dw3 = unique(diff(vSW));

  a1 = nearest(dw1(1)./dw1(1));
  a2 = nearest(dw2(1)./dw1(1));
  a3 = nearest(dw3(1)./dw1(1));

  if(a2==2 & a3==4)
    % This is a LowRes file

    % IDPS SDR channel frequencies - 842-type file
    dw_lw=0.625;
    dw_mw=1.250;
    dw_sw=2.500;    

   
    islowres=true;

  elseif(a1==1 & a2==1)
    % This is a High Res file

    % HighRes Channel frequencies - 888-type file
    dw_lw=0.625;
    dw_mw=0.625;
    dw_sw=0.625;    

    islowres=false;

  else
    error(['Wrong resolutio! ' num2str([a1 a2 a3])]);
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  % Make the BASE grid
  wn_lw0 = [650 :dw_lw:1095];
  wn_mw0 = [1210:dw_mw:1750];
  wn_sw0 = [2155:dw_sw:2550];

  nchan_lw0 = length(wn_lw0); 
  nchan_mw0 = length(wn_mw0); 
  nchan_sw0 = length(wn_sw0); 

  ichan_lw0 = [1:nchan_lw0];
  ichan_mw0 = [1:nchan_mw0] + nchan_lw0;
  ichan_sw0 = [1:nchan_sw0] + nchan_lw0 + nchan_mw0;

  nchan_0 = nchan_lw0 + nchan_mw0 + nchan_sw0;


  % Add guard channels - ngc in each side of each band
  wn_lw = [wn_lw0(1)-dw_lw.*[ngc:-1:1],  wn_lw0,  wn_lw0(end)+dw_lw.*[1:ngc]];
  wn_mw = [wn_mw0(1)-dw_mw.*[ngc:-1:1],  wn_mw0,  wn_mw0(end)+dw_mw.*[1:ngc]];
  wn_sw = [wn_sw0(1)-dw_sw.*[ngc:-1:1],  wn_sw0,  wn_sw0(end)+dw_sw.*[1:ngc]];

  nchan_lw = length(wn_lw);
  nchan_mw = length(wn_mw);
  nchan_sw = length(wn_sw);

  nchan = nchan_lw + nchan_mw + nchan_sw;

  ichan_lw = [nchan_0+0*ngc+(1:ngc), ichan_lw0, nchan_0+1*ngc+(1:ngc)];
  ichan_mw = [nchan_0+2*ngc+(1:ngc), ichan_mw0, nchan_0+3*ngc+(1:ngc)];
  ichan_sw = [nchan_0+4*ngc+(1:ngc), ichan_sw0, nchan_0+5*ngc+(1:ngc)];

  % Make final grid vchan and ichan
  vchan_g = [wn_lw wn_mw wn_sw]';
  ichan_g = [ichan_lw ichan_mw ichan_sw]';


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  % Final step - Find the actual existing channels:

  iLW = interp1(vLW, (1:length(vLW))', wn_lw, 'nearest');
  iMW = interp1(vMW, (1:length(vMW))', wn_mw, 'nearest');
  iSW = interp1(vSW, (1:length(vSW))', wn_sw, 'nearest');


  % Similarly (inverse direction) for ichan
  i_lw = interp1(wn_lw, (1:numel(wn_lw)), vLW(iLW), 'nearest');  
  i_mw = interp1(wn_mw, (1:numel(wn_mw)), vMW(iMW), 'nearest');  
  i_sw = interp1(wn_sw, (1:numel(wn_sw)), vSW(iSW), 'nearest');  

  % Make vchan and ichan arrays
  vchan = [vLW(iLW) vMW(iMW) vSW(iSW)]';
  ichan = [ichan_lw(i_lw) ichan_mw(i_mw) ichan_sw(i_sw)]';

  nchanLW = numel(iLW);
  nchanMW = numel(iMW);
  nchanSW = numel(iSW);  

  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Create the PROF and PATTR structures
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  % get data sizes
  [m, nscan] = size(scTime);
  nobs = 9 * 30 * nscan;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % If we have bad geo data - use ungly_hack
  if(badgeo)
    warning(['Using geonav_ugly_hack to estimate fundamental GEO fields']);

    nfovs=9;
    nxtrack=30;
    natrack=61;

    if(nfovs~=size(rLW,2))
      nfovs=size(rLW,2);
      disp(['File contains a different number of nfovs - ',num2str(nfovs)]);
    end
    if(nxtrack~=size(rLW,3))
      nxtrack=size(rLW,3);
      disp(['File contains a different number of nxtrack - ',num2str(nxtrack)]);
    end
    if(natrack~=size(rLW,4))
      natrack=size(rLW,4);
      disp(['File contains a different number of natrack - ',num2str(natrack)]);
    end


    % Make ifov, xtrack, atrack arrays
    [ifov xtrack atrack] = mkgrid([1:nfovs],[1:nxtrack],[1:natrack]);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Time
    % 

    mtime = datenum(1958,1,1,0,0,scTime(1:nxtrack, 1:natrack)/1000);

    % Reproduce the same time for the ifovs

    rmtime = ones(nfovs,1)*(transpose(reshape(mtime,[nxtrack.*natrack,1])));

    rmtime = reshape(rmtime,[1 nfovs*nxtrack*natrack]);

    rtime = (rmtime - datenum(2000,1,1,0,0,0))*3600*24;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Make a profile and header:

    prof.rtime = rtime;
    %prof.rmtime = rmtime;
    %prof.robs1 = robs1;
    %prof.ifovs = reshape(ifov,[1,nfovs*nxtrack*natrack]);
    %prof.xtrack= reshape(xtrack,[1,nfovs*nxtrack*natrack]);
    %prof.atrack= reshape(atrack,[1,nfovs*nxtrack*natrack]);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Set up attributes 

    pattr = set_attr('profiles','rtime','seconds since 0z 1 Jan 2000');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Add Geolocation

    geo = geonav_ugly_hack(scTime, eng);

    % The rank is: ([1:3]x[xtrack])x([1:3]x[atrack])
    % so we must reshape it:
    %
    rlat = reshape(permute(reshape(geo.fovLat,[3,nxtrack,3,natrack]),[1 3 2 4]),[nfovs, nxtrack, natrack]);
    rlon = reshape(permute(reshape(geo.fovLon,[3,nxtrack,3,natrack]),[1 3 2 4]),[nfovs, nxtrack, natrack]);

    prof.rlat = reshape(rlat,[1,nfovs*nxtrack*natrack]);
    prof.rlon = reshape(rlon,[1,nfovs*nxtrack*natrack]);




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % If have good geo data - use it
  else

    % copy bcast geo values to the prof struct
    prof = struct;
    prof.rlat = single(geo.Latitude(:)');
    prof.rlon = single(geo.Longitude(:)');
    prof.rtime = reshape(ones(9,1) * (geo.FORTime(:)' * 1e-6 - tdif), 1, nobs);
    prof.satzen = single(geo.SatelliteZenithAngle(:)');
    prof.satazi = single(geo.SatelliteAzimuthAngle(:)');
    prof.solzen = single(geo.SolarZenithAngle(:)');
    prof.solazi = single(geo.SolarAzimuthAngle(:)');
    prof.zobs = single(geo.Height(:)');

    % assign the prof struct udefs
    prof.udef = zeros(20, nobs, 'single');
    prof.iudef = zeros(10, nobs, 'int32');

    % iudef 3 is granule ID as an int32
    t1 = str2double(cellstr(geo.Granule_ID(:,4:16)))';
    t2 = int32(ones(270,1) * t1);
    prof.iudef(3,:) = t2(:)';

    % iudef 4 is ascending/descending flag
    t1 = geo.Asc_Desc_Flag';
    t2 = int32(ones(270,1) * t1);
    prof.iudef(4,:) = t2(:)';

    % iudef 5 is orbit number 
    t1 = geo.Orbit_Number';
    t2 = int32(ones(270,1) * t1);
    prof.iudef(5,:) = t2(:)';

    % Interpolate X,Y,Z at MidTime to rtime
    xyz = geo.SCPosition; % [3 x 4*n]
    mtime = double(geo.MidTime)*1E-6 - tdif; % [1 x 4*n]
    isub = prof.rtime > 0;

    % Remove NaNs, Infs, and points with no positive diff.
    innan = find(~isnan(mtime) & ~isinf(mtime));
    msel = [logical(1); diff(mtime(innan)) > 0];
    msel = innan(msel);

    prof.udef(10,isub) = interp1(mtime(msel),xyz(1,msel),prof.rtime(isub),'linear','extrap');
    prof.udef(11,isub) = interp1(mtime(msel),xyz(2,msel),prof.rtime(isub),'linear','extrap');
    prof.udef(12,isub) = interp1(mtime(msel),xyz(3,msel),prof.rtime(isub),'linear','extrap');

    % prof.iudef( 8,:) = QAbitsLW;
    % prof.iudef( 9,:) = QAbitsMW;
    % prof.iudef(10,:) = QAbitsSW;

    % attributes borrowed from readsdr_rtp
    pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 2000'}, ...
      {'profiles' 'iudef(3,:)' 'Granule ID {granid}'}, ...
      {'profiles' 'iudef(4,:)' 'Descending Indicator {descending_ind}'}, ...
      {'profiles' 'iudef(5,:)' 'Beginning Orbit Number {orbit_num}'}, ...
      {'profiles' 'iudef(8,:)' 'longwave QA bits {QAbitsLW}'}, ...
      {'profiles' 'iudef(9,:)' 'mediumwave QA bits {QAbitsMW}'}, ...
      {'profiles' 'iudef(10,:)' 'shortwave QA bits {QAbitsSW}'}, ...
      {'profiles' 'udef(10,:)' 'spacecraft X coordinate {X}'}, ...
      {'profiles' 'udef(11,:)' 'spacecraft Y coordinate {Y}'}, ...
      {'profiles' 'udef(12,:)' 'spacecraft Z coordinate {Z}'}, ...
      };

  end
  

  % Continue with variables that do not depend on GEO data
  % locally assigned values for the prof struct
  prof.pobs = zeros(1,nobs,'single');
  prof.upwell = ones(1,nobs,'int32');

  iobs = 1:nobs;
  prof.atrack = int32( 1 + floor((iobs-1)/270) );
  prof.xtrack = int32( 1 + mod(floor((iobs-1)/9),30) );
  prof.ifov = int32( 1 + mod(iobs-1,9) );


  % Findex Approximation:
  % As we have now, findex is just the ordinal file number for a particular day.
  % Howard's files have 61 scan lines, which entails on approximately 480 seconds.
  % So here we define a "granule" as the ith 480s block in a particular day.
  start_time = datenum(2000,1,1,0,0,min(prof.rtime));
  %end_time   = datenum(2000,1,1,0,0,max(prof.rtime));
  start_time = (start_time - floor(start_time))*86400;
  %end_time = (end_time - floor(end_time))*86400;
  findex = floor(start_time/480)+1;
  prof.findex = int32(findex*ones(size(prof.rtime)));
   




  % copy bcast radiance values to the prof struct
  prof.robs1 = zeros(nchan, nobs, 'single');

  ic = 1:nchanLW;
  prof.robs1(ic,:) = single(reshape(rLW(iLW,:,:,:), nchanLW, nobs));

  ic = nchanLW + (1:nchanMW);
  prof.robs1(ic,:) = single(reshape(rMW(iMW,:,:,:), nchanMW, nobs));

  ic = nchanLW + nchanMW + (1:nchanSW);
  prof.robs1(ic,:) = single(reshape(rSW(iSW,:,:,:), nchanSW, nobs));

  prof.robsqual = zeros(1, nobs, 'single');


   

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
  % Create the HEAD and HATTR structures

  head.nchan = nchan;
  head.ichan = ichan;
  head.vchan = vchan; 

  hattr = set_attr('header','pltfid','NPP');
  if(islowres)
    hattr = set_attr(hattr,'instid','CrIS');
  else
    hattr = set_attr(hattr,'instid','CrIS HiRes');
  end
  
  head.pfields=4;

end
