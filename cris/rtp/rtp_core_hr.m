function rtp_core_hr(dates, rtpset, data_path, data_type, data_str, src, prod_dir)
% function rtp_core_hr(dates, rtpset, data_path, data_type, data_str, src, prod_dir)
%
%  Runtime function to make CrIS rtp files
%
%  Input: 
%     dates(2) - [start end] - matlab datenum format 
%    
%     rtpset='subset'/'full'/'full4ch'/'site_only_obs'
%     data_path='/home/motteler/cris/data', '/asl/data/cris/sdr60';
%     data_str=''/'_subset'/.../.../'site_only_obs'
%     src='.ccast', '_noaa_ops';
%
%  Name is constructe like: ['cris_' data_type data_str src '.yyyy.mm.dd.hh.v1.rtp']
%    data_type = basename(data_path) = sdr60 ; in the example
% 
%  Coded to work on the HR Cris data, but it also can work with regular data, 
%  and will replace the originsl rtp_core.
%
%  Based on: 15 Feb 2011 - Paul Schou
%  Breno Imbiriba - 2013.03.22

  rn='rtp_core_hr'
  greetings(rn);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % 0 - Setup
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  if(numel(dates)==1)
    warning('Input variable "dates" has no end date. Setting it to the end of the day (to the last milisecond!)');
    dates(2) = floor(dates(1))+0.99999998; % To the last milisecond 0.999 999 988 425 926
  end  


  version = 'v1';

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Loop over time - Rearranging the data
  % Loop over hours or 10mins (for an allfovs)
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % "span" carried the hour, or the 10mins interval, array.
  span = 0:23;
  day2span = 24;

  if strcmp(rtpset,'full')
    span = 0:24*6-1;
    day2span = 144;
  elseif strcmp(rtpset,'full4ch')
    span = 0:23;
    day2span = 24;
  end



  startday = floor(dates(1));
  starttime = dates(1)-startday;
  endtime = dates(2)-startday;

  disp(['Processing t0=' datestr(dates(1),'yyyy/mm/dd - HH:MM:SS') ' tf=' datestr(dates(2),'yyyy/mm/dd - HH:MM:SS') ]);

  % Find which entried of 'span' match these times:
  iokspan = find(span>=floor(starttime*day2span) & span<ceil(endtime*day2span));

  if(numel(iokspan)==0)
    disp(['No span selected: ' datestr(starttime,'HH:MM:SS') ' - ' datestr(endtime,'HH:MM:SS') ]);
    disp(rtpset)
    disp(span);
    disp(starttime*day2span)
    disp(endtime*day2span);
  end

  span = span(iokspan);

  for decihour = span

    if strcmp(rtpset,'full')
      hour = floor(decihour / 6);
      hourstr = [num2str(hour,'%02d') num2str(mod(decihour,6),'%01d')];
      timestr = [num2str(decihour,'%03d')];
    else
      hour = decihour;
      hourstr = [num2str(hour,'%02d')];
      timestr = [num2str(hour,'%02d')];
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Search for data files
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(strcmp(src,'.ccast'))

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % 1.1 - Howard's files:
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      yyyy = datestr(dates(1),'yyyy');
      ddd  = num2str(floor(mat2jd(dates(1))),'%03d');
      yyyymmdd = datestr(dates(1),'yyyymmdd');

      inputglob = [data_path '/' yyyy '/' ddd '/SDR_d' yyyymmdd '_t' hourstr '*.mat'];
     
      files = findfiles(inputglob);

      disp(['Found ' num2str(numel(files)) ' Howard SDR Files.']);

    elseif(strcmp(src,'_noaa_ops'))

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % 1.2 - Standard sdr60 files:
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      yyyy = datestr(dates(1),'yyyy');
      ddd  = num2str(floor(mat2jd(dates(1))),'%03d');
      yyyymmdd = datestr(dates(1),'yyyymmdd');

       
      inputglob = ([data_path '/hdf/' yyyy '/' ddd '/SCRIS_npp_d' yyyymmdd '_t' hourstr '*' src '.h5']);
    
      files = findfiles(inputglob);

      disp(['Found ' num2str(numel(files)) ' Standard SDR60 Files.']);

    else
      error('Wrong file_type - it must be either "_noaa_ops" or ".ccast"');
    end

    if length(files) == 0; 
      disp(['WARNING: No CrIS Data Files. Skipping....']);
      continue; 
    end  % no files found = continue to next hour

 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Make output file name
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rtpfile = [prod_dir '/' datestr(dates(1),'yyyy/mm/dd') '/cris' data_type data_str src '.' datestr(dates(1),'yyyy.mm.dd') '.' timestr '.' version '.rtp'];


    if exist(rtpfile,'file')
      disp(['  RTP File ' rtpfile ' already exists. Skipping....']);
      continue
    end

    % Make/check for lock file
    disp(['  output: ' rtpfile])
    if ~lockfile(rtpfile); 
      disp(['WARNING: Lockfile exists for file ' rtpfile '. Skipping....']); 
      continue; 
    end

    disp(['Creating RTP File ' rtpfile]);

    % make output dir 
    mkdirs(dirname(rtpfile))



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Load hdf files and construct the RTP structure
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for ifile = 1:length(files)

      dd = dir(files{ifile});

      disp(['Reading ' files{ifile}]);

      [~, ~, ext] = fileparts(files{ifile});

      if(strcmp(ext,'.mat'));
	[head hattr profi pattr] = sdr2rtp_bc(files{ifile});
      else
	[head hattr profi pattr] = sdr2rtp_h5_l(files{ifile});
      end

      prof(ifile) = profi;

    end
     
    % if no files were loaded continue on to the next hour
    if ~exist('prof','var')
      disp('No prof structure (no SDR files loaded) ! Skipping');
      continue
    end
    
    prof = structmerge(prof,2);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Run some emergency fixes - in the case we have problems
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [head hattr prof pattr] = sdr_fixup(head,hattr, prof, pattr);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Adding Land information
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Issue an warning if have bad dta banks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    cris_banks_test_warn_l(head, prof);

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Compute Clear Flag
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % The subset algorithm seems to need 
    % atmospheric model information.(???)
    % Fill ECMWF (and other fields) into the file
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(strcmp(rtpset,'site_only_obs'))
      do_clear=false;
    else
      do_clear=true;
    end

    if(do_clear)
      [head hattr prof pattr] = cris_clear_flag_l(head,hattr,prof,pattr);
    end 


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Perform data subsetting
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp(rtpset,'subset')
      subtest = 1;
    elseif strcmp(rtpset,'full4ch')
      subtest = 2;
    elseif strcmp(rtpset,'site_only_obs')
      subtest = 3;
    else
      subtest = 0; % full
    end

    [head,hattr,prof,pattr,summary] = rtp_cris_subset_hr(head,hattr,prof,pattr,subtest,1);

    if isempty(prof); 
      disp('ERROR: no data returned from rtp_cris_subset. Skipping....'); 
      continue; 
    end  % if no data was returned


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Save Data File
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    mkdirs(dirname(rtpfile))
    disp(['Writing out rtp file: ' rtpfile]);
    rtpwrite(rtpfile,head,hattr,prof,pattr)
    if exist('summary','var')
      save([rtpfile(1:end-3) 'summary.mat'],'-struct','summary')
    end
    clear summary head prof hattr pattr

  end % hour loop

  farewell(rn);

