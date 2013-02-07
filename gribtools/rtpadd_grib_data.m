function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr, fields, rec_per_day, center_long);

% function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr);
% function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr, fields, rec_per_day, center_long);
%
% Routine to read in a 37, 60, or 91 level ECMWF file and return a
% RTP-like structure of profiles that are the closest grid points
% to the specified (lat,lon) locations.
%
% Input:
%    sourcename : (string) complete ECMWG GRIB file name
%                to automatically pick files use either 'ECMWF' or 'ERA'
%    head      : rtp header structure
%    hattr     : header attributes
%    prof.       profile structure with the following fields
%        rlat  : (1 x nprof) latitudes (degrees -90 to +90)
%        rlon  : (1 x nprof) longitude (degrees, either 0 to 360 or -180 to 180)
%        rtime : (1 x nprof) observation time in seconds
%    pattr     : profile attributes, note: rtime must be specified
%    OPTIONAL
%    fields    : list of fields to consider when populating the rtp profiles:
%                 {'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'}
%               default:  {'SP','SKT','10U','10V','TCC','CI','T','Q','O3'}
%    rec_per_day : number of ECMWF time steps per day {default=8}
%    center_long : center of grib longitude values
%
% Output:
%    head : (RTP "head" structure of header info)
%    hattr: header attributes
%    prof : (RTP "prof" structure of profile info)
%    pattr: profile attributes
%
% Note: uses external routines: p60_ecmwf.m, p91_ecmwf.m, readgrib_inv_data.m,
%    readgrib_offset_data.m, as well as the "wgrib" program.
%

