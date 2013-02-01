%%%%%%%%
%
%  Main processing script to change observation files into calc files with profiles.
%
%  Input variable:
%  
%  JOB - [sdate edata] - matlab time operation time
%  model - atmospheric model - era, ecm, gsf, HAS TO CODE MORE
%  emis  - emissivity model - wisc, dan
%  input_glob - "glob" of files to look for to process for rtp calc creation
%  usgs   - optiona variable - if it exists, add the USGS landfrac and salti.
%  sarta  - version of sarta to use (clr - clear / cld - slab cloudy)
%
%%%%%%%%

%  Written by Paul Schou  17 Jun 2011
%  Comments by Breno Imbiriba 2012.12.27 - FUCK!!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence
%
% 0.1 Setup IASI pathes
% 0.2 sleep for a random amount of time - this is to easy the clustrer load
% 0.3 **Setup base mode, emis variables if not present ?? It should FAIL!
%        Done
% 0.4 Find base files (based on glob)
% 1.0 Loop over base files
% 1.1 Makeup name of output file
% 1.2 **Check if it exists ?? It should check file creation date!
%       Done
% 1.3 Set lock file
% 1.4 Read input file - using rtpread_12. USE Breno's rtpread_all for all cases!!!
% 2.0 Add Model data - ecmwf, era, gsf, NO MERRA
% 2.1 add windspeed if not present
% 2.2 **Add USGS land fraction/salti - WHY using another routine?? There's no explanation whatsoever!!!
%       It seems to be more genera, but it used "downscale" which may have issues if deg_step is not a multiple of the higres grid
% 2.3 Add emissivity - wisc - has a funny error catching thing...
% 2.3 Add rho
% 3.1 Run Klayuers
% 3.2 Run Sarta
% 3.3 Read in calculations
% 4.0 Save calc file
% 4.1 Error check




rn='sarta_core (IASI)';
greetings(rn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Setup 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iasi_paths

% SLEEP for a bit - to ease the cluster load !!
system('sleep $(( $RANDOM % 30 ))');


if ~exist('model','var')
  error(['Missing "model" variable']);
end
if ~exist('emis','var')
  error(['Missing "emis" variable']);
end
if ~exist('sarta','var')
  sarta='clr';
end

% 
clear f
file_list = findfiles(input_glob);
say(['Found ' num2str(length(file_list)) ' files to add model data'])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Loop over files 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for f = file_list

  try % if a file goes bad skip it and go to the next

    bn = basename(f{1});

    outfile = [dirname(f{1}) '/' model '.' sarta '.' basename(f{1},'_1')];
    say(['Outfile: ' outfile])

    % Check if file already exists. 
    if exist([outfile '_1Z'],'file') || exist([outfile],'file');
      say('Output file exists')
      tdir0=dir(f{1});
      if exist([outfile '_1Z'],'file')
        tdir1=dir([outfile '_1Z']);
      else
        tdir1=dir([outfile]);
      end
      if(tdir1.datenum<tdir0.datenum)
	say('   and it is OLDER than base file... Regenerating!');
      else
	say('   but it is NEWER then base file... Continuing to next file...');
	continue;
      end
    end

    % declare we are working on this day so we don't have two processes working on the same day
    if ~lockfile(outfile); 
      say('WARNING: LOCK FILE already exists for this file! Continuing to next file...');
      continue; 
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Read input file
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [head hattr prof pattr] = rtpread_12(f{1});




    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Remove robs1 and calflag to save space (those exist on the base file)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isfield(prof,'robs1'); prof = rmfield(prof,'robs1'); end
    if isfield(prof,'calflag'); prof = rmfield(prof,'calflag'); end
    hattr = set_attr(hattr,'rtpfile',f{1},'header');
    pattr = set_attr(pattr,'rtime','Seconds since 2000','profiles');
    %hattr = set_attr(hattr,'prod_code','process_l1bcm.m');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Mode Matchup 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp(model,'ecm')
      say(['  adding ecm profiles to ' bn])
      try
    	[head hattr prof pattr] =rtpadd_ecmwf_data(head,hattr,prof,pattr);
      catch
	say(['ERROR: Reading in ecmwf data. Continuing to next file...'])
	continue
      end
    elseif strcmp(model,'era')
      say(['  adding era profiles to ' bn])
      %system(['/asl/opt/bin/getera ' datestr(JOB(1),'yyyymmdd')])
      if strcmp(sarta,'cld')
        [head, hattr, prof, pattr] = rtpadd_era_data(head,hattr,prof,pattr,{'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'});
      else
        [head, hattr, prof, pattr] = rtpadd_era_data(head,hattr,prof,pattr,{'SP','SKT','10U','10V','TCC','CI','T','Q','O3'});
      end
      %[head hattr prof pattr] =rtpadd_era_data(head,hattr,prof,pattr);
    elseif strcmp(model,'gfs')
      say(['  adding gfs profiles to ' bn])
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
      say(['  adding wis emissivity to ' bn])
      dv = datevec(JOB(1));
      try

	[prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');

      catch err

	Etc_show_error(err);
	say('Something went wrong...');

	if dv(3) > 15
	  say('   trying next month...');
	  dv = datevec(JOB(1) + 30);
	  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
	else
	  say('   trying previous month...');
	  dv = datevec(JOB(1) - 30);
	  [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
	end
      end
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



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Run Klayers and Sarta
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    say(['  setting sarta attributes in ' bn])
    hattr = rm_attr(hattr,'sarta');
    hattr = rm_attr(hattr,'klayers');

    if strcmp(sarta,'clr')
      %sarta_exec='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';
      sarta_exec='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte_swch4';
    elseif strcmp(sarta,'cld')
      sarta_exec='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte_swch4';
      iasi_cloudy
    else
      error('unknown sarta specification');
    end
    klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
    hattr = set_attr(hattr,'sarta_exec',sarta_exec);
    hattr = set_attr(hattr,'klayers_exec',klayers_exec);

    % if we are using static layers
    %[head,prof] = klayers_filt(head,prof,1025);

    % write out an rtp file for sarta
    %say(['  writing out rtp file for sarta ' bn])
    tmp = mktemp();
    outfiles = rtpwrite_12(tmp,head,hattr,prof,pattr);

    for tmp1 = outfiles
      tmp1 = tmp1{1};
      say(['  running klayers on ' bn ' (' tmp1 ')'])
      tmp2 = [tmp1 'b'];
      out = system([get_attr(hattr,'klayers_exec') ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
      unlink(tmp1)
      if(out ~= 0)
	say(['ERROR: Klayers run Failed!']);
	error(['  error running klayers on ' bn]); 
      end

      say(['  running sarta on ' bn ' (' tmp2 ')'])
      %out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
      disp([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' ']);
      out = system([get_attr(hattr,'sarta_exec') ' fin=' tmp2 ' fout=' tmp1 ' ']);
      unlink(tmp2)
      if(out ~= 0)
	say(['ERROR: Sarta run Failed!']);
	error(['  error running sarta on ' bn]); 
      end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Reading in final result section and copying rcalc over to previous rtp structure
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    say(['  reading in calcs for ' bn])
    if ~exist(tmp,'file')
      say(['Temporary file is GONE!?!?!']);
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
    say(['  writing out ' outfile]);
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

  catch err
    Etc_show_error(err)
    say(['Dump "prof":']);
    prof
    say(['Something went wrong! Continuing to next file...']);
  end

end


farewell(rn);
% END OF SCRIPT
