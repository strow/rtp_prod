function gs = gstats(gtops,outfile);
%--- Global Statistics for RTP files ---
% function gs = gstats(gtops,outfile);
%
% Calculate radiance (not BT) stats from RTP granules specified
% by gfile.  Variables set in the "default selection parameters"
% section can be reset by passing them in as fields in the gtops
% structure.  This routine returns a separate bin for secant
% angle as well as water (ie num_water_bins*num_angle_bins).
% FOVs are selected using "PROF.clrflag" and then running a clear
% test.  Works with pt1 or pt2 files (default gtops.iok for pt1).
% 
%
%  Inputs:
%    gtops      - structure of optional selection parameters (see list below)
%
% Output: (gs structure fields)
%    npro    - total number of profiles selected per bin
%    count   - total number of profiles selected per channel per bin
%    robs1_avg  - mean observed rad
%    robs1_std  - std observed rad
%    rcalc_avg  - mean calculated rad
%    rcalc_std  - std calculated rad
%    stemp_avg  - mean surface temperature per bin
%    stemp_std  - stdev surface temperature per bin
%    gtotal_avg    - mean gas column total per bin
%    gtotal_std  - stdev gas column total per bin
%    ang_avg  - mean secant angle per bin [secant]
%    ang_std  - stdev secant angle per bin [secant]
%    rlat_avg  - mean latitude per bin
%    rlat_std  - stdev latitude per bin
%    rtime_avg  - mean time per bin
%    rtime_std  - stdev time per bin
% Optional outputs, provided if specified in inc_fields, ie: inc_fields = {..., 'rlon'}
%    rlon_avg  - mean longitude per bin
%    rlon_std  - stdev longitude per bin
%
% Selection parameters for gtops:
%    filter       - matlab code for a filter, eg: 'prof=filter_name(head,prof)'  default: ''
%    klayers      - matlab to run klayers filter code before stats, default: 
%                   '[head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr)'
%    filemask     - filter for file selection, can be a string or multiple strings in cells
%    inc_fields   - cell array of fields to consider in stats, note: when using field names
%                   such as {'rlat','rtime'} and only a avg is required use: {'rlat_avg','rtime_avg'}
%    iok          - desired channel indices {default=all}
%    jac          - structure with jacobian setup details, skip if empty {default=[]}
%       .sarta    - sarta executable for jacobian computation
%    secang_bins  - allowed secant angle {ie: [1 1.94]}
%    scanang_bins - allowed scan angle {ie: [1 1.94]}
%    solzen_bins  - allowed solar zenith angle {ie: [0 180]}
%    mmw_bins     - bin boundaries for mm of water {ie: [0 40]}
%    ang_bins     - bin boundaries for secant {ie: [1 1.94]}
%    rlat_bins    - bin boundaries for latitude {ie: [-90,90]}
%    rlon_bins    - bin boundaries for longitude {ie: [-180,180]}
%    fov_bins     - fov selections {default=[] which means all in one}
%    landfrac_bins- allowed land fraction {ie: [0 1]};
%    stemp_bins   - allowed SST (ie prof.stemp) {ie: [100 inf]}
%    calflag_bit  - which bit to allow to pass {default 0, NaN to disable}
%    site_bins    - num of a site to select (last bin is ignored) {ie: [1 2 nan]}
%    siterad_bins - site radius of selection in degrees {default 5}
%    transcom_bins - bin by the transcom bins for the regions {normal 0:23}
%   --Dynamic selection bins/filters by channel--
%    robs1_id#_bins - bin by robs1 channel id #
%    rcalc_id#_bins - bin by rcalc channel id #
%    bto_id#_bins   - bin by bt_obs1 channel id # {ie: gt.bto_id2333_bins=270:5:305}
%    btc_id#_bins   - bin by bt_calc channel id #
%    dbt_id#_bins   - bin by delta bt (obs - calc) channel id #
%   --Checking output values--
%    debug        - set to 1 to enable debug output in stats structure

% obsolete fields - changed from hard code to soft coded fields, see above
%    dbtsst_bins  - max allowed udef(17) for clouds {default []}
%    dbtq_bins    - min allowed udef(18) for low clouds {default []}
%       note: dbtq may be negative if cloudy or temperature inversion
%    dbt820_bins  - max allowed udef(19) for cirrus {default []}
%    dbt960_bins  - max allowed udef(20) for dust {default []}

% Written by Paul Schou 2010
% Updated: 28 June 2011 to automatically detect problems in rtp header gas sizes and remove missing gasses

if exist('jac','dir')
end

% ----------------------------
% default selection parameters
% ----------------------------

% selection chriteria for files
gt.filemask = [];

% channel index selection subset, [] = all
gt.iok = [];

% jacobian setup
gt.jac=[];

% custom filter name
gt.filter=[];
gt.klayers='[head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr)';

% site setup
gt.site_bins = [];
gt.siterad_bins = [];
[slat slon] = fixedsite();

% Default clear test dbt* values
gt.dbt_bins = [];
gt.dbtsst_bins = [];
gt.dbtq_bins   = [];
gt.dbt820_bins = [];
gt.dbt960_bins = [];
gt.reason_bins = [];
gt.clear_bins = [];
gt.dbt1231_bins = [];
gt.clrflag_bins = [];

% solar zenith angle selection
gt.solzen_bins = [];

