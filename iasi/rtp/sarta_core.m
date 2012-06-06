%%%%%%%%
%
%  Main processing script to change observation files into calc files with profiles.
%
%%%%%%%%

%  Written by Paul Schou  17 Jun 2011
iasi_paths

system('sleep $(( $RANDOM % 30 ))');

if ~exist('model','var')
  model='ecm';
end
%if ~exist('emis','var')
  emis='wis';
%end

%JOB = datenum(2011,5,29);

clear f
file_list = findfiles(input_glob);

disp(['  Found a total of ' num2str(length(file_list)) ' files to add model data'])

for f = file_list
try % if a file goes bad skip it and go to the next
bn = basename(f{1});

%outfile = [dirname(f{1}) '/calc_' basename(f{1},'_1Z')];
outfile = [dirname(f{1}) '/' model '.' basename(f{1},'_1')];
disp(['Outfile: ' outfile])

if exist([outfile '_1Z'],'file');
  continue;
end
% declare we are working on this day so we don't have two processes working on the same day
if ~lockfile(outfile); continue; end


[head hattr prof pattr] = rtpread_12(f{1});

% save some space by not keeping robs1
if isfield(prof,'robs1'); prof = rmfield(prof,'robs1'); end
if isfield(prof,'calflag'); prof = rmfield(prof,'calflag'); end
hattr = set_attr(hattr,'rtpfile',f{1},'header');
pattr = set_attr(pattr,'rtime','Seconds since 2000','profiles');
%hattr = set_attr(hattr,'prod_code','process_l1bcm.m');

%%%%
%
%  Model matchup section
%
%%%%
if strcmp(model,'ecm')
  disp(['  adding ecm profiles to ' bn])
  try
  [head hattr prof pattr] =rtpadd_ecmwf_data(head,hattr,prof,pattr);
  catch
    disp(['ERROR: Reading in ecmwf data'])
    continue
  end
elseif strcmp(model,'era')
  disp(['  adding era profiles to ' bn])
  system(['/asl/opt/bin/getera ' datestr(JOB(1),'yyyymmdd')])
  [head hattr prof pattr] =rtpadd_era_data(head,hattr,prof,pattr);
elseif strcmp(model,'gfs')
  disp(['  adding gfs profiles to ' bn])
  [head hattr prof pattr] =rtpadd_gfs(head,hattr,prof,pattr);
else
  error('unknown profile model')
end

if ~isfield(prof,'wspeed')
  prof.wspeed = zeros(size(prof.rtime));
end


%%%%
%
%  Surface altitude and landfrac
%
%%%%
%[prof.salti, prof.landfrac] = usgs_deg10_dem(prof.rlat, prof.rlon);
% fix the land frac for the larger fovs:
[prof.salti prof.landfrac] = usgs_degN(prof.rlat,prof.rlon,1.5);

%%%%
%
%  Emissivity Matchup section
%
%%%%
if strcmp(emis,'wis')
  disp(['  adding wis emissivity to ' bn])
  dv = datevec(JOB(1));
  try
    [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  catch
    if dv(3) > 15
       dv = datevec(JOB(1) + 30);
      [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
    else
       dv = datevec(JOB(1) - 30);
      [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
    end
  end
  pattr = set_attr(pattr,'emis',emis_str);
elseif strcmp(emis,'dan')
  disp(['  adding dan emissivity to ' bn])
  pattr = set_attr(pattr,'emis','DanZhou');
  [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr);
else
  error('unknown emissivity model')
end
prof.nrho= prof.nemis;
prof.rho = (1.0 - prof.emis)/pi;

%%%%
%
%  Run SARTA / KLAYERS section
%
%%%%
disp(['  setting sarta attributes in ' bn])
hattr = rm_attr(hattr,'sarta');
hattr = rm_attr(hattr,'klayers');

%sarta_exec='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';
sarta_exec='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte_swch4';
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);

% if we are using static layers
%[head,prof] = klayers_filt(head,prof,1025);

% write out an rtp file for sarta
disp(['  writing out rtp file for sarta ' bn])
tmp = mktemp();
outfiles = rtpwrite_12(tmp,head,hattr,prof,pattr);

for tmp1 = outfiles
  tmp1 = tmp1{1};
  disp(['  running klayers on ' bn ' (' tmp1 ')'])
  tmp2 = [tmp1 'b'];
  out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
  unlink(tmp1)
  if out ~= 0; error(['  error running klayers on ' bn]); end

  disp(['  running sarta on ' bn ' (' tmp2 ')'])
  %out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
  out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' ']);
  unlink(tmp2)
  if out ~= 0; error(['  error running sarta on ' bn]); end
end


%%%%
%
%  Reading in final result section and copying rcalc over to previous rtp structure
%
%%%%
disp(['  reading in calcs for ' bn])
if ~exist(tmp,'file')
  error(['file ' tmp ' does not exist'])
end
[h hattr p pattr] = rtpread_12(tmp);
unlink(tmp1)
prof.rcalc = p.rcalc;
clear p;

%%%%
%
%  Write out a final result
%
%%%%
disp(['  writing out ' outfile]);
hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);
%  head
%  get_attr(hattr)
%  prof
%  get_attr(pattr)
rtpwrite_12([outfile 'Z'],head,hattr,prof,pattr);

unlink(tmp1)
unlink(tmp2)
clear head hattr prof pattr p

catch; 
disp('ERRORED OUT')
prof
end

end
