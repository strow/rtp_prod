%%%%%%%%
%
%  Main processing script to change observation files into calc files with profiles.
%
%%%%%%%%

%  Written by Paul Schou  17 Jun 2011
airs_paths


%JOB = datenum(2011,5,29);

clear f
for f = findfiles(input_glob);
bn = basename(f{1});

outfile = [dirname(f{1}) '/' model '.' basename(f{1},'Z') 'Z'];

if exist(outfile,'file');
  continue;
end
% declare we are working on this day so we don't have two processes working on the same day
if ~lockfile(outfile); continue; end


[head hattr prof pattr] = rtpread(f{1});

% save some space by not keeping robs1
if isfield(prof,'robs1'); prof = rmfield(prof,'robs1'); end
if isfield(prof,'calflag'); prof = rmfield(prof,'calflag'); end
hattr = set_attr(hattr,'rtpfile',f{1});
%hattr = set_attr(hattr,'prod_code','process_l1bcm.m');

%%%%
%
%  ECMWF Matchup section
%
%%%%
if strcmp(model,'ecm')
  disp(['  adding ecm profiles to ' bn])
  try
  [head hattr prof pattr] =rtpadd_ecmwf_data(head,hattr,prof,pattr);
  catch
    disp(['  ERROR:  Failed adding ECMWF profile'])
    continue
  end
elseif strcmp(model,'era')
  disp(['  adding era profiles to ' bn])
  system(['/asl/opt/bin/getera ' datestr(JOB(1),'yyyymmdd')])
  [head hattr prof pattr] =rtpadd_era_data(head,hattr,prof,pattr);
elseif strcmp(model,'gfs')
  disp(['  adding gfs profiles to ' bn])
  [head hattr prof pattr] =rtpadd_gfs(head,hattr,prof,pattr);
elseif strcmp(model,'merra')
  disp(['  adding merra profiles to ' bn]);
  [head hattr prof pattr] =rtpadd_merra(head,hattr,prof,pattr);
else
  error('unknown profile model')
end

if ~isfield(prof,'wspeed')
  prof.wspeed = zeros(size(prof.rtime));
end

%%%%
%
%  Emissivity Matchup section
%
%%%%
if strcmp(emis,'wis')
  disp(['  adding wis emissivity to ' bn])
  dv = datevec(JOB(1));
  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  %try
  %  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  %catch
  %  if dv(3) > 15
  %     dv = datevec(JOB(1) + 30);
  %    [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  %  else
  %     dv = datevec(JOB(1) - 30);
  %    [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  %  end
  %end
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

if ~exist('klayers_exec','var');
  klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
end

if ~exist('sarta_exec','var');
  if JOB(1) < datenum(2003,10,01)
    %sarta='/asl/packages/sartaV108/BinV201/sarta_apr08_m140x_385_wcon_nte';
    %sarta_exec='/asl/packages/sartaV108/BinV201/sarta_apr08_m140x_370_wcon_nte';
    sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte';
  else
    sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte';
  end
end

hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);

% if we are using static layers
%[head,prof] = klayers_filt(head,prof,1025);

% write out an rtp file for sarta
disp(['  writing out rtp file for sarta ' bn])
tmp1 = mktemp();
p = prof;
if isfield(p,'robs1'); p = rmfield(p,'robs1'); end
if isfield(p,'calflag'); p = rmfield(p,'calflag'); end
rtpwrite(tmp1,head,hattr,p,pattr);

disp(['  running klayers on ' bn])
tmp2 = mktemp();
out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2]);
%out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
unlink(tmp1)
if out ~= 0; error(['  error running klayers on ' bn]); end

tmp1 = mktemp();
disp(['  running sarta on ' bn])
out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1]);
%out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
unlink(tmp2)
if out ~= 0; error(['  error running sarta on ' bn]); end


%%%%
%
%  Reading in final result section and copying rcalc over to previous rtp structure
%
%%%%
try
disp(['  reading in calcs for ' bn])
[h hattr p pattr] = rtpread(tmp1);
unlink(tmp1)
prof.rcalc = p.rcalc;
clear p;
catch
  disp(['ERROR: Could not read in calc rtp file'])
end

%%%%
%
%  Write out a final result
%
%%%%
hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);
disp(['  writing out ' outfile]);
%  head
%  get_attr(hattr)
%  prof
%  get_attr(pattr)
rtpwrite(outfile,head,hattr,prof,pattr);

unlink(tmp1)
unlink(tmp2)
clear head hattr prof pattr p

end