% latitude & longitude selection
gt.rlat_bins = [];
gt.rlon_bins = [];
gt.xtrack_bins = [];
gt.atrack_bins = [];
gt.xtrack_eo_bins = [];

% fov selection
gt.fov_bins = [];

% scan angle selection [secant]
gt.scanang_bins = [];

% secant angle selection [secant]
gt.secang_bins = [];

% calflag bit
gt.calflag_bit = 0;

% wspeed bins
gt.wspeed_bins = [];

% total precipitable water selection
%gt.mmw_bins = [];
%gt.mmw_udef  = -1;                % -1 for none

% surface temperature selection
gt.stemp_bins =[];  % bin boundaries

% Land fraction
gt.landfrac_bins = [];

% Surface altitude bins
gt.salti_bins = [];

% Emissivity minimum bins
gt.emismin_bins= [];

gt.ifov_bins = [];

gt.debug = [];

% ----------------------------
% User specific requirements
% ----------------------------

img = sqrt(-1);

% set default gstats fields if not set
if isfield(gtops,'inc_fields')
  inc_fields = sort(gtops.inc_fields);
  %gtops = rmfield(gtops,'inc_fields');
else
  inc_fields = {'stemp_avg','rtime_avg','robs1','rcalc'};
end    
gtops.inc_fields = inc_fields;


% option to override defaults with gtops fields
if nargin > 0
  optvar = fieldnames(gtops);
  for i = 1 : length(optvar)
    vname = optvar{i};
    if isfield(gt, vname) | strcmp(vname(max(1,end-4):end),'_bins')
      if ~isfield(gt, vname); disp(['  setting non standard field ' vname]); end
      gt.(vname) = trim(getfield(gtops, vname));
      if (strcmp(vname,'iok'))
        disp(['gtops.iok: length=' int2str(length(gt.iok)) ...
        ', min=' int2str(min(gt.iok)) ', max=' int2str(max(gt.iok))])
      elseif isnumeric(getfield(gt, vname))
        disp(['gt.' vname ' = ' num2str(getfield(gt, vname))])
      else
        disp(['gt.' vname ' = '])
        if isstruct(getfield(gt, vname))
          getfield(gt, vname)
        else
          disp(strvcat(getfield(gt, vname)))
        end
      end
    else
      fprintf(1, '  Warning::  Unknown option or range %s\n', vname);
    end
    pause(0.2)
  end
end
gt.inc_fields = inc_fields;
if ~isempty(gt.debug)
  gt.debug = struct;
end

% Fill in the site if the given is a site number
%if size(gt.site,2) == 2
%  [slat slon] = fixedsite();
%  site_n = gt.site(:,1);
%  gt.site = [slat(gt.site(:,1)) slon(gt.site(:,1)) double(gt.site(:,2))];
%  for nn = 1:size(gt.site,1)
%    disp(['    site #' num2str(site_n(nn)) '   ' num2str(gt.site(nn,1)) 'x' num2str(gt.site(nn,2))])
%  end
%end

% ----------------------------
% Index and fold the bins
% ----------------------------

% Get all the selection fields from the gt structure
gt_names = fieldnames(gt);
sel_names = gt_names(find(~cellfun(@isempty,regexp(gt_names,'_bins$'))));
nbins = 1;

