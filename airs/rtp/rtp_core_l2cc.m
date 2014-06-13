function rtp_core_l2cc(wdates,prod_dir)
%%%%%%%
%
%  Main processing script to create AIRS RTP files from raw data
% 
%  Script to procude ALLFOVS L2CC files from AIRS
%
%  Input variable: 
%    dates = [start_date end_date] (in matlab format)  
%    prod_dir = '/asl/data/rtprod_airs/'
%
%  Paul Schou - 2011.xx.xx
%  Breno Imbiriba - 2012.12.04
%                   2013.05.02 - function version for L2CC data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence
%
% 0.1 Add pathes
% 0.2 Compute dates
% 1.1 **Fetch AIRS data using /asl/opt/bin/getairs
%       This routine should be in the git repo! Fix it!
% 2.1 Loop over granules
% 2.2 Set output file name - summary and rtp
% 2.3 find input AIRS hdf files
% 2.4 find existing output files and load its dates
% 2.5 If either gran_dates or rtp_dates are different (or inexistent), generate file
% 2.6 Make lock file
% 3.1 **Loop over granule files (again!) - but we only have just one file here. ??
%       We should know at this point how many files are there, 1! 
%       Make it more robust by computing file names instead of finding them. Fix it!
% 3.2 Read in AIRS data (readl1b_all)
% 3.3 Contruct the RTP prof structure
% 3.4 Set default CO2ppm value
% 3.5 Set USGS salti and landfrac fields
% 3.6 Set iudef(2,:) for fixed sites
% 3.7 Set udef(1,:) for rtime - end of loop 3.1
% 4.1 **Check if "prof" exists, and merge them
%       We should know that prof is a 1-entry array, (see 3.1)
% 4.2 Contruct the head structure
% 4.3 Make attributes
% 5.1 Save data and summary data.




