%
%  Runtime function to make CrIS rtp files
%
%  Input: 
%     JOB - matlab datenum indicating the time to be processed
%    
%     rtpset='subset';
%     data_path='/asl/data/cris/sdr60';
%     data_str='_subset';
%     src='_noaa_ops';
%
%  Name is constructe like: ['cris_' data_type data_str src '.yyyy.mm.dd.hh.v1.rtp']
%    data_type = basename(data_path) = sdr60 ; in the example
% 
%  All paths are hardcoded into the function and need to be changed as
%  needed.
%
%  Created: 15 Feb 2011 - Paul Schou
%  Updates: 
%    3 March 2011 - added hour divisions and rtpfile pattr
%    4 March 2011 - padded the cris reader with try/catch with error output
%                   added Scott's uniform test for 3 channels and put the result in udef 13
%     16 Dec 2011 - updates to add to the revision control system
%     30 Dec 2011 - LLS.  Fixed pattr for Reason.  Was set to udef(1,:) 
%                   when it is actually stored in iudef(1,:)
%     01 Jan 2012 - LLS changed zeros(20,...) to zeros(10,...).  
%                   10 = max size for iudef, causing fmatch{} rtp error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence:
%
% 0.1 - **Totaly stupid hard coded JOB date - REMOVE IT!
%         Now simply fail
% 0.2 - go over CrIS pathes
% 0.3 - Make up wavenumber grid
% 0.4 - **Set up this "inan" array for hardcoded bad channels ??
% 0.5 - **define "site_range" like for AIRS??
% 0.6 - version number
% 0.7 - ** setup 'si' and 'pi' index array - NEVER USED
% 0.8 - **IF no data_str, set it to '' ?? will it be an allfovs??
% 0.9 - 
% 
% 3.? - **Weird remapping of bad rlat/rlon. Leave them bad!!

% Set up
% Loop over hours or 0.1*hours (for an allfovs)
  % Search for hdf files
  % Load hdf files and construct the RTP structure
  % Get rid of negative times
  % Fill in fake Lat/Lons -   % Demaged file - some CrIS files may not have rlat,rlon,satzen 
  % A proxy for satzen
  % A trap for missing zobs data, substitute CRiS altitude (correct?)
  % Look for bad lat/lons
  % Add salti and landfrac
  % Refill bad values
  % Set up Header
  % Test for bad band banks - Just a warning
  % Fill ECMWF (and other fields) into the file 
  %  *The subset algorithm seems to need % atmospheric model information.(???)*
  % Perform data subsetting
% Save Data File

cris_paths



