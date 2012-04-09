%
%  Runtime function to make CrIS rtp files
%
%  Input: JOB - matlab datenum indicating the time to be processed
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


% If no job is specified, go to the test day
if ~exist('JOB','var')
  JOB = datenum(2011,3,10);
end

cris_paths

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
    
disp(['Processing ' datestr(JOB(1),26) ' with version: ' version])
for hour = 0:23
  disp([' hour ' num2str(hour)])
  disp(['searching: ' data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(mat2jd(JOB(1)),'%03d') '/SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' num2str(hour,'%02d') '*' src '.h5']);
  f = findfiles([data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(mat2jd(JOB(1)),'%03d') '/SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' num2str(hour,'%02d') '*' src '.h5']);
  data_type = basename(data_path);
  rtpfile = [prod_dir '/' datestr(JOB(1),26) '/cris_' data_type data_str src '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.' version '.rtp'];
  disp(['  found ' num2str(length(f)) ' sdr60 files'])
  disp(['  creating ' rtpfile])
  if exist(rtpfile,'file')
    disp('  skipping');
    continue
  end

  if length(f) == 0
    f = findfiles([data_path '/hdf/' datestr(JOB(1),'yyyy') '/' num2str(mat2jd(JOB(1)),'%03d') '/SCRIS_npp_d' datestr(JOB(1),'yyyymmdd') '_t' num2str(hour,'%02d') '*' src '.h5']);
    rtpfile = [prod_dir '/' datestr(JOB(1),26) '/cris_' data_type src '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.' version '.rtp'];
    disp(['  found ' num2str(length(f)) ' sdr4 files'])
  end

  if length(f) == 0; continue; end  % no files found = continue to next hour
  mkdirs(dirname(rtpfile))
  disp(['  output: ' rtpfile])
  if ~lockfile(rtpfile); continue; end

  clear prof pattr head hattr
  for i = 1:length(f)
    d = dir(f{i});
    %if(d.bytes < 172281920); disp('file too small'); continue; end
    disp(['Reading ' f{i}])
try
    [p pattr]=readsdr_rtp(f{i});
catch e
 e
 %keyboard
 disp([' failure reading ' f{i} ]);
 continue % failure reading the file, try the next
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
    continue
  end

  prof=structmerge(prof,2)
  
  % This is to catch the data point which have latitude values of -9999 and to keep the
  %   values / fovs we will map them to a equator point that has an invalid rlon point
  disp([' bad rlat = ' num2str(sum(prof.rlat < -999))])
  bad_loc = abs(prof.rlat) > 999 | abs(prof.rlon) > 999;
  prof.rlat(bad_loc) = 0;
  prof.rlon(bad_loc) = 360;
  disp([' bad rlat = ' num2str(sum(prof.rlat < -999))])

  % Get head.vchan from fm definitions above
  head.ichan = (1:1329)';
  head.vchan = fm;
  head.ptype = 0;
  head.pfields = 5;  % Paul had = 4 here
  head.ngas = 0;
  head.nchan = length(fm);
  head.pltfid = -9999;
  head.instid = -9999;
  head.vcmax = -9999;
  head.vcmin = -9999;

  hattr = set_attr('header','pltfid','NPP');
  hattr = set_attr(hattr,'instid','CrIS');
  hattr = set_attr(hattr,'rtpfile',rtpfile);
  pattr = set_attr(pattr,'udef(13,:)','dbt test: ch 401 499 731 {dbtun}');
  pattr = set_attr(pattr,'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}')

  % Put this back in and subset later once debugged
  idtest=[401, 499, 731];
  prof.udef(13,:) = xuniform(head, prof, idtest);


  % search for data in all three bands that are not bad
  idtest2=[499, 731, 1147];
  rmin = bt2rad(head.vchan(idtest2),170);
  nobs = length(prof.rtime);
  junk = sum(prof.robs1(idtest2,:) > rmin * ones(1,nobs));
  iok = find(junk == 3);

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
  if(all(prof.rlon < -900)); 
    disp('Warning: Longitudes are bogus')
    prof.landfrac = zeros(size(prof.rtime));
    prof.rlon = zeros(size(prof.rtime))+360;
    prof.rlat = zeros(size(prof.rtime));
  end  % all the latitudes are bogus

  if ~isfield(prof,'landfrac')
    disp('no landfrac')
    [prof.salti, prof.landfrac] = usgs_deg10_dem(prof.rlat, prof.rlon);
  end

  % get rid of negative times
  ikeep = prof.rtime > 0 & prof.rtime < 0.5E9;
  prof = structfun(@(x) x(:,ikeep),prof,'UniformOutput',0);

  % This is for the rtp_cris_subset algorithm:
  disp('running rtpadd_ecmwf');
  if(JOB(1) > datenum(2012,1,1))
    [head hattr prof pattr] =rtpadd_gfs(head,hattr,prof,pattr);
  else
    [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
  end

  if(~isfield(prof,'zobs')); prof.zobs = ones(size(prof.rtime)) * 830610; end
  if(~isfield(prof,'wspeed')); prof.wspeed = ones(size(prof.rtime)) * 0; end

  disp('adding emissivity');
  rtime = rtpget_date(prof,pattr);
  dv = datevec(JOB(1));
  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
 
  %  A proxy for solzen for the given orbit
  %if(~isfield(prof,'solzen') | any(prof.solzen < 1000))
  %  center_fov = prof.xtrack == 15;
  %  lat_dir = diff(prof.rlat(center_fov));
  %  sol_zen = ([lat_dir(1) lat_dir lat_dir(end)] < 0)*90 + 45;
  %keyboard
  %  prof.solzen = reshape(repmat(sol_zen,15,1),1,[]);
  %  prof.solzen = prof.solzen(1:length(prof.rtime));
  %end



  if(isfield(prof,'scanang'))
    if(~isfield(prof,'satzen')) 
      zang = vaconv(prof.scanang,prof.zobs,prof.salti);
      prof.satzen = 1./cos(deg2rad(zang));
    end
  else
    prof
    disp('  missing scanang!');
  end



  try
  [head,hattr,prof,pattr,summary] = rtp_cris_subset(head,hattr,prof,pattr,strcmp(rtpset,'subset'));
  catch e
    e
    %keyboard
  end
  if isempty(prof); disp('ERROR: no data returned'); continue; end  % if no data was returned


  % A trap for missing zobs data, substitute CRiS altitude (correct?)
  if ~isfield(prof,'zobs') | all(prof.zobs < 1)
    prof.zobs = ones(size(prof.rtime)) * 820000;
    pattr = set_attr(pattr,'zobs','CrIS Estimated Altitude');
  end

  %[head hattr prof pattr] = rtpadd_ecmwf_data(head, hattr, prof, pattr);
  mkdirs(dirname(rtpfile))
  disp(['Writing out rtp file: ' rtpfile]);
  rtpwrite(rtpfile,head,hattr,prof,pattr)
  if exist('summary','var')
    save([rtpfile(1:end-3) 'summary.mat'],'-struct','summary')
  end
  clear summary head prof hattr pattr

end % hour loop


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