% Fold the selection fields together
disp('/---------- FOLDING ----------\'); fold=0;
for i = 1:length(sel_names)
  len = length(getfield(gt,sel_names{i}));
  %if(len == 1); error(['Invalid selection range for ' sel_names{i} ', must either be empty or 2+ bins']); end
  if(len < 2); len = 2; end  % if we don't have any selection chriteria, skip field

  % begin by folding the previous bins
  for j = 1:i-1
    gt = setfield(gt,[sel_names{j}(1:end-5) '_sel'],repmat(getfield(gt,[sel_names{j}(1:end-5) '_sel']),[1 len-1]));
  end
  % finish by making the current bin and size it appropriately
  nbins = nbins * (len - 1);
  temp = trim(repmat(1:len-1,[nbins/(len-1) 1]));
  gt = setfield(gt,[sel_names{i}(1:end-5) '_sel'],reshape(temp,[1 nbins]));
  if len > 2
    fold = fold + 1;
    disp(sprintf('(%d)%22s = %d',fold,['number of ' sel_names{i}(1:end-5) ' bins'], len-1));
    inc_fields = union(inc_fields,[sel_names{i}(1:end-5) '_avg']); % make sure we are returning all subsets
  end
end
disp('\-----------------------------/')
disp(sprintf('%25s = %d','Total bins', nbins));

% save the gtops to the return gs structure
gs.gtops = orderfields(gt);
% clean up the empty bins and single selections from the return
for i = 1:length(sel_names)
  if isempty(getfield(gs.gtops,sel_names{i}))
    gs.gtops = rmfield(gs.gtops,sel_names{i});
  end
  if max(getfield(gs.gtops,[sel_names{i}(1:end-5) '_sel'])) == 1
    gs.gtops = rmfield(gs.gtops,[sel_names{i}(1:end-5) '_sel']);
  end
end

% ----------------------------
% File selection mask
% ----------------------------

% Run through a file selection:
files = [];
if iscell(gt.filemask)
  for i = 1:length(gt.filemask)
    files = [files findfiles(gt.filemask{i})];
  end
elseif isstr(gt.filemask)
  files = findfiles(gt.filemask);
end
gs.gtops.mfile = [mfilename('fullpath') '.m'];
gs.gtops.files = files;

% check to make sure that files were selected
if length(files) == 0
  disp('  Warning: No files selected');
  return;
end

% ----------------------------
% Loop over the files
% ----------------------------

% Total up the size of the files to estimate runtime
total_bytes = 0;
for ic=1:length(files)
  t = dir(files{ic});
  total_bytes = total_bytes + t.bytes;
  gs.gtops.file_modified(ic) = t.datenum;
end
start_time = datenum(clock);
cur_bytes = 0;

disp(['outfile: ' outfile])
if nargin == 2 & exist(outfile,'file')
  %%% fast way to get things done!
  %  exit
  %%
  disp('Found existing outfile, loading file modified times:');
  gs2 = load(outfile,'gtops','rcalc_count','robs1_count');
  %disp(datestr(gs2.gtops.file_modified))
  %disp('new:')
  %disp(datestr(gs.gtops.file_modified))
  match = 1;
  if isfield(gs2,'robs1_count') & isfield(gs2,'rcalc_count')
    if ~isequal(gs2.rcalc_count,gs2.robs1_count)
      disp('  The counts don''t match, will regenerate')
      match = 0;
    else
      disp('  The counts match')
    end
  else
    disp('  The counts are missing, will regenerate')
    match = 0;
  end
  if isfield(gs2,'gtops') & isstruct(gs2.gtops) & isfield(gs2.gtops,'file_modified') & isequal(gs.gtops.file_modified,gs2.gtops.file_modified)
    disp('Times match -- checking gtops fields...')
    gt_fields = union(fieldnames(gtops),fieldnames(gs2.gtops));
    %gtops 
    %gs2.gtops
    for i = 1:length(gt_fields)
      fname = gt_fields{i};
      if ~isfield(gtops,fname) & strcmp(fname(max(1,end-4):end),'_bins'); 
        disp(['  Bin criteria changed: new gtops does not have ' fname ' will regenerate']); 
        match = 0; continue; end
      if ~isfield(gs2.gtops,fname) & strcmp(fname(max(1,end-4):end),'_bins'); 
        disp(['  Bin criteria changed: old gtops does not have ' fname ' will regenerate']); 
        match = 0; continue; end
      if ~isfield(gtops,fname); disp(['  warning: new gtops does not have ' fname]); continue; end
      if ~isfield(gs2.gtops,fname); disp(['  warning: old gtops does not have ' fname]); continue; end
      if ~isequalwithequalnans(getfield(gtops,fname),getfield(gs2.gtops,fname))
        disp(['  Fields mismatch in ' fname ' will regenerate'])
        match = 0; end
    end
    if match == 1
      exit  % the files have not changed, so skip updating the stats
    end
  end
  disp('Unmatched, continuing to create new stat file')
end

count =  zeros([1 nbins],'uint16');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for f = 1:length(files) % main file loop
  fname = files{f};

  % If file does not exist
  if ~exist(fname, 'file')
    disp(['Skipping missing file: ' fname])
    continue % main file loop
  end

  % Time estimation clause
  fstats = dir(fname);
  d_time = datenum(clock) - start_time; % delta time
  try
    est_time = '00:00:00  EST_TIME  REMAINING_TIME';
    if(i > 1) est_time = [datestr(d_time,13) '  ' ...
                datestr(d_time/cur_bytes*(total_bytes),13) '  ' ...
                datestr(d_time/cur_bytes*(total_bytes - cur_bytes),13)];
    end
  catch; end;
  cur_bytes = cur_bytes + fstats.bytes;
  disp([basename(fname) 9 '[' num2str(f) '/' num2str(length(files)) ']  ' est_time])


  % Read the RTP file into memory
  try
    [head, hattr, prof, pattr] = rtpread_12(fname);
    %ud = prof.iudef;
    %if any(prof.iudef(1,:) > 0);
    %  disp('  Using iudef(1,:) for reason');
    %  ud = prof.iudef;
    %else
    %  disp('  Warning: using udef(1,:) instead of iudef for reason');
    %  ud = prof.udef;
    %end
    fname2 = '';
    rtpfile = get_attr(hattr,'rtpfile');

%%XXXXXXXXXXXXX HACKS FOR BAD FILES
    if strcmp(rtpfile,'rtpname')
      disp('  WARNING XXX resetting parent for missing rtpfile variable in rtp file');
      bn=basename(fname);
      dn=dirname(fname);
      rtpfile = [dn bn(9:end)];
      hattr = set_attr(hattr,'rtpfile',rtpfile);
    end

    if length(rtpfile) == 0
      disp('  WARNING XXX resetting parent for missing string in rtp file');
      bn=basename(fname);
      dn=dirname(fname);
      hattr = set_attr(hattr,'rtpfile',['/asl/data/rtprod_airs/' dn(31:end) '/' bn(6:end-1)]);
    end

    if strcmp(rtpfile(1:min(end,8)),'/scratch')
      disp('  WARNING XXX resetting parent for bad rtp file');
      bn=basename(fname);
      dn=dirname(fname);
      hattr = set_attr(hattr,'rtpfile',[dn '/' bn(9:end-1)]);
    end
%%XXXXXXXXXXXXX HACKS FOR BAD FILES END
    [head, hattr, prof, pattr] = rtpgrow(head, hattr, prof, pattr,dirname(fname));
    if ~isfield(prof,'robs1'); disp(['  Missing robs1 - skipping ' fname]); continue; end
%    if strcmp(fname(end),'1') & exist([fname(1:end-1) '2'],'file')
%      fname2 = [fname(1:end-1) '2'];
%    end
%    if strcmp(fname(end-1:end),'1Z') & exist([fname(1:end-2) '2Z'],'file')
%      fname2 = [fname(1:end-2) '2Z'];
%    end
%    if ~isempty(fname2)
%      [head2, hattr2, prof2, pattr2] = rtpread(fname2);
%      [head2, hattr2, prof2, pattr2] = rtpgrow(head2, hattr2, prof2, pattr2);
%      if isfield(prof,'rcalc'); prof.rcalc = [prof.rcalc;prof2.rcalc]; end
%      if isfield(prof,'robs1'); prof.robs1 = [prof.robs1;prof2.robs1]; end
%      if isfield(prof,'calflag'); prof.calflag = [prof.calflag;prof2.calflag]; end
%      if isfield(head,'ichan'); head.ichan = [head.ichan;head2.ichan]; end
%      if isfield(head,'vchan'); head.vchan = [head.vchan;head2.vchan]; end
%      if isfield(head,'nchan'); head.nchan = head.nchan + head2.nchan; end
%      clear head2 hattr2 prof2 pattr2
%    end
    gs.gtops.rtp_sarta = get_attr(hattr,'sarta');
    gs.gtops.rtp_sarta_exec = get_attr(hattr,'sarta_exec');
    gs.gtops.rtp_klayers = get_attr(hattr,'klayers');
    gs.gtops.rtp_klayers_exec = get_attr(hattr,'klayers_exec');
    if length(gs.gtops.rtp_klayers_exec) == 0
      disp('  WARNING: Missing klayers_exec, using airs wetwater default');
      gs.gtops.rtp_klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs';
    end
    if isfield(prof,'rcalc') & isfield(prof,'robs1') & size(prof.rcalc,2) ~= size(prof.robs1,2)
      disp('  ERROR:  rcalc and robs1 have different nfov');
      continue;
    end

  catch e
    e.stack
    keyboard
    disp(['Error reading or growing file: ' fname])
       failed = fopen(['~/badfiles.txt'],'a');
       fwrite(failed,[fname 10],'char');
       fclose(failed);
    continue
  end
  
  % remove gas numbers if they don't exist in the profile structure
  if isfield(head,'glist')
    for gnum = head.glist'
      if ~isfield(prof,['gas_' num2str(gnum)])
        head.gunit = head.gunit(head.glist ~= gnum);
        head.glist = head.glist(head.glist ~= gnum);
        head.ngas = head.ngas - 1;
      end
    end
  end

  % user defined filter
  if ~isempty(gt.filter)
    before_nobs = length(prof.rtime);
    disp(['  Filtering with ' gt.filter '...'])
    eval([gt.filter ';']);
    after_nobs = length(prof.rtime);
    disp(['    before filter ' num2str(before_nobs) ' after filter ' num2str(after_nobs)])
    clear before_nobs after_nobs
  end

  if length(prof.rtime) == 0; continue; end
  if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error(['  Stats Error: rcalc missing after executing ' gt.filter]); end

  % site subset filter
  if ~isempty(gt.site_bins)
    disp(['  Subsetting with site'])
    before_nobs = length(prof.rtime);
    clear new_prof;
    for i = 1:length(gt.site_bins)-1
      s_dist = distance(slat(gt.site_bins(i)),slon(gt.site_bins(i)),prof.rlat,prof.rlon);
      plist = find(s_dist <= gt.siterad_bins(end));

      % skip site if no data
      if length(plist) == 0; %disp('    no fovs left');
        continue; end

      % setup the site rtp fields
      [tmp_head, tmp_prof]=subset_rtp(head, prof, [], [], plist);
      tmp_prof.site = repmat(double(gt.site_bins(i)),[1 length(plist)]);
      tmp_prof.siterad = s_dist(plist);

      % merge the results
      new_prof(i) = tmp_prof;
      clear tmp_prof;
      % REMOVE ME -- debug lines
      %plist
      %s_dist(plist)
      %load coast
      %plot(tmp_prof.rlon,tmp_prof.rlat,'.',slon(gt.site_bins(i)),slat(gt.site_bins(i)),'x',long,lat,'-')

      
      %keyboard
      %pause
    end
    if ~exist('new_prof','var'); disp('    no profiles left'); continue; end
    prof=structmerge(new_prof,2);

    site = prof.site;
    siterad = prof.siterad;

    disp(['    before site selection ' num2str(before_nobs) ' after ' num2str(length(prof.rtime))])
    inc_fields = union(inc_fields,{'rlat_avg' 'rlon_avg' 'siterad_avg'}); % make sure we are returning lat/lon
  end

  if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error('  Stats Error: rcalc missing after doing site selection'); end
  if length(prof.rtime) == 0; continue; end

  % klayers filter
  %ud = prof.udef;
  if ~isfield(gtops,'skip_calc') & mod(head.pfields,2) == 1 & ~isempty(gt.klayers)

    disp(['  running klayers filter: ' gt.klayers]);
    eval([gt.klayers ';']);
    %[head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr);
    prof.gtotal = single(totalgas_rtp(head.glist, head, prof));
  end

  %prof.udef = ud;
  if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error(['  Stats Error: rcalc missing after executing ' gt.klayers]); end
  if length(prof.rtime) == 0; continue; end

  % save some memory
  if isfield(prof,'rcalc'); prof.rcalc = single(prof.rcalc); end
  if isfield(prof,'robs1'); prof.robs1 = single(prof.robs1); end

  % restore the site field
  if ~isempty(gt.site_bins)
    prof.site = site;
    prof.siterad = siterad;
  end


  disp('  Processing...')

  % define the frequency and channel selection (if not already defined)
  if ~exist('iok','var')
    iok = trim(1:length(head.vchan));
    gs.gtops.iok = iok;
  end
  niok = length(iok);
  if ~exist('freq','var'); freq = head.vchan(iok); end  % load the frequencies from the head structure
  if ~isfield(gs.gtops,'freq'); gs.gtops.freq = (freq); end  % store the frequencies in the gtops structure
  if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error('  Stats Error: rcalc missing!'); end

  % use calflag to clean the data:
  if isfield(prof,'robs1') 
    if isfield(prof,'calflag') & ~isnan(gt.calflag_bit)
      prof.robs1(prof.robs1 < -100) = nan;
      
      % trim down the calflag if it's dimensions are larger than robs1
      if size(prof.calflag,1) > size(prof.robs1,1)
        prof.calflag=prof.calflag(1:size(prof.robs1,1),:);
      end
      
      % filtering by calflag if the calflag attributes have bits1-4 assigned by Scott's calnum
      if isequal(size(prof.calflag),size(prof.robs1));
        cf_attr = get_attr(pattr,'calflag');
        if strcmp(cf_attr(1:min(end:5)),'image')
          disp('  skipping calflag as it is an image');
        elseif strcmp(cf_attr(1:min(end,10)),'bits1-4=NE')
          prof.robs1(prof.calflag >= 64) = nan; 
          disp('  filtering by calflag >= 64')
        elseif isfield(gtops,'nocalflag')
          disp('  skipping calflag bit')
        else
          prof.robs1(prof.calflag ~= gt.calflag_bit) = nan; 
          disp('  filtering by calflag bit')
        end
      else
        size(prof.calflag)
        size(prof.robs1)
        error('  GSTATS: sizes differ between calflag and robs1')
      end
    elseif ~exist('warn_robs_calflag') % we really should be using the calflag
      disp('  Warning: robs1 requested, but no calflag filter used.')
      warn_robs_calflag = 1; % supress further warnings
    end
    prof.robs1(prof.robs1 == 0 | (prof.robs1 < -100)) = nan;  % what to do with fake channels

    % clean up any noisy data from the calcs when it is bad in the obs
    %if isfield(prof,'rcalc') 
    %  prof.rcalc(isnan(prof.robs1)) = nan; % set all rcalc to nans in robs1
    %end
  end

try
  %%%%%%
  %
  %  In this section we will work on setting up the dataset based on what is requested in 
  %    the gtops.  This is done by finding what fields are needed and producing them in the
  %    prof structure for later statistics.
  %
  %%%%%%
  % fill in needed missing fields based on calculations
  gt_fields = union(fieldnames(gt),inc_fields);
  for i = 1:length(gt_fields);
    field = gt_fields{i}; 
    if length(field) > 5 && strcmp(field(end-4:end),'_bins'); 
      % if a bin selection is not in the gtops or it is empty lets continue
      if ~isfield(gt,field) | isempty(getfield(gt,field)); continue; end
      field = field(1:end-5); % remove the _bins from the name
    end
    if length(field) > 4 && strcmp(field(end-3:end),'_avg'); field = field(1:end-4); end
    if isfield(prof,field); continue; end  % if we already have this field, then let's continue

    if field(end) >= '0' & field(end) <= '9'
      if strcmp(field(1:min(8,end)),'robs1_id')
        prof.(field) = reshape(prof.robs1(str2num(field(9:end)),:),1,[]);
      elseif strcmp(field(1:min(8,end)),'rcalc_id')
        prof.(field) = reshape(prof.rcalc(str2num(field(9:end)),:),1,[]);
      elseif strcmp(field(1:min(6,end)),'bto_id')
        prof.(field) = reshape(rad2bt(head.vchan(str2num(field(7:end))),prof.robs1(str2num(field(7:end)),:)),1,[]);
      elseif strcmp(field(1:min(6,end)),'btc_id')
        prof.(field) = reshape(rad2bt(head.vchan(str2num(field(7:end))),prof.rcalc(str2num(field(7:end)),:)),1,[]);
      elseif strcmp(field(1:min(6,end)),'dbt_id')
        prof.(field) = reshape(rad2bt(head.vchan(str2num(field(7:end))),prof.robs1(str2num(field(7:end)),:)) - ...
          rad2bt(head.vchan(str2num(field(7:end))),prof.rcalc(str2num(field(7:end)),:)),1,[]);
      end
    end

    switch field
      % brightness temperatures calculations
      case 'btobs1'; if isfield(prof,'robs1'); prof.btobs1 = real(rad2bt(freq, prof.robs1)); end
      case 'btcalc'; if isfield(prof,'rcalc'); prof.btcalc = real(rad2bt(freq, prof.rcalc)); end
      case 'dbt'; if isfield(prof,'rcalc') & isfield(prof,'robs1')
        if ~isfield(prof,'btcalc') & length(freq) == size(prof.rcalc,1);
          prof.btcalc = real(rad2bt(freq, prof.rcalc)); end
        if ~isfield(prof,'btobs1'); prof.btobs1 = real(rad2bt(freq, prof.robs1)); end
        prof.dbt = prof.btobs1 - prof.btcalc; end
      % other filters for calculations
      %case 'dbt1231'; 
      %  for iu = 1:20
      %    if strcmp(get_attr(pattr,['L1bCM udef(' num2str(iu) ',:)']),'cx1231')
      %      prof.dbt1231 = prof.udef(iu,:);
      %      break;
      %    elseif strcmp(regexp(get_attr(pattr,['udef(' num2str(iu) ',:)']),'{\w+}','match'),'{dbt1231u}')
      %      prof.dbt1231 = prof.udef(iu,:);
      %      break
      %    end
      %  end
      %case 'dbtsst'; 
      %  for iu = 1:20
      %    if strcmp(get_attr(pattr,['L1bCM udef(' num2str(iu) ',:)']),'dbtsst')
      %      prof.dbtsst = prof.udef(iu,:);
      %      break
      %    elseif strcmp(regexp(get_attr(pattr,['udef(' num2str(iu) ',:)']),'{\w+}','match'),'{dbtsst}')
      %      prof.dbtsst = prof.udef(iu,:);
      %      break
      %    end
      %  end
      %case 'dbtq';   if any(abs(prof.udef(18,:)) < 9999); prof.dbtq = prof.udef(18,:); end
      %case 'dbt820'; if any(abs(prof.udef(19,:)) < 9999); prof.dbt820 = prof.udef(19,:); end
      %case 'dbt960'; if any(abs(prof.udef(20,:)) < 9999); prof.dbt960 = prof.udef(20,:); end
      case 'reason';
        reason = getudef(prof,pattr,'reason');
        if ~isempty(reason); prof.reason = reason; clear reason; end
        %for iu = 1:20
        %  if strcmp(get_attr(pattr,['L1bCM udef(' num2str(iu) ',:)']),'reason bitflags [1=clear,2=site,3=cloud,4=random]') ...
        %      & all(prof.udef(iu,:) >= 0) & isequal(prof.udef(iu,:),uint16(prof.udef(iu,:)))
        %    disp('  Using udef(1,:) for reason (L1bCM)');
        %    prof.reason = prof.udef(iu,:);
        %    break
        %  elseif strcmp(regexp(get_attr(pattr,['iudef(' num2str(iu) ',:)']),'{\w+}','match'),'{reason_bit}') ...
        %      & all(prof.iudef(iu,:) >= 0) & isequal(prof.udef(iu,:),uint16(prof.iudef(iu,:)))
        %    disp('  Using iudef(1,:) for reason_bit');
        %    prof.reason = prof.iudef(iu,:);
        %    break
        %  elseif strcmp(regexp(get_attr(pattr,['udef(' num2str(iu) ',:)']),'{\w+}','match'),'{reason}') ...
        %      & all(prof.udef(iu,:) >= 0) & isequal(prof.udef(iu,:),uint16(prof.udef(iu,:)))
        %    disp('  Using udef(1,:) for reason');
        %    prof.reason = prof.udef(iu,:);
        %    break
        %  end
        %end
        if ~isfield(prof,'reason')
         if isfield(prof,'iudef') & any(prof.iudef(1,:) > 0);
          disp('  Warning: Using iudef(1,:) for reason');
          prof.reason = prof.iudef(1,:);
         elseif isfield(prof,'udef')
          disp('  Warning: using udef(1,:) instead of iudef for reason');
          prof.reason = prof.udef(1,:);
         else
          disp('  Warning: no reason bin, but reason binning was requested');
          exit;
         end
        end
        prof.reason(prof.reason < 0) = 0; % clear out the negatives
        if any(isnan(prof.reason(:))) | any(double(prof.reason(:)) < 0)
          error('  Reason bin has non valid values, are you sure you want to bin by reason?');
        end
        if isfield(gt,'reason_bins') & length(gt.reason_bins) == 1
          %disp(['  reason count: ' num2str(sum(prof.reason > 0)) ' ' num2str(length(find(prof.reason== 1))) ' ' num2str(length(find(bitand(prof.reason,1))))])
          %prof.reason = bitand(double(prof.reason),double(gt.reason_bins));
          prof.reason = bitget(double(prof.reason),double(gt.reason_bins))*double(gt.reason_bins);
          %keyboard
        end
      %case 'clear'; prof.clear = bitand(prof.udef(1,:),1);  %deprecated for iudef get attr method
      case 'xtrack_eo'
        prof.xtrack_eo = mod(prof.xtrack,2);
      case 'transcom'
        load TranscomRegionMatrix
        ii = sub2ind(size(RegionMatrix),max(1,min(180,round(-prof.rlat+89.5))),mod(round(prof.rlon-0.5),360)+1);
        prof.transcom = RegionMatrix(ii);
      case 'emismin'; 
        if isfield(prof,'emis')
          prof.emismin = min(prof.emis,[],1);
        else
          disp('  Warning: emismin requested but emis doesn''t exist in rtp file');
        end
      case 'secang';
        if isfield(prof,'satzen')
          % Check satzen is plausible
          if any(prof.satzen(:) > 90.001)
            disp('RTP file contains invalid prof.satzen data, skipping...')
            continue;
          end
          prof.secang = 1.0./cos(prof.satzen*pi/180); % convert satzen to secang
        end
      case 'mmw'
        % water selection
        if (isfield(gt,'mmw_udef') & gt.mmw_udef > 0) % & gt.mmw_udef <= head.nudef)
          if ~isempty(gt.mmw_bins)
            iwat = find(head.glist == 1);
            nlevs = 91;
            if gt.mmw_udef > 0 & isfield(prof,'udef')
              prof.mmw = prof.udef(gt.mmw_udef,:);
            elseif (isfield(prof,'gtotal'))
              prof.mmw = prof.gtotal(iwat,:);
            else
              prof.mmw = 20*ones(1,length(prof.rtime));
            end
          end
        else
          % Run klayers and then calc total water
          prof.mmw = mmwater_rtp(head,prof);
        end
      otherwise
        if ~strcmp(field(max(1,end-3):end),'_sel') & ...
	     ~strcmp(field(max(1,end-3):end),'_bit')
	  tmp = getudef(prof,pattr,field);
          if ~isempty(tmp);
	    prof.(field) = tmp;
            clear tmp;
          else
            disp(['  Warning: Unknown field, ' field]);
          end
        end
    end
  end