rn='rtp_core (cris)';
greetings(rn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Set up
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If no job is specified, go to the test day
if ~exist('JOB','var')
  error('No JOB variable declared');
end


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

site_range = 55.5;  % we 55.5 km for AIRS
version = 'v1';

% These indices not used yet, done explicitely below for now
% Sarta index
si = [1:1305 1308:1311 1316:1319 1324:1327];
% Proxy index
pi = [3:715  720:1152 1157:1315 1:2 716:719 1153:1156 1316:1317];
if ~exist('data_str','var')
  data_str = '';
end

span = 0:23;
if strcmp(rtpset,'full')
  span = 0:24*6-1;
elseif strcmp(rtpset,'full4ch')
  span = 0:23;
elseif strcmp(rtpset,'full49ch')
  span = 0:23;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Loop over hours or 0.1*hours (for an allfovs)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(['Processing ' datestr(JOB(1),'yyyy/mm/dd') ' with version: ' version])
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
  % Search for hdf files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



  disp([' time: ' timestr '  search: '  hourstr '*'])
  disp(['searching: ' data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(floor(mat2jd(JOB(1))),'%03d') '/GCRSO-SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' hourstr '*' src '.h5']);
  f = findfiles([data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(floor(mat2jd(JOB(1))),'%03d') '/GCRSO-SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' hourstr '*' src '.h5']);
  data_type = basename(data_path);
  rtpfile = [prod_dir '/' datestr(JOB(1),26) '/cris_' data_type data_str src '.' datestr(JOB(1),'yyyy.mm.dd') '.' timestr '.' version '.rtp'];
  disp(['  found ' num2str(length(f)) ' GCRSO-SCRIS files'])


  if length(f) == 0
    disp('NO GCRSO-SCRIS files found, trying alternate hash')
    f = findfiles([data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(floor(mat2jd(JOB(1))),'%03d') '/SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' hourstr '*' src '.h5']);
    disp([data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(floor(mat2jd(JOB(1))),'%03d') '/SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' hourstr '*' src '.h5']);
    rtpfile = [prod_dir '/' datestr(JOB(1),26) '/cris_' data_type data_str src '.' datestr(JOB(1),'yyyy.mm.dd') '.' timestr '.' version '.rtp'];
    disp(['  found ' num2str(length(f)) ' SCRIS files'])
  end

  if exist(rtpfile,'file')
    disp(['  RTP File ' rtpfile ' already exists. Skipping....']);
    continue
  end
 
  if length(f) == 0; 
    disp(['WARNING: No CrIS Data Files. Skipping....']);
    continue; 
  end  % no files found = continue to next hour


  disp(['  found ' num2str(length(f)) ' sdr60 files'])
  disp(['  creating ' rtpfile])

  mkdirs(dirname(rtpfile))
  disp(['  output: ' rtpfile])
  if ~lockfile(rtpfile); 
    disp(['WARNING: Lockfile exists for file ' rtpfile '. Skipping....']); 
    continue; 
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Load hdf files and construct the RTP structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  clear prof pattr head hattr
  for i = 1:length(f)
    d = dir(f{i});
    %if(d.bytes < 172281920); disp('file too small'); continue; end
    
    disp(['Reading ' f{i}])

    try
      [p pattr]=readsdr_rtp(f{i});
    catch err
      disp(['ERROR:  Problem reading in file ' f{i}])
      Etc_show_error(err);
      continue
    end

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
    prof(i) = p;
    clear p;
  end % file loop
  
  % if no files were loaded continue on to the next hour
  if ~exist('prof','var')
    disp('No prof structure (no SDR files loaded) ! Skipping');
    continue
  end

  prof=structmerge(prof,2);




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
  % Test if we still have any profiles left
  % 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if(numel(prof.rtime)==0)
    disp(['WARNING: We are left with no profiles. Going to next file...']);
    continue
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
 



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Add salti and landfrac
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ~isfield(prof,'landfrac')
    disp('Adding salti and landfrac');
    [prof.salti, prof.landfrac] = usgs_deg10_dem(prof.rlat, prof.rlon);
  else
    disp('Data seems to already contain landfrac or salti.');
  end

 




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Set up Header
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

  %% Uniform test with different channels
  %pattr = set_attr(pattr,'udef(13,:)','dbt test: ch 401 499 731 {dbtun}');
  %idtest=[401, 499, 731];
  %prof.udef(13,:) = xuniform3(head, prof, idtest);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Test for bad band banks - Just a warning
  % (junk = number of good banks (0,1,2, or 3) for each profile)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % search for data in all three bands that are not bad
  idtest2=[499, 731, 1147];
  rmin = bt2rad(head.vchan(idtest2),repmat(170,size(idtest2)));
  nobs = length(prof.rtime);
  junk = sum(prof.robs1(idtest2,:) > (rmin' * ones(1,nobs)));
  iok = find(junk == 3);
  if(numel(iok)~=numel(junk))
    disp(['WARNING: there are ' num2str(numel(junk)-numel(iok)) ' profiles with at least one bad BANK. Will not do anything!']);
  end


  % Declare iudef

  if ~isfield(prof,'iudef')
    prof.iudef = zeros(10,length(prof.rtime));
  end

  % find the site fovs
  %[isiteind, isitenum] = fixedsite(prof.rlat, prof.rlon, site_range);
  %prof.iudef(1,isiteind) = bitor(prof.iudef(1,isiteind),2);

  % select random fovs
  %irand = find(rand(size(prof.rtime)) < .001);
  %prof.iudef(1,irand) = bitor(prof.iudef(1,irand),8);

  % find the clear fovs
  %bt1231 = rad2bt(head.vchan(731), prof.robs1(731,iok));
  %iclear = iok(abs(prof.udef(13,iok)) < 0.5 & bt1231 > 270);
  %prof.iudef(1,iclear) = bitor(prof.iudef(1,iclear),1);




%  %%  A proxy for solzen for the given orbit
%  if(~isfield(prof,'solzen') | all(prof.solzen < 1000))
%    disp('  patching solzen - missing or has bad values')
%    center_fov = prof.xtrack == 15;
%    lat_dir = diff(prof.rlat(center_fov));
%    sol_zen = ([lat_dir lat_dir(end)] < 0)*90 + 45;
%    %keyboard
%    prof.solzen = reshape(repmat(sol_zen,max(prof.xtrack(:)),1),1,[]);
%  %  prof.solzen = prof.solzen(1:length(prof.rtime));
%  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % The subset algorithm seems to need 
  % atmospheric model information.(???)
  % Fill ECMWF (and other fields) into the file
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  disp('running rtpadd_ecmwf');
  try
    [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
  catch err
    Etc_show_error(err);
    say('Error reading ECMWF data... Continuing to the next iteration...');
    continue
  end

  if(~isfield(prof,'wspeed')); 
    prof.wspeed = ones(size(prof.rtime)) * 0; 
  end

  disp('adding solar');
  [prof.solzen prof.solazi] = SolarZenAzi(rtime,prof.rlat,prof.rlon,prof.salti/1000);
  

  disp('adding emissivity');
  dv = datevec(JOB(1));
  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
 

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Perform data subsetting
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if strcmp(rtpset,'subset')
    subtest = 1;
  elseif strcmp(rtpset,'full4ch')
    subtest = 2;
  elseif strcmp(rtpset,'full49ch')
    subtest = 3;
  else
    subtest = 0; % full
  end

  [head,hattr,prof,pattr,summary] = rtp_cris_subset(head,hattr,prof,pattr,subtest);


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

% END OF SCRIPT

% $$$ % How to load SARTA channel ordering from instrument ordering (SDR files)
% $$$ % si is indexing for Sarta
% $$$ si = [3:715 720:1152  1157:1315];
% $$$ si_n = length(si);
% $$$ % Channel definitions from SARTA
% $$$ si(1308) = 1;
% $$$ si(1309) = 2;
% $$$ si(1310) = 716;
% $$$ si(1311) = 717;
% $$$ si(1316) = 718;
% $$$ si(1317) = 719;
% $$$ si(1318) = 1153;
% $$$ si(1319) = 1154;
% $$$ si(1324) = 1155;
% $$$ si(1325) = 1156;
% $$$ si(1326) = 1316;
% $$$ si(1327) = 1317;
% $$$ siuse = [1308:1311 1316:1319  1324:1327];

% Test Scripts; Use frequency instead of robs1 to test
% $$$ fm_test = zeros(1329,1);
% $$$ fm_test(1:si_n) = ff(si(1:si_n));  % a == fr! up to length(si)
% $$$ fm_test(siuse) = ff(si(siuse));