% Created: 17 Mar 2006, Scott Hannon - re-write of old 60 level version
% Rewrite:  4 May 2011, Paul Schou - switched to matlab binary reader
% Update : 17 Jun 2011, Paul Schou - added grib 2 capabilities
% Update: 27 Jun 2011, S.Hannon - add isfield test for head.pfields
% Update: 05 Jan 2012, L. Strow - bitor argument translated to uint32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence
%
% 0.1 Setup H20, O3, set number of recs per day (ECMWF style)
% 0.2 Get rtime from the prof (RTP)
% 0.3 Read GRIB file if exists and is unziped
% 0.4 Check if times in the file date are compatible with rtime - FAIL
% 0.5 Chek for gzip grub file
% 0.6 Error if file doesn't exist... 
% 1.0 If gribversion~=1 and the gribfile is not *.2, split it
% 1.1    and call this same routine again for each part
% 1.2    RETURN
% 1.3 Again, Tests for the file existence
% 1.4 Again, Read grib data
% 1.5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  rn='rtpadd_grib_data';
  greetings(rn);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Setup 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  min_H2O_gg = 3.1E-7;  % 0.5 pppm
  min_O3_gg = 1.6E-8;   % 0.01 ppm
  new_file = [];

  if ~exist('rec_per_day','var')
    rec_per_day = 8;
  end

  if ~exist('fields','var')
    fields = [];
  end


  [rtime rtime_st] = rtpdate(head,hattr,prof,pattr);


  if exist([sourcename '.inv']) & exist([sourcename])
    [offset,param,level,gribdate] = readgrib_inv_data(sourcename);
    if ~( max(gribdate)+0.5/rec_per_day > min(rtime) & min(gribdate)-0.5/rec_per_day < max(rtime) )
      error(['ERROR: GRIB file times out of range. Something is bad.']);
    end
  end

  orig_file = sourcename;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % If GRIB file is in GZIP format, unzip it into a temporary file
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ~exist(sourcename,'file') & exist([sourcename '.gz'],'file')
    new_file = keepNfiles([sourcename '.gz'],2);
    sourcename = new_file;
  elseif ~exist(sourcename,'file')
    disp('attempting download of ECMWF file');
    system(['cd ' getenv('SHMDIR') '/; curl -O http://cress.umbc.edu/' sourcename '.gz']);
    new_file = [getenv('SHMDIR') '/' basename(sourcename)];
    sourcename = new_file;
  end

  if ~exist(sourcename,'file')
    error(['Grib file does not exist: ' sourcename])
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % If GRIB version is NOT 1, split into two parts, with extensions *.1 and *.2
  % After, call this same routine again for each part.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % split out the two versions of grib and call self twice, one for each version
  if getgribver(sourcename) ~= 1 & ~strcmp(sourcename(end-1:end),'.2')

    if ~(exist([sourcename '.1'],'file') & exist([sourcename '.2'],'file'))
      system(['/asl/opt/bin/gribsplit ' sourcename ' > /dev/null; echo > ' sourcename]);
    end
    [head, hattr, prof, pattr] = rtpadd_grib_data([sourcename '.1'], head, hattr, prof, pattr, fields, rec_per_day, center_long);
    [head, hattr, prof, pattr] = rtpadd_grib_data([sourcename '.2'], head, hattr, prof, pattr, fields, rec_per_day, center_long);

    farewell(rn);
    return
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Prepare to actually read the data
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  gribver = getgribver(sourcename);

  % Check the GRIB file exists
  if ~exist(sourcename,'file')
     error(['did not find GRIB file=' sourcename]);
  end


  % Get profile fields
  [offset,param,level,gribdate] = readgrib_inv_data(sourcename);
  levs = unique(level(strcmp(param,'T')));
  if isempty(levs)
    levs = unique(level(level < 200 & level > 0));
  end
  nlev = length(levs);


  %%%%%%%%%%%%%%%%%%%
  % Check lat and lon
  %%%%%%%%%%%%%%%%%%%

  nprof = length(prof.rlat);
  if (length(prof.rlon) ~= nprof)
     say('Error: lon and lat are different sizes!');
     farewell(rn);
     return
  end

  % Latitude must be between -90 (south pole) to +90 (north pole)
  if any(prof.rlat < -90 | prof.rlat > 90);
     say('Error: latitude out of range!')
     farewell(rn);
     return
  end

  % Note: longitude can be either 0 to 360 or -180 to 180 
  if any(prof.rlon < -180 | prof.rlon > 360);
     say('Error: longitude out of range!')
     farewell(rn);
     return
  end

  %[rtime rtime_st] = rtpgetdate(head,hattr,prof,pattr);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Determine record numbers for profile parameters in GRIB file
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %  This section was constructed to read linearly from the grib file
  %   there is no forward and backward reading, just forward to maximize
  %   efficiency through the i/o cache.

  ci_udef = 1;
  if ~isfield(prof,'udef')
    prof.udef = nan(20,nprof,'single');
  end

  if isstr(sourcename)
    fh = fopen(sourcename,'r','b');
    say(['  opening grib file ' sourcename])
  end

  iprof = [];
  if isempty(fields)
    %fields = {'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'};
    fields = {'SP','SKT','10U','10V','TCC','CI','T','Q','O3'};
  end

  %datestr(gribdate(find(ismember(gribdate,round(rtime*8)/8))))
  date_match = 0;

  %for irec = 1:length(param)
  %for irec = find(gribdate > min(rtime)-1/8 & gribdate < max(rtime)+1/8)'
  for irec = find(ismember(gribdate,round(rtime*rec_per_day)/rec_per_day))'
    % read in the grib fields needed and skip the rest
    if ismember(param{irec}, fields)
      idate = abs(gribdate(irec) - rtime) <= 0.5/rec_per_day & ~isnan(prof.rlat) & abs(prof.rlat) <= 90;
      %say(['  matched ' num2str(sum(idate)) ' points'])
      %if level(irec) == 1; say(datestr(gribdate(irec))); end  % debug date
      %say(['    matched ' num2str(sum(idate)) ' data points of ' num2str(length(idate))])
      %say(datestr(gribdate(irec)))

      if ~any(idate); 
	continue; 
      end

      date_match = 1;
      if gribver == 1
	d = readgrib_offset_data(fh,offset(irec));
	%d = readgrib_offset(sourcename,offset(irec));
      elseif gribver == 2
	d = readgrib2_rec(sourcename,irec);
      else
	error('bad grib file / record');
      end
    else
      continue;
    end

    % convert the latitude and longitude values to matchup points
    if isempty(iprof)
      if isequal(size(d),[1 1440*721])
	d = reshape(d,1440,721);
      elseif isequal(size(d),[721 1440])
	d = reshape(d,1440,721);
      end

      %ilon = mod(round(mod(prof.rlon+180,360)/360*size(d,1)),size(d,1))+1;
      %ilon = mod(round(mod(prof.rlon,360)/360*size(d,1)),size(d,1))+1;
      rlon = mod(prof.rlon+center_long,360);
      ilon = mod(round(rlon/360*size(d,1)),size(d,1))+1;
      prof.plon = (ilon-1)*360/size(d,1)+center_long;
      % in the grib 2 files the map the latitude is flipped
      if gribver == 2
	ilat = min(size(d,2),round((prof.rlat/90+1)*(size(d,2)-1)/2)+1);
	prof.plat = ((ilat-1)*180/(size(d,2)-1)-90);
      else
	ilat = min(size(d,2),round((-prof.rlat/90+1)*(size(d,2)-1)/2)+1);
	prof.plat = -((ilat-1)*180/(size(d,2)-1)-90);
      end
      iprof = sub2ind(size(d),ilon,ilat);
    end

    %say(param{irec})

    if ~isfield(prof,'ptime'); prof.ptime = nan(1,nprof,'single'); end
    prof.ptime(1,idate) = (gribdate(irec)-rtime_st)*86400;

    if length(find(levs == level(irec))) == 0 & ( strcmp(param{irec},'T') | strcmp(param{irec},'Q') | strcmp(param{irec},'CC') | strcmp(param{irec},'O3') | strcmp(param{irec},'CIWC') | strcmp(param{irec},'CLWC') )
      say(['WARNING: bad level for record: ' num2str(irec) '  for level ' num2str(level(irec))])
      continue;
    end

    % assign the field to the correct profile field
    switch param{irec}
      % Parameter "SP" surface pressure (Pa)
      case 'SP'; if ~isfield(prof,'spres'); prof.spres = nan(1,nprof,'single'); end
	prof.spres(1,idate) = d(iprof(idate)) / 100;  % convert Pa to hPa=mb

      % Parameter "SKT" skin temperature (K)
      case 'SKT'; if ~isfield(prof,'stemp'); prof.stemp = nan(1,nprof,'single'); end
	prof.stemp(1,idate) = d(iprof(idate));
	%say(['skt ' num2str(sum(idate))])
	
      % Parameter "SSTK" skin temperature (K)
      case 'SSTK'; if ~isfield(prof,'sstk'); prof.sstk = nan(1,nprof,'single'); end
	prof.sstk(1,idate) = d(iprof(idate));
	%say(['skt ' num2str(sum(idate))])
	
      % Parameter "10U"/"10V" 10 meter u/v wind component (m/s)
      case '10U'; if ~exist('wind_u','var'); wind_u = nan(1,nprof,'single'); end
	wind_u(1,idate) = d(iprof(idate));
	%say(['setting 10U for ' num2str(sum(idate))])
      case '10V'; if ~exist('wind_v','var'); wind_v = nan(1,nprof,'single'); end
	wind_v(1,idate) = d(iprof(idate));
	%say(['setting 10V for ' num2str(sum(idate))])

      % Parameter "TCC" total cloud cover (0-1)
      case 'TCC'; if ~isfield(prof,'cfrac'); prof.cfrac = nan(1,nprof,'single'); end
	prof.cfrac(1,idate) = d(iprof(idate));
	if any(prof.cfrac > 1)
	  say('Warning: cloud frac > 1')
	  %if strcmp(getenv('USER'),'schou'); keyboard; end
	end

      % Parameter "CI" sea ice cover (0-1)
      case 'CI'; 
	%if ~isempty(getenv('TEST')); keyboard; end
	prof.udef(ci_udef,idate) = d(iprof(idate));

      % Parameter "T" temperature (K)
      case 'T'; if ~isfield(prof,'ptemp') | size(prof.ptemp,1) ~= nlev; prof.ptemp = nan(nlev,nprof,'single'); end
	prof.ptemp(find(levs == level(irec)),idate) = d(iprof(idate));
	%say('t')

      % Parameter "Q" specific humidity (kg/kg)
      case 'Q'; if ~isfield(prof,'gas_1') | size(prof.gas_1,1) ~= nlev; prof.gas_1 = nan(nlev,nprof,'single'); end
	prof.gas_1(find(levs == level(irec)),idate) = d(iprof(idate));
	  %if any(d(:) <= 0) & strcmp(getenv('USER'),'schou'); say('Q < 0!!'); keyboard; end
	% WARNING! ECMWF water is probably specific humidity rather than mixing ratio,
	% in which case this code should do: gas_1 = gas_1 / (1 - gas_1).

      % Parameter "O3" ozone mass mixing ratio (kg/kg)
      case 'O3'; if ~isfield(prof,'gas_3') | size(prof.gas_3,1) ~= nlev; prof.gas_3 = nan(nlev,nprof,'single'); end
	prof.gas_3(find(levs == level(irec)),idate) = d(iprof(idate));
	  %if any(d(:) <= 0) & strcmp(getenv('USER'),'schou'); say('O3 < 0!!'); keyboard; end

      % Parameter "CC" cloud cover (0-1) 
      case 'CC'; if ~isfield(prof,'cc') | size(prof.cc,1) ~= nlev; prof.cc = nan(nlev,nprof,'single'); end
	prof.cc(find(levs == level(irec)),idate) = d(iprof(idate));

      % Parameter "CIWC" cloud ice water content kg/kg 
      case 'CIWC'; if ~isfield(prof,'ciwc') | size(prof.ciwc,1) ~= nlev; prof.ciwc = nan(nlev,nprof,'single'); end
	prof.ciwc(find(levs == level(irec)),idate) = d(iprof(idate));

      % Parameter "CLWC" cloud liquid water content kg/kg 
      case 'CLWC'; if ~isfield(prof,'clwc') | size(prof.clwc,1) ~= nlev; prof.clwc = nan(nlev,nprof,'single'); end
	prof.clwc(find(levs == level(irec)),idate) = d(iprof(idate));
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read wind data & convert
  %%%%%%%%%%%%%%%%%%%%%%%%%%

  if exist('wind_u','var') & exist('wind_v','var')
    i = ~isnan(wind_u);
    prof.wspeed(i) = sqrt(wind_u(i).^2 + wind_v(i).^2);
    prof.wsource(i) = mod(atan2(single(wind_u(i)), single(wind_v(i))) * 180/pi,360);
  end


  % Calculate the pressure levels (using p60_ecmwf.m & p91_ecmwf.m)
  if isfield(prof,'spres') & nlev > 1
    prof.nlevs = nlev*ones(1,nprof);
    pstr = ['prof.plevs=p' int2str(nlev) '_ecmwf( prof.spres );'];
    eval(pstr);
    head.pmin = min( prof.plevs(1,:) );
    head.pmax = max( prof.plevs(nlev,:) );
  else
    levels = [1 2 3 5 7 10 20 30 50 70 100 125 150 175 200 225 250 300 350 400 450 500 550 600 650 700 750 775 800 825 850 875 900 925 950 975 1000];
    prof.nlevs = length(levels)*ones(1,nprof);
    prof.plevs = repmat(levels(:),[1 length(prof.rtime)]);
    head.pmin = min( levels );
    head.pmax = max( levels );
  end

  % Assign the output header structure
  head.ptype = 0;
  if (isfield(head,'pfields'))
     head.pfields = bitor(uint32(head.pfields), 1);
  else
     head.pfields = 1;
  end
  head.ngas = 2;
  head.glist = [1; 3];
  head.gunit = [21; 21];
  %head.nchan = 0;
  %head.mwnchan = 0;



  % Find/replace bad mixing ratios
  if isfield(prof,'gas_1')
    ibad = find(prof.gas_1 <= 0);
    nbad = length(ibad);
    if (nbad > 0)
      prof.gas_1(ibad) = min_H2O_gg;
      say(['Replaced ' int2str(nbad) ' negative/zero H2O mixing ratios'])
    end
  end
  %
  if isfield(prof,'gas_3')
    ibad = find(prof.gas_3 <= 0);
    nbad = length(ibad);
    if (nbad > 0)
      prof.gas_3(ibad) = min_O3_gg;
      say(['Replaced ' int2str(nbad) ' negative/zero O3 mixing ratios'])
    end
  end
  %  fix any cloud frac
  if isfield(prof,'cfrac')
    ibad = find(prof.cfrac > 1);
    nbad = length(ibad);
    if (nbad > 0)
      prof.cfrac(ibad) = 1;
      say(['Replaced ' int2str(nbad) ' CFRAC > 1 fields'])
    end
  end

  if exist(sourcename,'file')
    fclose(fh);
  end

  % If we are using keepNfiles, then it will keep the last 3 temporary
  %   files read in and automatically delete the rest
  if ~isempty(new_file)
    delete(new_file);
  end

  if date_match == 0
    say(['***WARNING***: No dates / fields matched, make sure the file is the correct date / set for requested fields'])
%    say(['    grib file date span : ' datestr(min(gribdate)) ' ' datestr(max(gribdate))])
%    say(['    grib records per day: ' num2str(rec_per_day)])
%    say(['    which matches       : ' datestr(min(gribdate)-0.5/rec_per_day) ' ' datestr(max(gribdate)+0.5/rec_per_day)])
%    say(['    rtime date span     : ' datestr(min(rtime)) ' ' datestr(max(rtime))])
%    say(['    nan lats            : ' num2str(sum(isnan(prof.rlat)))])
%    say(['    bad lats            : ' num2str(sum(abs(prof.rlat) > 90))])
%    say(['    total fovs          : ' num2str(length(prof.rtime))])
    %unique(param)
    %fields'
  end

 farewell(rn);

end
%%% end of function %%%
