function [head hattr prof pattr] = rtpmake_airs_l1b_datafiles(files)
% function [head hattr profi pattr] = rtpmake_airs_l1b_datafiles(files)
% 
% files - list of l1b AIRS files
%
% Breno Imbiriba - 2013.06.25
% Based on excerpts of Paul's rtp_core.m 


  nodata = -9999;


  for ifile = 1:length(files)  % loop over granule files for a day

    disp(['Loading file ' files{ifile}]);


    %%%%%%
    % 
    % Read AIRS Data File
    %
    %%%%%%

    [eq_x_tai, f, gdata]= readl1b_all(files{ifile});


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    % Construct PROFILE structure
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    data.findex = int32(gdata.findex(:)');
    data.atrack = int32(gdata.atrack(:)'); %'
    data.xtrack = int32(gdata.xtrack(:)'); %'

    data.zobs = single(gdata.zobs(:)'); %'
    data.calflag = single(gdata.calflag);

    data.robs1 = single(gdata.robs1);

    data.rlat = single(gdata.rlat(:)');  %'
    data.rlon = single(gdata.rlon(:)');  %'
    data.rtime = gdata.rtime(:)';  %'

    data.scanang = single(gdata.scanang(:)');
    data.satazi = single(gdata.satazi(:)'); %'
    data.satzen = single(gdata.satzen(:)'); %'
    data.solazi = single(gdata.solazi(:)'); %'
    data.solzen = single(gdata.solzen(:)'); %'

    data.salti = single(gdata.salti(:)');
    data.landfrac = single(gdata.landfrac(:)');

    nok = length(data.rtime);


    %%%%
    %
    % Fill out the iudef values
    %
    %%%%
    
    data.iudef = int32(nodata*ones(10,nok));


    %%
    % fill out the iudef values
    %% 

    data.udef = single(nodata*ones(20,nok));
    data.udef(1,:) = eq_x_tai(:)' - gdata.rtime(:)';


    prof(ifile) = data;

    clear data;

  end   % loop over files

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
	  {'header' 'instid' 'AIRS'} };
  %
  pattr={ {'profiles' 'rtime' 'seconds since 1 Jan 1993'}, ...
	  {'profiles' 'robsqual' '0=good, 1=bad'}, ...
	  {'profiles' 'udef(1,:)' 'eq_x_tai - rtime'} };

  % PART 1
  head.instid = 800; % AIRS 
  head.nchan = length(part1);
  head.ichan = part1;
  head.vchan = vchan(part1);
  %set_attr(hattr,'rtpfile',[rtp_outfile]);

end
