%%%%%%
%
%  Main processing script to create IASI RTP files from raw data
%
%  Script to produce IASI FULL, FULL4CH, SUBSET data
%
%  Input variables:
%    JOB = [start_date end_date] (in matlab format)
%    data_str='' (a string for data variation)
% 
%  To use execute the script using
%    $ clustcmd mkday_####.m 20090801:20090808
%  from the command line.
%

% Written by Paul Schou (paulschou.com) April 2010
%            Breno Imbiriba  - 2012.12.24 - comments, warnings, and reorder
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence
%
% 0.1 Add IASI paths
% 0.2 Test for JOB variable
% 0.3 Configure the input and output dirs 
% 0.4 Make tempfiles
% 0.5 **If variable 'data_str' doesn't exist, set it to ''.
% 0.6 Set up to have hourly files, except if it's 'full' 
% 1.0 Loop over dates
% 1.1 **Create file name - this is confusing and unstandard!!
% 1.2 Search for needed files
% 1.3 Check the existence of old files and if they need to be recreated
% 1.4 Setup some variables
% 1.5 Make lockfile
% 2.0 **Read input files - Most of everything enters here!
% 3.0 Construct the RTP structure
% 4.0 Save data file



rn='rtp_core (iasi)';
greetings(rn);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Set up
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Set up IASI specific pathes

iasi_paths


% Test for the JOB variable

if ~exist('JOB','var')
  say('JOB variable missing!');  
  error('Bad input argument');
end



% Directories to use for input / output files

indir = ['/asl/data/IASI/L1C/' datestr(JOB(1),26)];
outdir = [prod_dir '/' datestr(JOB(1),26)];


% temporary files

tmpfile1 = mktemp('IASI_L1C1');
tmpfile2 = mktemp('IASI_L1C2');



% Test for the data_str variable

if ~exist('data_str','var')
  say('WARNING: data_str does not exist. setting it to nothing.');
  data_str = '';
end



span = 0:23;
allfov = 0;
if strcmp(rtpset,'full')
  allfov = 1;
  span = 0:24*6-1;
elseif strcmp(rtpset,'full4ch')
  allfov = 1;
elseif strcmp(rtpset,'full2345ctr')
  allfov = 1;
elseif strcmp(rtpset,'subset')
  % nothing to be done
else
  say(['Unknown rtpset string ' rtpset '.']);
  error('Bad input argument');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Loop over hours or 0.1*hours (for an allfovs)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