catch e; e
  e.message
  keyboard; 
  disp(['error point 1 ' outfile])
  continue
end

  %%%%%%%% BEGIN Selection Filters %%%%%%%%
  %                                       %
  ibin = []; gtbin = [];

  % super dynamic field selection routine, works on any 1-D prof field
  %  this works by looking at the fields in prof and searching for fields of the same 
  %  name in gtops (adding the _bins suffix).  So if one needs to add additional criteria
  %  for stats, they just need to add fields to the gtops above.

  all_fields = fieldnames(prof);
  for j = 1:length(all_fields)
    if isfield(gt,[all_fields{j} '_bins']) && ~isempty(getfield(gt,[all_fields{j} '_bins']))
      [junk tmp] = histc(amax(getfield(prof,all_fields{j})),getfield(gt,[all_fields{j} '_bins']));
      if length(getfield(gt,[all_fields{j} '_bins']))
        tmp(abs(amax(getfield(prof,all_fields{j}))) >= 9999) = 1; % what to do about no values
      end
      ibin = [ibin;min(tmp,nbins)];
      gtbin = [gtbin;getfield(gt,[all_fields{j} '_sel'])];
      if ~any(ibin(end,:)); 
        disp(['  Warning: ' all_fields{j} '_bins selected no data']); 
      elseif ~all(ibin(end,:)); 
        disp(sprintf('  Warning: %s_bins selection excluded %d profs',all_fields{j},sum(ibin(end,:) == 0)));
      end
      if ~any(all(ibin,1)); disp(['  Warning: After indexing ' all_fields{j} ' all ' num2str(size(ibin,2)) ' bins are now empty']); break; end
    end
  end
  clear junk tmp

  if ~isempty(gt.debug)
    gs.gtops.debug.ibin(f) = {ibin};
    gs.gtops.debug.pset(f) = {[]};
    gs.gtops.debug.rtime(f) = {prof.rtime};
  end
  


  %                                     %
  %%%%%%%% END Selection Filters %%%%%%%%

  % do a matrix search for the matching fields
  [s pset]=ismember(ibin',gtbin','rows');
  if ~isempty(gt.debug)
    gs.gtops.debug.pset(f) = {pset};
  end

  pset = pset(s);
  if length(pset) == 0
    disp('  Warning: no bins selected');
    continue
  else
    disp(sprintf('  %d of %d profs selected',length(pset),length(s)))
  end


  if any(ismember(inc_fields,{'rlat_avg' 'rlon_avg'})) | any(ismember(inc_fields,{'rlat' 'rlon'}))
    inc_fields = union(inc_fields,{'rlat_avg' 'rlon_avg'}); % make sure we are returning lat/lon
    rlat_avg = []; rlon_avg = [];
  end

  % do the math
  for i = 1:length(inc_fields);
    field = inc_fields{i};

    % should we skip doing a std?
    do_std = true;
    if length(field) > 4 && strcmp(field(end-3:end),'_avg'); do_std = false; field = field(1:end-4); end

    if strcmp(field,'jac')
      %keyboard
      pnum = find(s);
      for j = 1:length(pnum)
        % jacobian calculations
        tmp = reshape(compute_jacs(gt.jac,head,structfun(@(x) ( x(:,pnum(j)) ),prof, 'UniformOutput', false)),[],1);
        first_dim = size(tmp,1);
        if ~exist([field '_sum'])
          eval(sprintf('%s_sum = zeros([first_dim nbins]);',field))
          eval(sprintf('%s_count = zeros([first_dim nbins],''uint16'');',field))
          if do_std; eval(sprintf('%s_sum2 = zeros([first_dim nbins]);',field)); end
        end
        jac_sum(:,pset(j)) = jac_sum(:,pset(j)) + t;
        jac_sum2(:,pset(j)) = jac_sum2(:,pset(j)) + tmp .^ 2;
        jac_count(:,pset(j)) = jac_count(:,pset(j)) + 1;
      end
      continue 
    end
    clear tmp

    % if a field is missing, lets skip over it and go to the next
    if ~isfield(prof,field) 
      if ~exist(['warn_' field],'var')
        disp(['  Warning: Field ' field ' does not exist in rtp file, skipping field and further warnings supressed.']);
        eval(['warn_' field '=1;']) % supress further warnings
      end
      continue
    end

    % handle the summations:
    first_dim = eval(['size(prof.' field ',1)']);
    t=getfield(prof,field,{1:first_dim,s});
    if ~exist([field '_sum'])
      eval(sprintf('%s_sum = zeros([first_dim nbins],''single'');',field))
      eval(sprintf('%s_count = zeros([first_dim nbins],''uint16'');',field))
      if do_std; eval(sprintf('%s_sum2 = zeros([first_dim nbins],''single'');',field)); end
    end