end 




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [head hattr prof pattr] = sdr2rtp_h5_l(f)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read hdf5 file
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  error('This routine is not coded for High Res files!')

  [p pattr]=readsdr_rtp(f{i});

  p.findex = int32(ones(size(p.rtime)) * i);

  % Now change indices to g4 of SARTA
  robs = p.robs1;
  nn = length(p.rlat);
  p.robs1 = zeros(1329,nn);
  p.robs1(inan,:) = NaN;
  % p.robs1(si,:) = robs(pi,:);    % test and implement later
  p.robs1(1:713,:)     = robs(3:715,:);
  p.robs1(714:1146,:)  = robs(720:1152,:);
  p.robs1(1147:1305,:) = robs(1157:1315,:);
  p.robs1(1308:1309,:) = robs(1:2,:);
  p.robs1(1310:1311,:) = robs(716:717,:);
  p.robs1(1316:1317,:) = robs(718:719,:);
  p.robs1(1318:1319,:) = robs(1153:1154,:);
  p.robs1(1324:1325,:) = robs(1155:1156,:);
  p.robs1(1326:1327,:) = robs(1316:1317,:);


  % Declare iudef

  if ~isfield(prof,'iudef')
    prof.iudef = zeros(10,length(prof.rtime));
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Set up Header
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % From g4 variant of CrIS SARTA, in order.
  fm1 = 650:0.625:1095;
  fm2 = 1210:1.25:1750;
  fm3 = 2155:2.5:2550;
  fm4 = 647.5:0.625:649.375;
  fm5 = 1095.625:0.625:1097.5;
  fm6 = 1205.00:1.25:1208.75;
  fm7 = 1751.25:1.25:1755;
  fm8 = 2145.00:2.5:2153.50;
  fm9 = 2552.5:2.5:2560;
  fm = [fm1';fm2';fm3';fm4';fm5';fm6';fm7';fm8';fm9'];

  % Sarta g4 channels that are not in Proxy data 
  inan = [ 1306 1307 1312:1315 1320:1323 1328:1329];


  % Get head.vchan from fm definitions above
  head.ichan = (1:1329)';
  head.vchan = fm;
  head.ptype = 0;
  head.pfields = 5;
  head.ngas = 0;
  head.nchan = length(fm);
  head.pltfid = -9999;
  head.instid = -9999;
  head.vcmax = -9999;
  head.vcmin = -9999;

  hattr = set_attr('header','pltfid','NPP');
  hattr = set_attr(hattr,'instid','CrIS');
  hattr = set_attr(hattr,'rtpfile',rtpfile);
  pattr = set_attr(pattr,'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');

end





function [head hattr prof pattr] = sdr_fixup(head,hattr, prof, pattr);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Demaged file - some CrIS files may 
  % not have rlat,rlon,satzen
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Get rid of negative times
  % 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ikeep = find(prof.rtime > 0 & prof.rtime < 0.5E9);
  if(numel(ikeep)~=numel(prof.rtime))
    disp(['WARNING: There are ' num2str(numel(prof.rtime)-numel(ikeep)) ' bad profiles. Removing them.']);
    prof = structfun(@(x) x(:,ikeep),prof,'UniformOutput',0);
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Fill in fake Lat/Lons
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ( (all(prof.rlat == 0) & all(prof.rlon == 0)) | ... 
       (all(prof.rlat<-900) & all(prof.rlon<-999)) )
    disp('WARNING: Demaged file: All Lats and Lons are invalid.')
    disp('         At one point Paul used geonav_single.m to fix this');
    disp('         but here I won''t do anything special about it...');
%    disp('WARNING: Demaged file: Bad Lat / Lon data, replacing--')
%    prof.rlat(:) = nan; 
%    prof.rlon(:) = nan;
%    isel = find(abs(double(prof.xtrack) - 15.5) < 2);
%    for i = 1:length(isel)
%      geo = geonav_single(iasi2mattime(prof.rtime(isel(i)))-.0003,prof.satzen(isel(i)));
%      prof.rlat(isel(i)) = geo.fovLat(prof.ifov(isel(i)));
%      prof.rlon(isel(i)) = geo.fovLon(prof.ifov(isel(i))); 
%    end
  end

  if(all(prof.rlon < -900)); 
    disp('Warning: Longitudes are bogus')
%    prof.landfrac = zeros(size(prof.rtime));
%    prof.rlon = zeros(size(prof.rtime))+360;
%    prof.rlat = zeros(size(prof.rtime));
  end  % all the latitudes are bogus



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Look for bad lat/lons
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Warn if there are bad lat/lons  
  lbad_loc = (prof.rlat<-1000 | prof.rlon<-1000 | abs(prof.rlat)>90);
  ibad_loc = find(lbad_loc);
  if(numel(ibad_loc)>0)
    disp(['WARNING: there are ' num2str(numel(ibad_loc)) ' bad rlat/rlon points']);
    disp(['         Will remove these profiles...']);
    % This is to catch the data point which have latitude values of -9999 and to keep the
    %   values / fovs we will map them to a equator point that has an invalid rlon point
    % Set these bad locations to 0,360 so that the USGS routine doesn't fail
%    prof.rlat(ibad_loc) = 0;
%    prof.rlon(ibad_loc) = 360;
     igood_loc = find(~lbad_loc);
    prof = structfun(@(x) x(:,igood_loc),prof,'UniformOutput',0);
    disp(['        ... left with ' num2str(numel(igood_loc))]);
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % A proxy for satzen
  % 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if(isfield(prof,'scanang'))
    if(~isfield(prof,'satzen') | all(prof.satzen < -900)) 
      disp('WARNING:  patching satzen - missing or has bad values')
      zang = vaconv(prof.scanang,prof.zobs,prof.salti);
      prof.satzen = 1./cos(deg2rad(zang));
    end
  else
    disp('WARNING:  missing scanang!  approximating satzen');
    prof.satzen = abs(double(prof.xtrack) - 15.5) * 4;
  end

  if isfield(prof,'satazi') & all(prof.satazi < -900)
    prof = rmfield(prof,'satazi');
  end
  if isfield(prof,'solazi') & all(prof.solazi < -900)
    prof = rmfield(prof,'solazi');
  end

  rtime = rtpdate(prof,pattr);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % A trap for missing zobs data, substitute CRiS altitude (correct?)
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ~isfield(prof,'zobs') | all(prof.zobs < 1)
    disp('WARNING: All zobs fields are missing! Using an estimate.');
    prof.zobs = ones(size(prof.rtime)) * 820000;
                                    % or 830610 ????
    pattr = set_attr(pattr,'zobs','CrIS Estimated Altitude');
  end
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % DONE with Demaged file code
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
end




function cris_banks_test_warn_l(head, prof)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Test for bad band banks - Just a warning
  % (junk = number of good banks (0,1,2, or 3) for each profile)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % search for data in all three bands that are not bad
  %idtest2=[499, 731, 1147];
  vctest2=[961.25, 1231.25, 2155.00];
  [ictest2, idtest2] = wn2ch(head, vctest2); 

  rmin = reshape(bt2rad(head.vchan(idtest2),170*ones(size(idtest2))),[3,1]);
  nobs = length(prof.rtime);
  junk = sum(prof.robs1(idtest2,:) > rmin * ones(1,nobs));
  iok = find(junk == 3);
  if(numel(iok)~=numel(junk))
    disp(['WARNING: there are ' num2str(numel(junk)-numel(iok)) ' profiles with at least one bad BANK. Will not do anything!']);
  end



end


function [head hattr prof pattr] = cris_clear_flag_l(head,hattr,prof,pattr)

  disp('running rtpadd_ecmwf');
  try
    [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
  catch err
    Etc_show_error(err);
    say('Error reading ECMWF data... Continuing to the next iteration...');
    return
  end

  if(~isfield(prof,'wspeed')); 
    prof.wspeed = ones(size(prof.rtime)) * 0; 
  end

  disp('adding solar');

  mtime = rtpdate(prof, pattr);
  [prof.solzen prof.solazi] = SolarZenAzi(mtime,prof.rlat,prof.rlon,prof.salti/1000);
  

  disp('adding emissivity');
  dv = datevec(floor(nanmean(mtime)));
  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');


end

