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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal routines: trim - reduce integet type to smallest one
%                    amax - return a the maximum value of a profile field for each FoV.
% Sequence
%
% 0   - Setup
% 0.1 - Default selection parameters - 
%       Here we define a clean "gt" array (gtops), except that: 
%       klayres<-rtpklayers, [slat slon]<-fixedsite(), calflag_bit<-0. 
%       I don't know why these three variables are not empty as the other ones.
% 0.2 - User specific requirements - look at the user provided 'gtops' array.
%       **look at 'inc_fields' - if empty, populate with rcalc, robs1, stemp_avg, rtime_avg** I don't want this!!
%	>> Fixed - not it errors out!!
% 0.3 - Loop over provided gtops to process it's fields - print fields, copy to 'gt'
%
% 1.  - Index and fold the bins - the 1st heart of the routine
%  
%       Here we have Nb "*_bins" fields (say A, B, C, D), each of some certain length L_i
%       At the end, we want all the Nb "*_sel" fields to have Prod(L_i) length, and its value
%       to be the INDEX to which entry in _sel represents which on _bins.
%       So we are here doing a Tensor product, for example:
%
%       A_abcd = A_a X I_b(B) X I_c(C) X I_d(D)
%       B_abcd = I_a(A) X B_b X I_c(C) X I_d(D)
%       ...
%       Where I_a(A) is an one-array of the size of A, etc...
%       For example: if L_i = [4 2 1 2]
% 
%       A_abcd = [1 2 3 4] X [1 1] X [1] X [ 1 1 ] = [ 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4]
%       B_abcd = [1 1 1 1] X [1 2] X [1] X [ 1 1 ] = [ 1 1 1 1 2 2 2 2 1 1 1 1 2 2 2 2] 
%       Etc. 
%       The way Paul coded this it was in through loops - a bit convolved but it seems to work.
%       
% 1.2 - All the selection fields are saver into gs.gtops (orderfield(gt))
% 1.3 - Remove singleton _sel fields (not needed!) and warn on empty ones (shouldn't happen!!)
% 2.  - File selection mask (data, rtp, file)
% 2.1 - Run 'findfiles' on the provided filemask ** This is something that should change
% 2.2 - Get the name of the current mfile (mfilename)
% 2.3 - Loop over files and get modification time of each.
% 3.  - Test for regeneration:
% 3.1 - Load output file (outfile) variables 'gtops', rcalc_count, robs1_count
% 3.2 - If originating file times match (file_modified), skip this file. Exit.
% 3.3 - Check old and new gtops *_bins fields 
% 3.4 - Check old and new gtops fields (in general) - simply warn if something is different
%       No check to the actual structure (not gtops!) This has to be done: Fail if nfields<=2
%
% 4.  - Main Loop - START LOOP OVER FILES --------------
% 4.1 - Skip missing input files - This can't happen! Added a warning
% 4.2 - A time estimation piece of code....based on remaining data to be loaded - nice
% 4.3 - Read RTP file
% 4.4 - Hack for old broken Z files ** this should go!
% 4.5 - Grow file - GIT version was bad!!!
% 4.6 - Quit if no robs1
% 4.7 - Setting sarta and klayers executable ** This shouldn't be hard coded here!
% 4.8 - Another fix for badly made RTP files with wrong number of gases
%
% 5.  - Apply filters
% 5.1 - Run user-defined filters 
% 5.2 - Quit if result gives 0 profiles back. Error if rcalcs are missing!
% 5.3 - Site-subset Filter - select by distance, test for return... a bit complicated
% 5.4 - If not skip-calc and has proper fields, Run KLAYERS
% 5.5 - Change numerical data type to single
% 6.  - Main Process
% 6.1 - Define frequency and channel selection - from header and gtops.freq
% 6.2 - Use calflag ... complex...
% 
% 7.  - Main calculation (try/catch loop ) - Create desired bin fields and add them to prof.
% 7.1 - check if field is in gtops - very odd/confusing... why doing this here
% 7.2 - If field is already in prof, continue
% 7.3 - If field name ends with a number - assume it's a variable with index...
%       Check the options (robs1_id, rcalc_id, bto_id,....)
%       Compute them and put in 'prof'
% 
% 8.  - A switch for the remaining possible fields  -
%       btobs1, btcalc, dbt, reason, xtrack_eo, transcom, emismin, secang, mmw, 
%       otherwise assume its an name set in the attributes and get the value.
%
% At this point prof contais all that its needed to start averaging in the bins
%
% 9.  - Begin Selection Filters 
% 9.1. Loop over prof fields names -----------START of all_fields
% 9.2. Test if field exists in 'gt' - if not, just ignore it and move to the next
% 9.3. Get the actuall field value from prof and from 'gt'
% 9.4. If this_pfield is MxNfovs, get only the maximum values (M entry) for each FoV
% 9.5. Bin mthis_pfield using the bins provided by this_gtfield. 
%    I'm not interested in the actual count in each bin (first return of histc),
%    but in the index of which bin a FoV is in (the second argument)
%    
% 9.6. If this_gtfield is not empty (i.e. it's a requested, non-empty field - sanity test)
%    Find bad FoVs (looking for mthis_pfield==-9999), and mark its bin as 1 - the leftmost bin.**PAUL is this right?
% 9.7. Add the vector of bins as a new line in 'ibin' 
% 9.8. Add the vector of selection bins as a new line in 'gtbin'
% 9.9. Look at the last line of 'ibin' (i.e. tmpbinidx) and find out if
%    1. not any (none) fov got selected - show message
%    2. not all (some) fov got selected - compute number and show message
% 9.A. For each fov, if it fall outside of a particular bin, it will be marked with a 0 bin
%     Then we know that this fov won't enter the final calculation.
%     1. Find out if (for each fov) all bins are valid
%     2. If there are no valid bins, warn that the selection killed aol fovs.
%        none(lvalid_bins)
%     --- END LOOP
%
%10.  - Do the ACTUAL binning!
%10.1. Find out (intersect or ismember) which profiles satiefy all the bin rules. Warn if no fovs selected
%10.2. **If either lat or lon is being requested for output, make sure both get reported!** Bad practice!
%10.3. Loop over the requested fields  - START LOOP of inc_fields ----
%10.4. If only requesting an average (*_avg) then set to NOT COMPUTE STD.
%10.5   **If field is 'jac', compute jacobians using compute_jacs passaing the gt.jac field and head and prof.
%         I can't find this routine anywhere 
%         Don't really know how it operates....
%10.6  **If field is missing from prof, warn and skip (warns just once for each field)** I don't like those teste
%        in the middle of the code. Things can't be iffy! Or the field IS supposed to be there or NOT!
%        If something goes wrong this shoud be an ERROR!
%10.7  Get the field (prof.field) for the desired profile** WHY SO convoluted?? 
%      Why not simply t=prof.(field)(:,s) ????
%10.8  **If field is for summation (*_sum) allocate space** I DON'T KNOW WHAT _sum REALLY IS!
%10.9  (try block) If it's rlon, use the complex wrapping calculation for sum and std. 
%10.A  Else, if field is scalar, compute the sum, and STD if requested
%10.B  Else, Loop over fovs, and sum keeping the first dimension
%10.C  (catch) Show any cought error - I do use try catches, but it should be used as a debugguing tool!
%10.D  Grow local count array       
%      ---- END LOOP OVER FILES --------------
%
%11.1  Copy count into gs.count (count is the number of FoVs in each bin)
%11.2  Loop over all inc_fields
%11.3  If field ends as _avg, remove the ending
%11.4  **If there no 'field_sum' variable defines, skip this variable.** I don't see where this would be defined
%11.5  **Define 'fclass' as single, except if field is 'rtime'>> What about ptime????
%11.6  If field is rlon, use complex rlon_sum to compute the avg.
%11.7  Else, compute: field_avg = fclass(field_sum./field_count); (double for time)
%11.8  **If field_sum2 (I guess STD component), and if it's rlon: 
%      Theorem (still to be proved):  for |Z_i|=1, i=1..N,
%                                     mean(angle) = arg(sum(Z_i))
%                                     std(angle)  = acos(abs(sum(Z_i))/N)
%11.9  IF count is not equal to npro, include it
%
%12    Save. Exit


  rn='gstats';
  greetings(rn);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Default selection parameters
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % User specific requirements
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  img = sqrt(-1);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Check for requested fields
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if isfield(gtops,'inc_fields')
    inc_fields = sort(gtops.inc_fields);
  else
    say('Error: You did not specify which fields to work on!');
    say('Eg: inc_fields = {''stemp_avg'',''rtime_avg'',''robs1'',''rcalc''}');
    error('Missing input arguments');
  end    

  gtops=rmfield(gtops,'inc_fields');


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % option to override defaults with gtops fields
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  if nargin > 0

    optvar = fieldnames(gtops); % get gtops fiels names

    for i = 1 : length(optvar)

      vname = optvar{i};
      if isfield(gt, vname) | strcmp(vname(max(1,end-4):end),'_bins') % if in gt or ends on a _bins

	if ~isfield(gt, vname); 
	  disp(['  setting non standard field ' vname]); 
	end

	gt.(vname) = trim(getfield(gtops, vname)); % copy field from gtops into gt.

	% Display fields:
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
	say(['Warning::  Unknown option or range ' vname ]);
      end
      % small pause to ease cluster work
      pause(0.2)
    end
  end

  gt.inc_fields = inc_fields;

  % set a debug structure
  if ~isempty(gt.debug)
    gt.debug = struct;
  end



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Index and fold the bins
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Get all the selection fields from the gt structure
  gt_names = fieldnames(gt);
  sel_names = gt_names(find(~cellfun(@isempty,regexp(gt_names,'_bins$'))));
  nbins = 1;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Fold the selection fields together
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % See Sequence above.

  say('/---------- FOLDING ----------\'); 
  fold=0;
 
  for isel = 1:length(sel_names)

    % Get length of the "isel^th" field
    len = length(getfield(gt,sel_names{isel}));
    if(len < 2); 
      len = 2; 
    end  

    % Do the tensor product of the previous fields folds with this current length
    % For all the fields before the "isel^th" field, fold them "len-1" times.
    for j = 1:isel-1
      gt = setfield(gt,[sel_names{j}(1:end-5) '_sel'],repmat(getfield(gt,[sel_names{j}(1:end-5) '_sel']),[1 len-1]));
    end

    % Compute current number of bins.
    nbins = nbins * (len - 1);

    % For this current field, simply make "the slowest" alternation (1111...2222...etc)
    temp = trim(repmat(1:len-1,[nbins/(len-1) 1]));
    gt = setfield(gt,[sel_names{isel}(1:end-5) '_sel'],reshape(temp,[1 nbins]));

    if len > 2
      fold = fold + 1;
      say(sprintf('(%d)%22s = %d',fold,['number of ' sel_names{isel}(1:end-5) ' bins'], len-1));
      inc_fields = union(inc_fields,[sel_names{isel}(1:end-5) '_avg']); % make sure we are returning all subsets
    end
  end
  say('\-----------------------------/')
  say(sprintf('%25s = %d','Total bins', nbins));


  % save the gtops to the return gs structure
  gs.gtops = orderfields(gt);

  % clean up the empty bins (the ones not requested) and single selections from the return
  for isel = 1:length(sel_names)
    if isempty(getfield(gs.gtops,sel_names{isel}))
      gs.gtops = rmfield(gs.gtops,sel_names{isel});
    end
    if max(getfield(gs.gtops,[sel_names{isel}(1:end-5) '_sel'])) == 1
      gs.gtops = rmfield(gs.gtops,[sel_names{isel}(1:end-5) '_sel']);
    end
  end





  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % File selection mask
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
    say('  Warning: No files selected');
    farewell(rn);
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

  say(['outfile: ' outfile])



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Test if new request matches existing files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  if nargin == 2 & exist(outfile,'file')

    say('Found existing outfile, loading file modified times:');

    gs2 = load(outfile,'gtops','rcalc_count','robs1_count');

    match = 1;

    % Check for bad gstats - count the number of variables in the output file
    if(numel(who('-file',outfile))<=2)
      say(['Something bad happened to the original GSTATS file! Is has only ' num2str(numel(fieldnames(gs2))) ' fields. As this is less than 3, we will regenerate the file.']);
      match = 0;
    end

    if(match==1)
      if isfield(gs2,'gtops') & isstruct(gs2.gtops) & isfield(gs2.gtops,'file_modified') & isequal(gs.gtops.file_modified,gs2.gtops.file_modified)
	gt_fields = union(fieldnames(gtops),fieldnames(gs2.gtops));

	for igtf = 1:length(gt_fields)
	  fname = gt_fields{igtf};
	  if ~isfield(gtops,fname) & strcmp(fname(max(1,end-4):end),'_bins'); 
	    say(['  Bin criteria changed: new gtops does not have ' fname ' will regenerate']); 
	    match = 0; 
	    continue; 
	  end
	  if ~isfield(gs2.gtops,fname) & strcmp(fname(max(1,end-4):end),'_bins'); 
	    say(['  Bin criteria changed: old gtops does not have ' fname ' will regenerate']); 
	    match = 0; 
	    continue; 
	  end
	  if ~isfield(gtops,fname); 
	    say(['new gtops does not have ' fname]); 
	    continue;
	  end
	  if ~isfield(gs2.gtops,fname); 
	    say(['old gtops does not have ' fname]); 
	    continue; 
	  end
	  if ~isequalwithequalnans(getfield(gtops,fname),getfield(gs2.gtops,fname))
	    say(['  Fields mismatch in ' fname ' will regenerate'])
	    match = 0; 
	  end

	end
	if match == 1
	  say('The gtops have not changed, so skip updating the stats');
	  farewell(rn);
	  exit  
	end
      end
      say('Unmatched, continuing to create new stat file')
    end
  end

  count =  zeros([1 nbins],'uint16');




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Main Loop
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  for f = 1:length(files) % main file loop
    fname = files{f};

    % If file does not exist
    if ~exist(fname, 'file')
      say(['This file came from a "dir" but it is not here anymore!! Skipping missing file: ' fname])
      continue % main file loop
    end

    % Estimate remaining time based on file sizes
    fstats = dir(fname);
    d_time = datenum(clock) - start_time; % delta time
    try % 
      est_time = '00:00:00  EST_TIME  REMAINING_TIME';
      if(i > 1) est_time = [datestr(d_time,13) '  ' ...
		  datestr(d_time/cur_bytes*(total_bytes),13) '  ' ...
		  datestr(d_time/cur_bytes*(total_bytes - cur_bytes),13)];
      end
    catch err; 
      %Etc_show_error(err); % No need for error checking this--- Just avoiding 1/0.
    end;
    cur_bytes = cur_bytes + fstats.bytes;

    TAB=char(9);
    say([basename(fname) TAB '[' num2str(f) '/' num2str(length(files)) ']  ' est_time])


    % -----------------------------
    % Read the RTP file into memory
    % Check if robs1 is present
    % Get sarta/klayer exec names
    % -----------------------------

    try % I/O try

      [head, hattr, prof, pattr] = rtpread_12(fname);

      fname2 = '';

      rtpfile = get_attr(hattr,'rtpfile');

  %%XXXXXXXXXXXXX HACKS FOR BAD FILES
      if strcmp(rtpfile,'rtpname')
	say('  WARNING XXX resetting parent for missing rtpfile variable in rtp file');
	bn=basename(fname);
	dn=dirname(fname);
	rtpfile = [dn bn(9:end)];
	hattr = set_attr(hattr,'rtpfile',rtpfile);
      end

      if length(rtpfile) == 0
	say('  WARNING XXX resetting parent for missing string in rtp file');
	bn=basename(fname);
	dn=dirname(fname);
	hattr = set_attr(hattr,'rtpfile',['/asl/data/rtprod_airs/' dn(31:end) '/' bn(6:end-1)]);
      end

      if strcmp(rtpfile(1:min(end,8)),'/scratch')
	say('  WARNING XXX resetting parent for bad rtp file');
	bn=basename(fname);
	dn=dirname(fname);
	hattr = set_attr(hattr,'rtpfile',[dn '/' bn(9:end-1)]);
      end
  %%XXXXXXXXXXXXX HACKS FOR BAD FILES END

      [head, hattr, prof, pattr] = rtpgrow(head, hattr, prof, pattr,dirname(fname));

      if ~isfield(prof,'robs1'); 
	say(['  Missing robs1 - skipping ' fname]); 
	continue; 
      end

      gs.gtops.rtp_sarta = get_attr(hattr,'sarta');
      gs.gtops.rtp_sarta_exec = get_attr(hattr,'sarta_exec');
      gs.gtops.rtp_klayers = get_attr(hattr,'klayers');
      gs.gtops.rtp_klayers_exec = get_attr(hattr,'klayers_exec');

      if length(gs.gtops.rtp_klayers_exec) == 0
	say('  WARNING: Missing klayers_exec, using airs wetwater default');
	gs.gtops.rtp_klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs';
      end

      if isfield(prof,'rcalc') & isfield(prof,'robs1') & size(prof.rcalc,2) ~= size(prof.robs1,2)
	say('  ERROR:  rcalc and robs1 have different nfov');
	continue;
      end

    catch err % I/O try 
      Etc_show_error(err);
   
      say(['Error reading or growing file: ' fname]);
	 failed = fopen(['~/badfiles.txt'],'a');
	 fwrite(failed,[fname 10],'char');
	 fclose(failed);
      continue
    end  % I/O try
   

    % Uniformity Bug Fix
    % Remove gas numbers if they don't exist in the profile structure
    if isfield(head,'glist')
      for gnum = head.glist'
	if ~isfield(prof,['gas_' num2str(gnum)])
	  say(['Warning: `prof` does not have gas ' num2str(gnum) '. Fix original RTP file: ' fname '! Adjusting local `head` to match `prof`.']);
	  head.gunit = head.gunit(head.glist ~= gnum);
	  head.glist = head.glist(head.glist ~= gnum);
	  head.ngas = head.ngas - 1;
	end
      end
    end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Apply Filters
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Applying User Defined Filter
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(gt.filter)
      before_nobs = length(prof.rtime);
      say(['  Filtering with ' gt.filter '...'])
      eval([gt.filter ';']);
      after_nobs = length(prof.rtime);
      say(['    before filter ' num2str(before_nobs) ' after filter ' num2str(after_nobs)])
      clear before_nobs after_nobs
    end

    % Filter effect:
    if length(prof.rtime) == 0; 
      say(['Warning: No profiles left: length(prof.rtime)==0. Continuing.']);
      continue; 
    end


    % Filter effect:
    if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); 
      error(['  Stats Error: rcalc missing after executing ' gt.filter]); 
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % site subset filter
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(gt.site_bins)
      say(['  Subsetting with site'])
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
      end

      if ~exist('new_prof','var'); disp('    no profiles left'); continue; end
      prof=structmerge(new_prof,2);

      site = prof.site;
      siterad = prof.siterad;

      say(['    before site selection ' num2str(before_nobs) ' after ' num2str(length(prof.rtime))])
      inc_fields = union(inc_fields,{'rlat_avg' 'rlon_avg' 'siterad_avg'}); % make sure we are returning lat/lon
    end


    if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error('  Stats Error: rcalc missing after doing site selection'); end
    if length(prof.rtime) == 0; 
      say('After site selection no FoVs returned... Skipping to next file...');
      continue; 
    end

    % klayers filter
    %ud = prof.udef;
    if ~isfield(gtops,'skip_calc') & mod(head.pfields,2) == 1 & ~isempty(gt.klayers)

      say(['  running klayers filter: ' gt.klayers]);
      eval([gt.klayers ';']);
      %[head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr);
      prof.gtotal = single(totalgas_rtp(head.glist, head, prof));
    end

    %prof.udef = ud;
    if ~isfield(gtops,'skip_calc') & ~isfield(prof,'rcalc'); error(['  Stats Error: rcalc missing after executing ' gt.klayers]); end
    if length(prof.rtime) == 0; 
      say('After klayers, no FoVs returned. That is WRONG! But skipping to the next file...');
      continue; 
    end

    % save some memory
    if isfield(prof,'rcalc'); prof.rcalc = single(prof.rcalc); end
    if isfield(prof,'robs1'); prof.robs1 = single(prof.robs1); end

    % restore the site field
    if ~isempty(gt.site_bins)
      prof.site = site;
      prof.siterad = siterad;
    end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Main Processing
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    say('  Processing...')

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
	    say('  skipping calflag as it is an image');
	  elseif strcmp(cf_attr(1:min(end,10)),'bits1-4=NE')
	    prof.robs1(prof.calflag >= 64) = nan; 
	    say('  filtering by calflag >= 64')
	  elseif isfield(gtops,'nocalflag')
	    say('  skipping calflag bit')
	  else
	    prof.robs1(prof.calflag ~= gt.calflag_bit) = nan; 
	    say('  filtering by calflag bit')
	  end
	else
	  size(prof.calflag)
	  size(prof.robs1)
	  error('  GSTATS: sizes differ between calflag and robs1')
	end
      elseif ~exist('warn_robs_calflag') % we really should be using the calflag
	say('  Warning: robs1 requested, but no calflag filter used.')
	warn_robs_calflag = 1; % supress further warnings
      end
      prof.robs1(prof.robs1 == 0 | (prof.robs1 < -100)) = nan;  % what to do with fake channels

      % clean up any noisy data from the calcs when it is bad in the obs
      %if isfield(prof,'rcalc') 
      %  prof.rcalc(isnan(prof.robs1)) = nan; % set all rcalc to nans in robs1
      %end
    end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Switch for rules of what to do 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    try % Main calculation try/catch loop
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
	  if ~isfield(gt,field) | isempty(getfield(gt,field)); 
	    continue; 
          end
	  field = field(1:end-5); % remove the _bins from the name
	end
	if length(field) > 4 && strcmp(field(end-3:end),'_avg'); field = field(1:end-4); end
	if isfield(prof,field); 
	  continue; 
        end  % if we already have this field, then let's continue

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

	  case 'reason';
	    reason = getudef(prof,pattr,'reason');
	    if ~isempty(reason); prof.reason = reason; clear reason; end
	    if ~isfield(prof,'reason')
	      if isfield(prof,'iudef') & any(prof.iudef(1,:) > 0);
		say('  Warning: Using iudef(1,:) for reason');
		prof.reason = prof.iudef(1,:);
	      elseif isfield(prof,'udef')
		say('  Warning: using udef(1,:) instead of iudef for reason');
		prof.reason = prof.udef(1,:);
	      else
		say('  Warning: no reason bin, but reason binning was requested');
		farewell(rn);
		exit;
	      end
	    end
	    prof.reason(prof.reason < 0) = 0; % clear out the negatives
	    if any(isnan(prof.reason(:))) | any(double(prof.reason(:)) < 0)
	      error('  Reason bin has non valid values, are you sure you want to bin by reason?');
	    end
	    if isfield(gt,'reason_bins') & length(gt.reason_bins) == 1
	      prof.reason = bitget(double(prof.reason),double(gt.reason_bins))*double(gt.reason_bins);
	    end

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
	      say('  Warning: emismin requested but emis doesn''t exist in rtp file');
	    end

	  case 'secang';
	    if isfield(prof,'satzen')
	      % Check satzen is plausible
	      if any(prof.satzen(:) > 90.001)
		say('RTP file contains invalid prof.satzen data, skipping...')
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
		say(['  Warning: Unknown field, ' field]);
	      end
	    end
	end
      end
    catch err; % Main calculation try
      Etc_show_error(err);
      say(['error point 1 ' outfile])
      continue
    end % Main calculation try


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   Begin Selection Filters
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%% BEGIN Selection Filters %%%%%%%%
    %                                       %
    % ibin(f,p) - f:number of requested fields, p: number of profiles
    %             Each vector ibin(:,p) will tell, for the particular profile 'p', 
    %             in which bins the requested fields fall. If you have a 0 for any field
    %             indicates that this profile falls out of the selection.
    %
    % gtbin(f,b)- f:number of requested fields, p: number of bins
    %             Each vector gtbin(:,b) will tell, for the particular serial bin number 'b', 
    %             in which bins the requested fields fall. 
    % 
    %             So you use those two arrays to map a particular profile into field bins into serial bins:
    %             F=ibin(:,p) <-> F'=gtbin(:,b). So by identifying F and F' we know in which bin 'b' the 
    %             FoV 'p' will go. 
    %             

    ibin = []; gtbin = [];

    % super dynamic field selection routine, works on any 1-D prof field
    %  this works by looking at the fields in prof and searching for fields of the same 
    %  name in gtops (adding the _bins suffix).  So if one needs to add additional criteria
    %  for stats, they just need to add fields to the gtops above.

    % 1. Loop over prof fields names

    all_fields = fieldnames(prof);

    for j = 1:length(all_fields)
   
      this_pfield_name = all_fields{j};
      this_gtfield_name= [this_pfield_name '_bins'];

      % 2. Test if field exists in 'gt' - if not, just ignore it and move to the next
      if isfield(gt,this_gtfield_name) && ~isempty(getfield(gt,this_gtfield_name))

	% 3. Get the actuall field value from prof and from 'gt'
	this_pfield = getfield(prof,this_pfield_name);
        this_gtfield= getfield(gt, this_gtfield_name);

	% 4. If this_pfield is MxNfovs, get only the maximum values (M entry) for each FoV
	mthis_pfield = amax(this_pfield);

	% 5. Bin mthis_pfield using the bins provided by this_gtfield. 
	%    I'm not interested in the actual count in each bin (first return of histc),
	%    but in the index of which bin a FoV is in (the second argument)
	%    
	[junkbin tmpbinidx] = histc(mthis_pfield, this_gtfield);

	% 6. If this_gtfield is not empty (i.e. it's a requested, non-empty field - sanity test)
	%    Find bad FoVs (looking for mthis_pfield==-9999), and mark its bin as 1 - the leftmost bin.
	if(length(this_gtfield)>0)
	  ibad_fovs = find(abs(mthis_pfield)>=9999);
          tmpbinidx(ibad_fovs) = 1;
	end


	% 7. Add the vector of bins as a new line in 'ibin' 
	ibin(end+1,:) = min(tmpbinidx,nbins);
	%ibin = [ibin;min(tmpbinidx,nbins)];

	% 8. Add the vector of selection bins as a new line in 'gtbin'
	gtbin(end+1,:) = getfield(gt, [this_pfield_name '_sel']);
	% gtbin = [gtbin;getfield(gt,[all_fields{j} '_sel'])];

	% 9. Look at the last line of 'ibin' (i.e. tmpbinidx) and find out if
	%    1. not any (none) fov got selected - show message
	%    2. not all (some) fov got selected - compute number and show message
	if ~any(ibin(end,:)); 
	  disp(['  Warning: ' this_pfield_name '_bins selected no data']); 
	elseif ~all(ibin(end,:)); 
	  disp(sprintf('  Warning: %s_bins selection excluded %d profs',this_pfield_name,sum(ibin(end,:) == 0)));
	elseif all(ibin(end,:));
	  %disp(sprintf('  N.B.   : %s_bins selection included ALL profs',this_pfield_name));
	end

	% 10. For each fov, if it fall outside of a particular bin, it will be marked with a 0 bin
	%     Then we know that this fov won't enter the final calculation.
	%     1. Find out if (for each fov) all bins are valid
        lvalid_bins = all(ibin,1);
        %     2. If there are no valid bins, warn that the selection killed aol fovs.
	%        none(lvalid_bins)
	if ~any(lvalid_bins); 
	  disp(['  Warning: After indexing ' all_fields{j} ' all ' num2str(size(ibin,2)) ' bins are now empty']); 
	  break; 
        end
      end
    end
    clear junk tmpbinidx

    if ~isempty(gt.debug)
      gs.gtops.debug.ibin(f) = {ibin};
      gs.gtops.debug.pset(f) = {[]};
      gs.gtops.debug.rtime(f) = {prof.rtime};
    end
    


    %                                     %
    %%%%%%%% END Selection Filters %%%%%%%%


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %  Do the Actual binning
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find which profiles are necessary - i.e. - find which F=ibin(:,p) <-> F'=gtbin(:,b) 
    % lead to p<->b
    % I think you could do this with intersect.
     
    [s pset]=ismember(ibin',gtbin','rows');
    if ~isempty(gt.debug)
      gs.gtops.debug.pset(f) = {pset};
    end

    pset = pset(s);
    if length(pset) == 0
      say('  Warning: no bins selected');
      continue
    else
      say(sprintf('  %d of %d profs selected',length(pset),length(s)))
    end

    % If requeting either rlat or rlon, change it to include both!
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

      % Handle the summations:
      
      % Get the prof.field(:,s), i.e. get the fields for the desired profile.
      % why not simply t=prof.(field)(:,s) ????
      
      first_dim = eval(['size(prof.' field ',1)']);
      t=getfield(prof,field,{1:first_dim,s});

      % If field is a summation, allocate space for the field_sum variables
      if ~exist([field '_sum'])
	eval(sprintf('%s_sum = zeros([first_dim nbins],''single'');',field))
	eval(sprintf('%s_count = zeros([first_dim nbins],''uint16'');',field))
	if do_std; eval(sprintf('%s_sum2 = zeros([first_dim nbins],''single'');',field)); end
      end

      try

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
      catch err
	Etc_show_error(err); 
	disp(['error point 2 ' outfile])
	continue
      end  

    end % inc_fields loop

    if ~isempty(pset)
      count = count + uint16(accumarray(pset,1,[nbins 1]))';
    end

    clear head hattr prof pattr
  end % main file loop



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Compute Statistics (avg) and save
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  % Count is the total number of FoVs per bin
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
      % This line would be much clear like this:
      % eval(['gs.' field '_avg = ' fclass '(' field '_sum ./ double(' field '_count)'])
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
    say(['Saving data file ' outfile ]);
    save(outfile,'-V7.3','-struct','gs');
  end

  farewell(rn);

end % end gstats function


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  %   
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function val = trim(val)
% Use the minimum integer data type possible for an integer number.

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
% If vec is a 1xN, returns vec (1xN)
% If vex is a nxN, will still return a 1xN vector but the 
%    with the maximum value for each entry

  if(size(vec,1) == 1)
    val = vec; 
    return; 
  end
  [val i] = nanmax(abs(vec),[],1);
  val = vec(i);
end