disp(['rtp_core: BEGIN']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up AIRS specific pathes

airs_paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%
%
% Compute dates and fetch AIRS data 
% 0.2 Set up I/O pathes 
% 1. Fetch AIRS data
%
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

julian = wdates(1) - datenum(datevec(wdates(1)).*[1 0 0 0 0 0]);
indir = ['/asl/data/airs/AIRI2CCF/' datestr(wdates(1),'yyyy') '/' num2str(julian,'%03d')];
outdir = [prod_dir '/' datestr(wdates(1),'yyyy/mm/dd')];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
system(['/asl/opt/bin/getairs ' datestr(wdates(1),'yyyymmdd') ' 2 AIRI2CCF.006 > /dev/null'])



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%
%
% Loop over AIRS data files
% 2. - Loop over existing data files and check what has to be done
%
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmpfile = mktemp('AIRS_L2');

[year mo day hr x x] = datevec(wdates(1));
hr_span = (wdates(2)-wdates(1))*24;

for gran = 1:240

  % Set up output files
  outfile = [outdir '/summary.AIRS_L2CC.' datestr(wdates(1),'yyyy.mm.dd') '.' num2str(gran,'%03d') '.mat'];
  rtp_outfile = [outdir '/airs_l2cc.' datestr(wdates(1),'yyyy.mm.dd') '.' num2str(gran,'%03d') '.rtp'];

  % Read Base data files
  files = []; dates = [];
  [f d] = findfiles([indir '/AIRS.' datestr(wdates(1),'yyyy.mm.dd') '.' num2str(gran,'%03d') '*.hdf']);
  files = [files f];
  dates = [dates d];
  [rtp_files rtp_dates] = findfiles([rtp_outfile]); % check if the rtp outfiles already exist

  dates2 = [];
  rtp_dates2 = [];
  if exist(outfile,'file')
    dates2 = load(outfile,'gran_dates');
    dates2 = dates2.gran_dates;
    rtp_dates2 = load(outfile,'rtp_dates');
    rtp_dates2 = rtp_dates2.rtp_dates;
  end

  % Fixed site matchup range {km}
  site_range = 55.5;  % we 55.5 km for AIRS

  % Default CO2 ppmv
  co2ppm_default = 385.0;

  % No data value
  nodata = -9999;


  if ~isequal(dates, dates2) | ~isequal(rtp_dates, rtp_dates2)
    
    disp(['Ready to genetate file ' outfile '.']);

    mkdirs(outdir,'+w +x','g');

    % declare we are working on this day so we don't have two processes working on the same day
    if ~lockfile(outfile); 
      disp(['Warning:  Lockfile exists for file ' outfile '. Skipping...']);
      continue; 
    end

    clear prof summary_arr;

    for i = 1:length(files)  % loop over granule files for a day

      disp(['Loading file ' files{i}]);


      %%%%%%
      % 
      % Read AIRS Data File
      %
      %%%%%%

      [eq_x_tai, f, gdata] = v6_readl2cc(files{i});


      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % 
      % Construct PROFILE structure
      % 
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      data.rtime = gdata.rtime(:)';  %'
      nok = length(data.rtime);

      data.rlat = gdata.rlat(:)';  %'
      data.rlon = gdata.rlon(:)';  %'
      data.satazi = gdata.satazi(:)'; %'
      data.satzen = gdata.satzen(:)'; %'
      data.zobs = gdata.zobs(:)'; %'
      data.solazi = gdata.solazi(:)'; %'
      data.solzen = gdata.solzen(:)'; %'
      data.robs1 = gdata.robs1;

      data.atrack = gdata.atrack(:)'; %'
      data.xtrack = gdata.xtrack(:)'; %'

      data.calflag = gdata.calflag;

      % write out the file index number for which file the data came from
      %   note: file names & dates are only available in the summary file
      data.findex = gdata.findex(:)'; %'


      %%%%
      %
      % Default CO2 values
      %
      %%%%

      data.co2ppm = co2ppm_default*ones(1,nok);

      %%%%
      %
      % Add landfrac and salti to RTP profile
      %
      %%%%

      data.salti = nodata*ones(1,nok,'single');
      data.landfrac = nodata*ones(1,nok,'single');
      s = abs(data.rlat) <= 90 & abs(data.rlon) <= 180;
      [data.salti(s) data.landfrac(s)] = usgs_deg10_dem(data.rlat(s),data.rlon(s));


      %%%%
      %
      % Fill out the iudef values
      %
      %%%%
      
      data.iudef = nodata*ones(10,nok);

      %%
      % Check for fixed sites
      %% 

      [isiteind, isitenum] = fixedsite(data.rlat(s), data.rlon(s), site_range);
      if (length(isiteind) > 0)
	data.iudef(2,s(isiteind)) = isitenum;
      end

      %%
      % fill out the iudef values
      %% 

      data.udef = nodata*ones(20,nok);
      data.udef(1,:) = eq_x_tai(:)' - gdata.rtime(:)';

%      % subset for good fields - DON'T This is an ALLFOVS!!!
%      s = abs(data.rlat) <= 90 & abs(data.rlon) <= 180 & nanmax(data.robs1,[],1) > 0 & max(isnan(data.robs1),[],1) == 0;
%      if sum(s) > 0
%	prof(i) = structfun(@(x) ( x(:,s) ), data, 'UniformOutput', false);
%	%prof(i)
%      end

      prof(i)=data;

    end   % loop over files



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%
    % 
    % Making HEADER/ATTR structures
    % 
    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if exist('prof','var')
      prof = structmerge(prof);

      nchan = size(prof.robs1,1);
      part1 = (1:nchan)';

      % Determine channel freqs
      vchan = f(:);

      %%%%%%%%%  Make a HEADER structure
      head = struct;
      head.pfields = 4;
      head.ptype = 0;
      head.ngas = 0;
      
      % Assign RTP attribute strings
      hattr={ {'header' 'pltfid' 'Aqua'}, ...
	      {'header' 'instid' 'AIRS'} }
      %
      pattr={ {'profiles' 'rtime' 'seconds since 1 Jan 1993'}, ...
	      {'profiles' 'robsqual' '0=good, 1=bad'}, ...
	      {'profiles' 'udef(1,:)' 'eq_x_tai - rtime'} };

      % PART 1
      head.instid = 800; % AIRS 
      head.nchan = length(part1);
      head.ichan = part1;
      head.vchan = vchan(part1);
      set_attr(hattr,'rtpfile',[rtp_outfile]);

      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % SAVE data file
      rtpwrite(tmpfile,head,hattr,prof,pattr);
      movefile(tmpfile,[rtp_outfile]);

      % save out a summary file
      summary.gran_files = files;
      summary.gran_dates = dates;
      [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile]);
      save(outfile,'-struct','summary')
    else
      disp(['Warning: "prof" variable does not exist! Something went wrong in the processing!']);
    end
  else
    disp('The file date lists match, doing nothing!');
  end

  clear prof summary_arr;

end % hour loop

disp(['rtp_core: END']);
end
% END OF THE SCRIPT
