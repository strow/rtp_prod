%
%  This code constructs IASI rtp files and is ready for real-time production
%
%  To use execute the script using
%    $ clustcmd mkday_full.m 20090801:20090808
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
outdir = ['/strowdataN/data/rtprod_iasi/' datestr(JOB(1),26)];

% temporary files
tmpfile1 = mktemp('IASI_L1C1');
tmpfile2 = mktemp('IASI_L1C2');

for hour = 0:23
disp(['hour=' num2str(hour)])

% File name
prefix = 'IASI_L1_CLR';
outfile = [outdir '/iasi_l1c_summary.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.mat'];
rtp_outfile = [outdir '/iasi_l1c.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.rtp'];


[files dates] = findfiles([indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*']);
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
    disp('The file date lists match, doing nothing!');
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
    disp(['outdir: ' outdir])
    mkdirs(outdir);
  end

  % declare we are working on this day so we don't have two processes working on the same day
  disp(['lockfile: ' outfile])
  if ~lockfile(outfile); continue; end

  [head, hattr, prof, pattr, summary] = iasi_uniform_clear_func([indir '/*IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*']);

  %if length(findfiles([indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*.gz'])) > 0
  %  [head, hattr, prof, pattr, summary] = iasi_uniform_clear_func([indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*.gz']);
  %else
  %  [head, hattr, prof, pattr, summary] = iasi_uniform_clear_func([indir '/IASI_xxx_1C_M02_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '*Z']);
  %end

  if exist('prof','var') & ~isempty(prof)
    prof = structmerge(prof)
    robs1 = prof.robs1;
    calflag = prof.calflag;

    nchan = 8461;
    split = ceil(nchan/2);
    part1 = (1:split)';
    part2 = (split+1:nchan)';

    % Determine channel freqs
    vchan = (645:0.25:2760)';

    %%%%%%%%%  Make a HEADER structure
    head = struct;
    head.pfields = 4;
    head.ptype = 0;
    head.ngas = 0;
    
    % Assign RTP attribute strings
%    hattr={ {'header' 'pltfid' 'IASI'}, ...
%            {'header' 'instid' 'METOP2'} }
    %
%    pattr={ {'profiles' 'rtime' 'seconds since 01 1 Jan 2000'}, ...
%            {'profiles' 'robsqual' '0=good, 1=bad'}, ...
%            {'profiles' 'iudef(2,:)' 'fixed site number'}, ...
%            {'profiles' 'iudef(3,:)' 'scan direction'} };

    %[head hattr prof pattr] = rtpadd_ecmwf_era(head,hattr,prof,pattr);

    % PART 1
    head.nchan = length(part1);
    head.ichan = part1;
    head.vchan = vchan(part1);
    prof.robs1 = robs1(part1,:);
    prof.calflag = calflag(part1,:);
    hattr = set_attr(hattr,'rtpfile',[rtp_outfile '_1']);
    rtpwrite(tmpfile1,head,hattr,prof,pattr);

    % PART 2
    head.nchan = length(part2);
    head.ichan = part2;
    head.vchan = vchan(part2);
    prof.robs1 = robs1(part2,:);
    prof.calflag = calflag(part2,:);
    hattr = set_attr(hattr,'rtpfile',[rtp_outfile '_2']);
    rtpwrite(tmpfile2,head,hattr,prof,pattr);

    % if we have not had any errors yet, lets start moving these into place
    movefile(tmpfile1,[rtp_outfile '_1']);
    movefile(tmpfile2,[rtp_outfile '_2']);

    % save out a summary file
    summary.gran_files = files;
    summary.gran_dates = dates;
    summary.version_str = version_str;
    [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile '_*']);
    save(outfile,'-struct','summary')
  end
%else
%  disp('The file date lists match, doing nothing!');
%end

end % hour loop

%IASI_check

%exit
