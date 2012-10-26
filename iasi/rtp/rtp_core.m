%
%  This code constructs IASI rtp files and is ready for real-time production
%
%  To use execute the script using
%    $ clustcmd mkday_####.m 20090801:20090808
%  from the command line.
%

% Written by Paul Schou (paulschou.com) April 2010

iasi_paths

if ~exist('JOB','var')
  JOB = datenum(2010,1,1)
  %JOB = datenum(2009,1,3)
end

% Directories to use for input / output files
indir = ['/asl/data/IASI/L1C/' datestr(JOB(1),26)];
outdir = [prod_dir '/' datestr(JOB(1),26)];

% temporary files
tmpfile1 = mktemp('IASI_L1C1');
tmpfile2 = mktemp('IASI_L1C2');

if ~exist('data_str','var')
  data_str = '';
end

span = 0:23;
allfov = 0;
if strcmp(rtpset,'full')
  allfov = 1;
  span = 0:24*6-1;
elseif strcmp(rtpset,'full4ch')
  allfov = 1;
end

for hour = span
disp(['hour=' num2str(hour)])

% File name
prefix = 'IASI_L1_CLR';
if strcmp(rtpset,'full')
  outfile = [outdir '/iasi_l1c_full.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%03d') '.v1.summary.mat'];
  rtp_outfile = [outdir '/iasi_l1c_full' data_str '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%03d') '.v1.rtp'];
  mask=[indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(floor(hour/6),'%02d') num2str(mod(hour,6),'%01d') '*'];
else
  outfile = [outdir '/iasi_l1c.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.summary.mat'];
  rtp_outfile = [outdir '/iasi_l1c' data_str '.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.rtp'];
  mask=[indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*'];
end


disp([' RTP outfile: ' outfile])

disp([' matching IASI file mask: ' mask])
[files dates] = findfiles(mask);
disp(['   found ' num2str(length(files)) ' files'])
[rtp_files rtp_dates] = findfiles([rtp_outfile '*']); % check if the rtp outfiles already exist

dates2 = [];
rtp_dates2 = [];
version_str = 'IASI processing v1.1';
 if exist(outfile,'file')
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
    disp('match fail: raw data dates')
  end
  if ~isequal(rtp_dates,rtp_dates2)
    disp('match fail: rtp dates');
  end
  if ~strcmp(version_str,version_str2)
    disp('match fail: version')
  end
  if isequal(dates,dates2) & isequal(rtp_dates,rtp_dates2) & strcmp(version_str,version_str2)
    disp(['The file date lists match, doing nothing! Skipping.']);
    continue
  end
 end


% Fixed site matchup range {km}
site_range = 55.5;  % we 55.5 km for IASI (and AIRS?)

% Default CO2 ppmv
co2ppm_default = 385.0;

% No data value
nodata = -9999;

%dates
%dates2

%if ~isequal(dates, dates2) | ~isequal(rtp_dates, rtp_dates2)
  if ~exist(outdir,'dir')
    disp(['creating output directory: ' outdir])
    mkdirs(outdir);
  end

  % declare we are working on this day so we don't have two processes working on the same day
  disp(['lockfile: ' outfile])
  if ~lockfile(outfile); 
    disp(['Lock File ' outfile ' exists. Skipping']);
    continue; 
  end

  head.pfields = 0;
  try
  %[head, hattr, prof, pattr, summary, isubset] = iasi_uniform_and_allfov_func([indir '/*IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*'],allfov);
  [head, hattr, prof, pattr, summary, isubset] = iasi_uniform_and_allfov_func(mask,allfov);
  catch
    disp(['ERROR: iasi_uniform_and_allfov failed. Skipping.']);
    continue
  end

  if exist('prof','var') & ~isempty(prof)
    prof = structmerge(prof)
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

    rtpwrite_12(rtp_outfile,head,hattr,prof,pattr);


    % save out a summary file
    summary.gran_files = files;
    summary.gran_dates = dates;
    summary.version_str = version_str;
    [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile '_*']);
    save(outfile,'-struct','summary')
  end

end % hour loop

%IASI_check