try
%    if strcmp(field,'rlon')
%      for p_ind = 1:length(pset)
%        [rlat_sum(1,pset(p_ind)) rlon_sum(1,pset(p_ind))] =  ...
%          meanm([prof.rlat(s) repmat(rlon_sum(pset(p_ind)),[1 rlon_count(pset(p_ind))])], ...
%             [t, repmat(rlon_sum(pset(p_ind)),[1 rlon_count(pset(p_ind))])]);
%        plot(prof.rlon(ibin(3,:)==94));hold all
%        rlon_count(pset(p_ind)) = rlon_count(pset(p_ind)) + length(t);
%      end
%      %keyboard
%    elseif strcmp(field,'rlat')
%      % do nothing, we'll do this in the rlon calculation

    if strcmp(field,'rlon')
      rlon_sum = rlon_sum + accumarray(pset,exp(t*pi/180*img),[nbins first_dim],@nansum)';
    elseif first_dim == 1
      eval(sprintf('%s_sum = %s_sum + accumarray(pset,t,[nbins first_dim],@nansum)'';', ...
        field,field))
      if do_std; 
        eval(sprintf('%s_sum2 = %s_sum2 + accumarray(pset,t.^2,[nbins first_dim],@nansum)'';', ...
          field,field))
      end
      eval(sprintf('%s_count = %s_count + uint16(accumarray(pset,~isnan(t),[nbins first_dim],@nansum))'';', ...
          field,field))
    else
      for p_ind = 1:length(pset)
        eval(sprintf('%s_sum(:,pset(p_ind)) = nansum([%s_sum(:,pset(p_ind)),t(:,p_ind)],2);', ...
          field,field))
        if do_std; 
          eval(sprintf('%s_sum2(:,pset(p_ind)) = nansum([%s_sum2(:,pset(p_ind)),t(:,p_ind).^2],2);', ...
            field,field))
        end
        eval(sprintf('%s_count(:,pset(p_ind)) = nansum([%s_count(:,pset(p_ind)),uint16(~isnan(t(:,p_ind)))],2);', ...
            field,field))
      end
    end
