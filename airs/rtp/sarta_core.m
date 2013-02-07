%%%%%%%%
%
%  Main processing script to change observation files into calc files with profiles.
% 
%  This script expects four variables 
% 'JOB'  - containing the matlab date to process
% input_glob - "glob" of files to look for to process for rtp calc creation
% model  - the model code name
% emis   - the emissivity code name
% usgs   - optiona variable - if it exists, add the USGS landfrac and salti.
% sarta  - version of sarta to use (clr - clear / cld - slab cloudy)
%
% Example:
% JOB=datenum(2010,04,10);
% input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1bcm.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];
% model='ecm'
% emis='wis'
%
%  Written by Paul Schou  17 Jun 2011
%  Comments, Checks, Warnings by Breno Imbiriba 2012.12.19
%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence of events:
% 1.1 Loop over globbed files --
% 1.2 Make the name for the output file
% 1.3 Make lock file
% 1.4 Read In RTP data
% 1.5 **Remove robs1 and caflag to save space ??
%       This is to make a rtpZ file - but careful! If using this code for 
%       something else, you must revisit this!
% 1.6 Set rtpfile attribute
% 2.1 Add Atmospheric Model
% 2.2 Check for RTP file consistency 
% 2.3 **Set windspeed to 0 if not present ??
%       Set it to -9999!!! 
% 2.4 **If 'usgs' variable exists ADD land fraction and surface altitude ???
%       The issues is that we want to know those two pieces of info even to
%       just analyse Obs. It's model but it's done before this routine elsewhere.
%       The best is to *check* if this is needed by looking at the prof.
% 2.5 Add Emissivity
% 2.6 Make rho=(1-emis)/pi;
% 3.1 Set klayers and sarta attributes
% 3.2 ** Use hardcoded klayers
%        I want to change this to an option. And move to SartaRun/KlayersRun
% 3.3 ** Set hardcoded sarta (two versions, Nov 2003)
%        idem
% 3.4 Make a copy of "prof" without robs1 and calflag - to speed up I/O
% 3.5 Save the RTP file
% 3.6 Run Klayers
% 3.7 Run Sarta
% 4.1 Read in calc files
% 4.2 **Check if there are rcalcs, if not, issue an Error (try/catch!???)
%       Fixed - not it FAILS if things go wrong
% 4.3 **Set again sarta and klayers attributes
%       Not necessary - unless some strange thing is happening. Removed.
% 4.4 Save final output file
% 4.5 Remove temporaty files - lock file is removed automatically when matlab quits


