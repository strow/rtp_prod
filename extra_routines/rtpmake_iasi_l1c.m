function [head hattr prof, pattr] = makertp_iasi_l1c(iasifiles)
% function [head hattr prof, pattr] = makertp_iasi_l1c(iasifiles)
%
%   Load all the IASI L1C data in the iasifiles list and return
%   the RTP structure.
%
% Based on the reader part of iasi_uniform_and_allfov_func.m
% Breno Imbiriba - 2013.08.03


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 0. Setup 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % IASI channel info
  fchan = (645:0.25:2760)'; %' [8461 x 1]

  % Expected/required data dimensions
  maxfov = 690;   % max number of atrack*xtrack per granule
  nxtrack = 30;   % number of cross track (xtrack)
  npixfov = 4;    % number of IASI "pixels" per FOV (ie 2x2 = 4)
  nimager = 4096; % number of IASI Imager pixels (64 x 64)
  nchan   = 8461; % number of IASI channels

  % Value for "no data"
  nodata = -999;

  % Random yield adjustment factor
  %randadjust = 0.1;
  randadjust = 0.3;




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % 1. Loop over the IASI files
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  for ic = 1:length(iasifiles)

    iasifile = iasifiles{ic};
    say(['File: ' iasifile])

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Read granule data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    clear data
    try
       data = readl1c_epsflip_all(iasifile);
    catch
       fh = fopen('~/iasi_errors','a');
       fprintf(fh,['ERROR reading ' iasifile '\n']);
       fclose(fh);
       say(['ERROR reading ' iasifile '. Continuing...']);

       continue
    end
    if ~exist('data','var')
       say(['NO DATA variable in ' ...
       '/asl/matlab/iasi/uniform/iasi_uniform_clear_func.m, continuing...'])
       continue
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check data dimensions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compress imager data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [ImageZ] = compress_imager(data.IASI_Image, data.ImageLat, data.ImageLon);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Quality Test (test #1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    qualflag = uint8(zeros(nax, npixfov));

    % Window channel radiance to use for r>0 testing
    rtest1 = squeeze(data.IASI_Radiances(:,:,1265)); %  961.00 cm^-1 band1
    rtest2 = squeeze(data.IASI_Radiances(:,:,2345)); % 1231.00 cm^-1 band2
    rtest3 = max(data.IASI_Radiances(:,:,[5231,5273,5317]),[],3); % band3

    %
    GQisFlagQual = data.GQisFlagQual; % (0=OK, 1=bad)
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


    warning('off');
    % Like what is done on site_dcc_random.m
    % Random FOVs (bit value 8)
    % We want repeatability of randomness here - if I rerun this code again 
    % I want the *same* random fovs - they are random so it doesn't matter
    %
    % For that we use int32(prof.rtime(1)) as the seed.
    % 
    random_seed = int32(data.Time2000(1)); 
    rng(random_seed,'twister');
    warning('on');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Random FoV selection
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Re-order ikeep so adjacent pixels are adjacent indices

    ind = reshape(1:nobs,npixfov,nax);
    ind1dt = reshape(ind',nax,npixfov); %'

    % We will keep all fovs:
    ikeep = [1:numel(ind1dt)];
    
    [junk,isort] = sort( ind1dt(ikeep) );
    ikeepout = ikeep(isort);
    nkeepout = length(ikeepout);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create RTP structures for output
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    head = struct;
    prof = struct;
    %
    % Add observation info to prof
    
    junk = reshape(data.Latitude,1,nobs);
    prof.rlat   = junk(ikeepout);

    junk = reshape(data.Longitude,1,nobs);
    prof.rlon   = junk(ikeepout);

    junk = reshape(data.Time2000,1,nobs);
    prof.rtime  = junk(ikeepout);
    
    junk = reshape(data.GQisFlagQual | qualflag ,1,nobs);
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Declare integer iudef array
    prof.iudef   = nodata*ones(10,nobs);


    % Reason - We only know about random 
    % reason code numbers (bit flags):
    %    1=IASI clear
    %    2=calibration site
    %    4=high clouds
    %    8=randomly selected
    %   16=AVHRR clear
    irandom = find(randomflag);
    prof.iudef(1, irandom) = 8; 

    % Scan diraction
    junk = reshape(data.Scan_Direction,1,nobs);
    prof.iudef( 3,:) = junk(ikeepout);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save AVHRR
    if (isfield(data,'Avhrr1BCldFrac') & isfield(data,'Avhrr1BQual'))
      use_avhrr = 1;
    end

    if (use_avhrr == 1)
       junk = round(reshape(data.Avhrr1BCldFrac,1,nobs)*100);
       prof.iudef( 6,:) = junk(ikeepout);
       junk = round(reshape(data.Avhrr1BLandFrac,1,nobs)*100);
       prof.iudef( 7,:) = junk(ikeepout);
       junk = reshape(data.Avhrr1BQual,1,nobs);
       prof.iudef( 8,:) = junk(ikeepout);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Declare real udef array
    prof.udef   = nodata*ones(20,nobs);
    prof.udef( 6,:) = data.state_vector_time - prof.rtime;




    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save ImageZ to calflag
    ix = reshape((1:nax)'*ones(1,npixfov),1,nobs); %'
    ixk = ix(ikeepout);
    prof.calflag = ImageZ(:,ixk);
    clear ImageZ ix ixk
    %

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pull out IASI radiances and then clear "data"
    rad = reshape(data.IASI_Radiances,nobs,nchan)'; %'
    prof.robs1 = rad(:,ikeepout);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Satellite etc info - to attributes
    pltfidstr = data.spacecraft_id;
    instidstr = data.instrument_id;
    process_version = data.process_version;

    clear data

  end % loop over files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %
  % Update header
  head.pfields = 4; % 1(prof) + 2(ir calc) + 4(ir obs);
  head.ichan(:,1)=[1:nchan];
  head.vchan(:,1)=fchan;
  head.nchan=nchan;


  % Assign RTP attribute strings
  hattr = set_attr('header','pltfid',pltfidstr);
  hattr = set_attr(hattr,'instid',instidstr);


  pattr = set_attr('profiles', 'robs1', iasifiles{1});
  pattr = set_attr('profiles', 'rtime', 'seconds since 0z, 1 Jan 2000');
   
  pattr = set_attr(pattr,'robsqual', 'GQisFlagQual [0=OK,1=band1bad,2=band2bad,4=band3bad]');
  pattr = set_attr(pattr,'calflag', 'imager data: Use uncompress_imager(calflag)');
  pattr = set_attr(pattr,'iudef(3,:)', 'scan direction {scandir}');
  pattr = set_attr(pattr,'iudef(6,:)', 'Avhrr1BCldFrac (percent) {Avhrr1BCldFrac100}');
  pattr = set_attr(pattr,'iudef(7,:)', 'Avhrr1BLandFrac (percent) {Avhrr1BLandFrac100}');
  pattr = set_attr(pattr,'iudef(8,:)', 'Avhrr1BQual bitflags {Avhrr1BQual}');
  pattr = set_attr(pattr,'udef(6,:)' , 'state_vector_time-rtime {orbittime}');



end
