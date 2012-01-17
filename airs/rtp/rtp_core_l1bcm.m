airs_paths

%mkmetadata(JOB)

% Fixed site matchup range {km}
site_range = 55.5;  % we 55.5 km for AIRS

% Default CO2 ppmv
co2ppm_default = 385.0;

% No data value
nodata = -9999;

% version of processing
rtp_version = 2.01;

julian = JOB(1) - datenum(datevec(JOB(1)).*[1 0 0 0 0 0]);

% LLS commented out below - updated by PS to identify the system and run if at UMBC
% Make sure the airs files are downloaded for this time
hostname = getenv('HOSTNAME');
if strcmp(hostname(max(1,end-7):end),'umbc.edu')
  disp(['../utils/get_meta_data ' datestr(JOB(1),'yyyymmdd') ' > /dev/null']);
  system(['../utils/get_meta_data ' datestr(JOB(1),'yyyymmdd') ' > /dev/null']);
  disp(['/asl/opt/bin/getairs ' datestr(JOB(1),'yyyymmdd') ' 2 AIRXBCAL.005 > /dev/null']);
  system(['/asl/opt/bin/getairs ' datestr(JOB(1),'yyyymmdd') ' 2 AIRXBCAL.005 > /dev/null']);
end
[files dates] = findfiles(['/asl/data/airs/AIRXBCAL/' datestr(JOB(1),10) '/' num2str(julian,'%03d') '/*.hdf']);
if isempty(files); error('No AIRS HDF files found for day'); end
outdir = [prod_dir '/' datestr(JOB(1),26)];

[y m d] = datevec(JOB(1));
%dustcal(y,julian);

pattr = [];

tmpfile = mktemp('AIRS_L1');

for hour = 0:23
hour

 outfile = [outdir '/airs_l1bcm_summary.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.mat'];
 rtp_outfile = [outdir '/airs_l1bcm.' datestr(JOB(1),'yyyy.mm.dd') '.' num2str(hour,'%02d') '.v1.rtp'];

 [rtp_files rtp_dates] = findfiles([rtp_outfile]); % check if the rtp outfiles already exist

 dates2 = [];
 rtp_dates2 = [];
 rtp_version2= nan;
 if exist(outfile,'file')
  prev = load(outfile,'gran_dates','rtp_dates','rtp_version');
  dates2 = prev.gran_dates;
  rtp_dates2 = prev.rtp_dates;
  if isfield(prev,'rtp_version');
    rtp_version2 = prev.rtp_version;
  end
 end



 if ~isequal(dates, dates2) | ~isequal(rtp_dates, rtp_dates2) | ~isequal(rtp_version, rtp_version2) 
  mkdirs(outdir,'+w +x','g');

  % declare we are working on this day so we don't have two processes working on the same day
  if ~lockfile(outfile); disp(['Lock file found, skipping ' outfile]); continue; end

  clear prof summary_arr;
  if ~exist('gdata','var')
    %mkmetadata(JOB);
    %mkmetadata(JOB-1);
    %try
      disp(files{1})
      % read in the entire file
      [gdata, pattr, f] = readl1bcm_v5_rtp(files{1});
    %catch 
    %  disp(['ERROR READING: ' files{1}]); 
    %
    %  disp('-- deleting hdf file and re-downloading it');
    %  unlink(files{1})
    %  system(['/asl/opt/bin/getairs ' datestr(JOB(1),'yyyymmdd') ' 2 AIRXBCAL.005 > /dev/null']);
    %  [gdata, pattr, f] = readl1bcm_v5_rtp(files{1});
    %end

  end




    nchan = size(gdata.robs1,1);
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
            {'header' 'instid' 'AIRS'} };
    %
    %pattr={ {'profiles' 'rtime' 'seconds since 1 Jan 1993'}, ...
    %        {'profiles' 'robsqual' '0=good, 1=bad'}, ...
    %        {'profiles' 'udef(1,:)' 'eq_x_tai - rtime'} };
    pattr = set_attr(pattr,'rtime','seconds since 1 Jan 1993','profiles');

    % PART 1
    head.instid = 800; % AIRS 
    head.pltfid = -9999;
    head.nchan = length(part1);
    head.ichan = part1;
    head.vchan = vchan(part1);
    head.vcmax = max(head.vchan);
    head.vcmin = min(head.vchan);
    hattr = set_attr(hattr,'rtpfile',[rtp_outfile]);

    if hour > 0
      ifov = gdata.findex > hour*10 & gdata.findex <= (hour+1)*10;
    else
      ifov = gdata.findex <= 10;
    end
    [head prof] = subset_rtp(head, gdata, [], [], find(ifov));

    % fix for zobs altitude
    if isfield(prof,'zobs')
      iz = prof.zobs < 20000 & prof.zobs > 20;
      prof.zobs(iz) = prof.zobs(iz) * 1000;
    end

    rtpwrite(tmpfile,head,hattr,prof,pattr);
    movefile(tmpfile,[rtp_outfile]);

    % save out a summary file
    summary.rtp_version = rtp_version;
    summary.gran_files = files;
    summary.gran_dates = dates;
    [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile]);
    save(outfile,'-struct','summary')
 else
  disp('The file date lists match, doing nothing!');
 end

 clear prof summary_arr head hattr;

end % hour loop