rn='sarta_core (AIRS)';
greetings(rn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up AIRS specific pathes

airs_paths

if ~exist('model','var')
  error(['Missing "model" variable']);
end
if ~exist('emis','var')
  error(['Missing "emis" variable']);
end
if ~exist('sarta','var')
  sarta='clr';
end


clear f


workfiles=findfiles(input_glob);

if(numel(workfiles)==0)
  say(['No files to work on! Returning...']);
  return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Loop over files 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



for f = workfiles

  bn = basename(f{1});

  outfile = [dirname(f{1}) '/' model '.' sarta '.' basename(f{1},'Z') 'Z'];
  say(['Outfile: ' outfile]);

  % Check if file already exists. 
  if(exist(outfile,'file'));
    say('Output file exists');
    dir0=dir(f{1});
    dir1=dir(outfile);
    if(dir0.datenum>dir1.datenum)
      say('   and it is OLDER than base file... Regenerating!');
    else
      say('   but it is NEWER then base file... Continuing to next file...');
      continue;
    end
  end

  % declare we are working on this day so we don't have two processes working on the same day
  if ~lockfile(outfile); 
    say(['Warning: lockfile for ' outfile ' already exists. Continuing...']);
    continue; 
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Read input file
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [head hattr prof pattr] = rtpread(f{1});




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Remove robs1 and calflag to save space (those exist on the base file)
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if isfield(prof,'robs1'); prof = rmfield(prof,'robs1'); end
  if isfield(prof,'calflag'); prof = rmfield(prof,'calflag'); end
  hattr = set_attr(hattr,'rtpfile',f{1});
  %hattr = set_attr(hattr,'prod_code','process_l1bcm.m');


  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %  Mode Matchup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  pattr=set_attr(pattr,'rtime','Seconds since 1993');
  if strcmp(model,'ecm')
    say(['  adding ecm profiles to ' bn])
    try
      [head hattr prof pattr] =rtpadd_ecmwf_data(head,hattr,prof,pattr);
    catch
      say(['  WARNING:  Failed adding ECMWF profile. Continuing to the next file....'])
      continue
    end
  elseif strcmp(model,'era')
    say(['  adding era profiles to ' bn])
    if strcmp(sarta,'cld')
      [head, hattr, prof, pattr] = rtpadd_era_data(head,hattr,prof,pattr,{'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'});
    else
      [head, hattr, prof, pattr] = rtpadd_era_data(head,hattr,prof,pattr,{'SP','SKT','10U','10V','TCC','CI','T','Q','O3'});
    end

  elseif strcmp(model,'gfs')
    say(['  adding gfs profiles to ' bn])
    [head hattr prof pattr] =rtpadd_gfs(head,hattr,prof,pattr);
  elseif strcmp(model,'mra')
    say(['  adding merra profiles to ' bn]);
    [head hattr prof pattr] =rtpadd_merra(head,hattr,prof,pattr);
  else
    error('unknown profile model')
  end


  %%%%
  % Test if model is there: 
  % We need to have at least gas_1, gas_3, and ptemp. 
  % And ptype must have the proper bits set
  %%%%

  lhave_ptemp = isfield(prof,'ptemp');
  lhave_gas_1 = isfield(prof,'gas_1');
  lhave_gas_3 = isfield(prof,'gas_3');
  [profbit, ircalbit, irobsbit] = pfields2bits(head.pfields);

  if(~lhave_ptemp || ~lhave_gas_1 || ~lhave_gas_3)
    say('*************************************************************************');
    say(['In prod_mat/airs/rtp/sarta_core - Model Match Up seems to have failed!!']);
    say(['ptemp:' yesno(lhave_ptemp) ' gas_1:' yesno(lhave_gas_1) ' gas_3:' yesno(lhave_gas_3) '.']);
    if(profbit)
      say(['Model match up routine is not filling head.pfields properly!']);
      say(['Prof has no profiles but profbit==1. FIX IT!!!']);
    end
    say('*************************************************************************');
    say('Aborting...');
    error(['Failed Adding Atmospheric Model']);
  end


  if(~profbit)
    say('*************************************************************************');
    say(['Model match up routine is not filling head.pfields properly!']);
    say(['Prof has profiles but profbit==0. FIX IT!!!']);
    say(['I will fix this here, but the rtpadd_* routines must be fixed!']);

    profbit=true;
    head.pfields=bits2pfields( profbit, ircalbit, irobs );

    say('*************************************************************************');
  end

  % Wind speed check 
  if ~isfield(prof,'wspeed')
    say(['Models does not provide wind speed. Setting it to -9999']);
    prof.wspeed = -9999*ones(size(prof.rtime));
  end

  %%% End of checks



  %%%%
  %
  %  Add landfrac to the profile if requested
  %
  %%%%
  if(exist('usgs','var') || ~isfield(prof,'salti') || ~isfield(prof,'landfrac'))
    say(['RTP prof doesn not have salti ou landfrac - or you declared the variable "usgs". Adding USGS model to prof.']);
    prof.salti = -9999*ones(size(prof.rtime),'single');
    prof.landfrac = -9999*ones(size(prof.rtime),'single');

    is = abs(prof.rlat) <= 90;
    [prof.salti(is) prof.landfrac(is)] = usgs_deg10_dem(prof.rlat(is),prof.rlon(is));
  end

  %%%%
  %
  %  Emissivity Matchup section
  %
  %%%%
  if strcmp(emis,'wis')
    say(['  adding wis emissivity to ' bn])
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
    say(['  adding dan emissivity to ' bn])
    pattr = set_attr(pattr,'emis','DanZhou');
    [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr);
  else
    error('unknown emissivity model')
  end

  prof.nrho= prof.nemis;
  prof.rho = (1.0 - prof.emis)/pi;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%
  %
  %  Run SARTA / KLAYERS section
  %
  %%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  say(['  setting sarta attributes in ' bn])
  hattr = rm_attr(hattr,'sarta');
  hattr = rm_attr(hattr,'klayers');

  if ~exist('klayers_exec','var');
    klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
  end

  if strcmp(sarta,'clr')
    if JOB(1) < datenum(2003,10,01)
      %sarta='/asl/packages/sartaV108/BinV201/sarta_apr08_m140x_385_wcon_nte';
      %sarta_exec='/asl/packages/sartaV108/BinV201/sarta_apr08_m140x_370_wcon_nte';
      sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte';
    else
      sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte';
    end
  elseif strcmp(sarta,'cld')
    sarta_exec = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte';
    airs_cloudy
  else
    error('unknown sarta specification');
  end

  hattr = set_attr(hattr,'sarta_exec',sarta_exec);
  hattr = set_attr(hattr,'klayers_exec',klayers_exec);

  % if we are using static layers
  %[head,prof] = klayers_filt(head,prof,1025);

  % write out an rtp file for sarta
  say(['  writing out rtp file for sarta ' bn])
  tmp1 = mktemp();

  p = prof;
  if isfield(p,'robs1'); p = rmfield(p,'robs1'); end
  if isfield(p,'calflag'); p = rmfield(p,'calflag'); end
  rtpwrite(tmp1,head,hattr,p,pattr);
  say(['  running klayers on ' bn])
  tmp2 = mktemp();
  %out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2]);
  out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
  unlink(tmp1)
  if out ~= 0; error(['  error running klayers on ' bn]); end

  tmp1 = mktemp();
  say(['  running sarta on ' bn])
  %out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1]);
  out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
  unlink(tmp2)
  if out ~= 0; error(['  error running sarta on ' bn]); end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%
  %
  %  Reading in final result section and copying rcalc over to previous rtp structure
  %
  %%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  say(['  reading in calcs for ' bn])

  [h hattr p pattr] = rtpread(tmp1);

  unlink(tmp1)
  if(~isfield(p,'rcalc'))
    error(['ERROR: Calc files has no actual rcalc field!!']);
  end

  prof.rcalc = p.rcalc;

  %%%%
  %
  %  Write out a final result
  %
  %%%%

  say(['  writing out ' outfile]);
  rtpwrite(outfile,head,hattr,prof,pattr);

  unlink(tmp1)
  unlink(tmp2)
  clear head hattr prof pattr p

end

farewell(rn);
% END OF THE SCRIPT
