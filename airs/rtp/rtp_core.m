addpath /asl/matlab/airs/readers/
addpath /asl/matlab/aslutil/
addpath /asl/matlab/science/
addpath /asl/matlab/h4toolsV201/
addpath /asl/matlab/rtptoolsV201/
addpath /asl/matlab/iasi/utils/ % fixed site

julian = JOB(1) - datenum(datevec(JOB(1)).*[1 0 0 0 0 0]);
indir = ['/asl/data/airs/AIRIBRAD/' datestr(JOB(1),10) '/' num2str(julian,'%03d')];
outdir = ['/asl/data/rtprod_airs/' datestr(JOB(1),26)];

system(['/asl/opt/bin/getairs ' datestr(JOB(1),'yyyymmdd') ' 1 AIRIBRAD.005 > /dev/null'])

tmpfile = mktemp('AIRS_L1');

[year mo day hr x x] = datevec(JOB(1));
hr_span = (JOB(2)-JOB(1))*24;

for hour = hr-1:hr+hr_span-1
hour

outfile = [outdir '/summary_AIRS1C' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '.mat'];
rtp_outfile = [outdir '/AIRS_L1B_' datestr(JOB(1),'yyyymmdd') num2str(hour,'%02d') '.rtp'];

files = []; dates = [];
for g = 1:10
  [f d] = findfiles([indir '/AIRS.' datestr(JOB(1),'yyyy.mm.dd') num2str(hour*10+g,'.%03d') '*.hdf']);
  files = [files f];
  dates = [dates d];
end
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
  mkdirs(outdir,'+w +x','g');

  % declare we are working on this day so we don't have two processes working on the same day
  if ~lockfile(outfile); continue; end

  clear prof summary_arr;
  for i = 1:length(files)  % loop over granule files for a day
    disp(files{i})
    try
      [eq_x_tai, f, gdata]=readl1b_all(files{i});
    catch; disp(['ERROR ' files{i}]); continue; end

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

    % default CO2 values
    data.co2ppm = co2ppm_default*ones(1,nok);

    % write out the file index number for which file the data came from
    %   note: file names & dates are only available in the summary file
    data.findex = gdata.findex(:)'; %'

    s = abs(data.rlat) <= 90 & abs(data.rlon) <= 180;
    data.salti = ones(1,nok)*nodata;
    [data.salti(s) data.landfrac(s)] = usgs_deg10_dem(data.rlat(s),data.rlon(s));
    
    % fill out the iudef values
    data.iudef = nodata*ones(10,nok);

    % Check for fixed sites
    [isiteind, isitenum] = fixedsite(data.rlat(s), data.rlon(s), site_range);
    if (length(isiteind) > 0)
      data.iudef(2,s(isiteind)) = isitenum;
    end

    % fill out the iudef values
    data.udef = nodata*ones(20,nok);
    data.udef(1,:) = eq_x_tai(:)' - gdata.rtime(:)';

    % subset for good fields
    s = abs(data.rlat) <= 90 & abs(data.rlon) <= 180 & nanmax(data.robs1,[],1) > 0 & max(isnan(data.robs1),[],1) == 0;
    if sum(s) > 0
      prof(i) = structfun(@(x) ( x(:,s) ), data, 'UniformOutput', false);
      %prof(i)
    end
  end   % loop over files

  if exist('prof','var')
    prof = structmerge(prof)

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
    rtpwrite(tmpfile,head,hattr,prof,pattr);
    movefile(tmpfile,[rtp_outfile]);

    % save out a summary file
    summary.gran_files = files;
    summary.gran_dates = dates;
    [summary.rtp_files summary.rtp_dates] = findfiles([rtp_outfile]);
    save(outfile,'-struct','summary')
  end
else
  disp('The file date lists match, doing nothing!');
end

  clear prof summary_arr;

end % hour loop

%run_addecmwf
rtpadd_ecmwf(findfiles(['rtprod/' datestr(JOB(1),26) '/AIRS_L1B_' datestr(JOB(1),'yyyymmdd') '*']))