say(['Processing ' datestr(JOB(1),'yyyy/mm/dd') ]);
for hour = span

  say(['Start Hour=' num2str(hour)])



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %
  % Create file names
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  prefix = 'IASI_L1_CLR';

  if strcmp(rtpset(1:min(4,end)),'full')

    outfile = [outdir '/iasi_l1c_' rtpset data_str '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%03d') '.v1.summary.mat'];
    rtp_outfile = [outdir '/iasi_l1c_' rtpset data_str '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%03d') '.v1.rtp'];
    mask=[indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(floor(hour/6),'%02d') num2str(mod(hour,6),'%01d') '*'];

  else

    outfile = [outdir '/iasi_l1c.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.summary.mat'];
    rtp_outfile = [outdir '/iasi_l1c' data_str '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.rtp'];
    mask=[indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*'];

  end


  say(['RTP outfile: ' outfile])
  say(['Matching IASI file mask: ' mask '...'])

  [files dates] = findfiles(mask);

  say(['    Found ' num2str(length(files)) ' files'])

  [rtp_files rtp_dates] = findfiles([rtp_outfile '*']); % check if the rtp outfiles already exist



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %
  % Check the existence of old files 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  dates2 = [];
  rtp_dates2 = [];
  version_str = 'IASI processing v1.1';

  if exist(outfile,'file')
    say(['File ' outfile ' already exists. Checking...']);

    dates2 = load(outfile,'gran_dates');
    dates2 = dates2.gran_dates;
    rtp_dates2 = load(outfile,'rtp_dates');
    rtp_dates2 = rtp_dates2.rtp_dates;

    version_str2 = '';
    version_str2 = load(outfile,'version_str');
    version_str2 = version_str2.version_str;
    datestr(rtp_dates');
    datestr(rtp_dates2');

    if ~isequal(dates,dates2)
      say('match fail: raw data dates')
    end
    if ~isequal(rtp_dates,rtp_dates2)
      say('match fail: rtp dates');
    end
    if ~strcmp(version_str,version_str2)
      say('match fail: version')
    end
    if isequal(dates,dates2) & isequal(rtp_dates,rtp_dates2) & strcmp(version_str,version_str2)
      say(['The file date lists match, doing nothing! Skipping...']);
      continue
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %
  % Setup some variables, make Lockfile
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  % Fixed site matchup range {km}
  site_range = 55.5;  % we 55.5 km for IASI (and AIRS?)

  % Default CO2 ppmv
  co2ppm_default = 385.0;

  % No data value
  nodata = -9999;


  %if ~isequal(dates, dates2) | ~isequal(rtp_dates, rtp_dates2)
  if ~exist(outdir,'dir')
    say(['creating output directory: ' outdir])
    mkdirs(outdir);
  end

  % declare we are working on this day so we don't have two processes working on the same day
  say(['lockfile: ' outfile])
  if ~lockfile(outfile); 
    say(['Lock File ' outfile ' exists. Skipping']);
    continue; 
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %
  % Read input files using iasi_uniform_and_allfov_func.m
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  head.pfields = 0;
  try
    [head, hattr, prof, pattr, summary, isubset] = iasi_uniform_and_allfov_func(mask,allfov);
  catch err
    Etc_show_error(err);
    say(['WARNING: iasi_uniform_and_allfov failed. Skipping...']);
    continue
  end

  if(isempty(prof))
    say(['Profile is empty. Continuing...']);
    continue
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %
  % Construct the RTP structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


  if exist('prof','var') & ~isempty(prof)
    prof = structmerge(prof);
    robs1 = prof.robs1;
    calflag = prof.calflag;


    %%%%%%%%%  Make a HEADER structure
    head = struct;
    head.pfields = 4;
    head.ptype = 0;
    head.ngas = 0;

    % Determine channel freqs
    head.vchan = (645:0.25:2760)';
    head.nchan = length(head.vchan);
    head.ichan = (1:head.nchan)';
    
    % Assign RTP attribute strings
    hattr = set_attr(hattr,'rtpfile',rtp_outfile,'header');
    hattr = set_attr(hattr,'pltfid','IASI');
    hattr = set_attr(hattr,'instid','METOP2');

    hattr = set_attr(hattr,'rtime','seconds since 01 1 Jan 2000','profiles');
    hattr = set_attr(hattr,'robsqual','0=good, 1=bad');

%   Some examples of attributes set by the reader:
%    pattr={ {'profiles' 'rtime' 'seconds since 01 1 Jan 2000'}, ...
%            {'profiles' 'robsqual' '0=good, 1=bad'}, ...
%            {'profiles' 'iudef(2,:)' 'fixed site number'}, ...
%            {'profiles' 'iudef(3,:)' 'scan direction'} };

    if strcmp(rtpset,'full4ch')
      iasi_chkeep = [1021 2345 3476 4401];
      [head, prof] = subset_rtp(head,prof,[],iasi_chkeep,[]);
    end

    if strcmp(rtpset,'full2345ctr')
      iasi_chkeep = [2345];
      ikeep = find(prof.xtrack == 15 | prof.xtrack == 16);
      [head, prof] = subset_rtp(head,prof,[],iasi_chkeep,ikeep);
    end

    say(['Saving ' num2str(numel(prof.rtime)) ' FoVs in this file']);

    rtpwrite_12(rtp_outfile,head,hattr,prof,pattr);


    % save out a summary file
    summary.gran_files = files;
    summary.gran_dates = dates;
    summary.version_str = version_str;
    [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile '_*']);
    save(outfile,'-struct','summary')
  end

end % hour loop

farewell(rn);
% END OF SCRIPT