catch e
  e
  %keyboard
  disp(['error point 2 ' outfile])
  continue
end  

  end % inc_fields loop

  if ~isempty(pset)
    count = count + uint16(accumarray(pset,1,[nbins 1]))';
  end

  clear head hattr prof pattr
end % main file loop

gs.npro = trim(count);

% divide out the sums and provide the statistics
for i = 1:length(inc_fields);
  field = inc_fields{i};
  if length(field) > 4 && strcmp(field(end-3:end),'_avg'); field = field(1:end-4); end
  
  % skip any missing fields
  if ~exist([field '_sum']); continue; end
  % keep accuracy on rtime
  if strcmp(field, 'rtime'); fclass = 'double'; else; fclass = 'single'; end

  % do the statistics
  if strcmp(field,'rlon')
    gs.rlon_avg = -angle(rlon_sum) * 180 / pi;
  else
    eval(sprintf('gs.%s_avg = %s(%s_sum ./ double(%s_count));',field,fclass,field,field))
  end

  %if eval(['isreal(gs.' field '_avg)']); eval(sprintf('gs.%s_avg = trimbits(gs.%s_avg,8);',field,field)); end
  if exist([field '_sum2'])
    if strcmp(field,'rlon')
      gs.rlon_std = acos(abs(rlon_sum)/rlon_count)*180/pi;
    else
      eval(sprintf('n = double(%s_count);',field))
      eval(sprintf('nm1 = max(0,double(%s_count-1));',field))
      eval(sprintf('gs.%s_std = single(sqrt(abs(%s_sum2./nm1 - %s_sum.*%s_sum./(n.*nm1))));', ...
        field,field,field,field))
      %if eval(['isreal(gs.' field '_std)']); eval(sprintf('gs.%s_std = trimbits(gs.%s_std,8);',field,field)); end
      clear([field '_sum2'],'n','nm1')
    end
  end
  clear([field '_sum'])

  % we should include the count field if it is not the same as npro
  first_dim = eval(['size(' field '_count,1)']);
  if eval(['~isequal(repmat(count,[first_dim 1]),' field '_count)'])
    eval(sprintf('gs.%s_count = trim(%s_count);',field,field))
  end
end

if nargin == 2
  save(outfile,'-V7.3','-struct','gs');
end

end % end gstats function

function val = trim(val)
  if ~isnumeric(val); return; end
  if isequal(val,uint32(val))
    if isequal(val,uint8(val)); val = uint8(val);
    elseif isequal(val,uint16(val)); val = uint16(val);
    else; val = uint32(val); end
  elseif isequal(val,int32(val))
    if isequal(val,int8(val)); val = int8(val);
    elseif isequal(val,int16(val)); val = int16(val);
    else; val = int32(val); end
  end
end

function val = amax(vec)
  if size(vec,1) == 1; val = vec; return; end
  [val i] = nanmax(abs(vec),[],1);
  val = vec(i);
end
