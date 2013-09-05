function [head hattr prof pattr] = rtpmake_airs_l1bcm_datafiles(files)
% function [head hattr profi pattr] = rtpmake_airs_l1bcm_datafiles(files)
% 
% files - list of l1bcm AIRS files
%
% Breno Imbiriba - 2013.08.06
% Based on excerpts of Paul's rtp_core_l1bcm.m 



  nodata = -9999;


  for ifile = 1:length(files)  % loop over granule files for a day

    disp(['Loading file ' files{ifile}]);


    %%%%%%
    % 
    % Read AIRS Data File
    %
    %%%%%%

    [data, pattr, f] = readl1bcm_v5_rtp(files{ifile});

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    % Construct PROFILE structure
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    nok = length(data.rtime);

    disp('No satazi for l1bcm as it is...');
    disp('No solazi for l1bcm as it is...');
    disp('No calflag for l1bcm as it is...');

    prof(ifile) = data;

  end   % loop over files

  prof = structmerge(prof);

  nchan = size(prof.robs1,1);
  ichan = (1:nchan)';

  % Determine channel freqs
  vchan = f(:);

  %%%%%%%%%  Make a HEADER structure
  head = struct;
  head.pfields = 4;
  head.ptype = 0;
  head.ngas = 0;

  head.instid = 800; % AIRS 
  head.nchan = length(ichan);
  head.ichan = ichan;
  head.vchan = vchan(ichan);
  %set_attr(hattr,'rtpfile',[rtp_outfile]);
  
  % Assign RTP attribute strings
  hattr={ {'header' 'pltfid' 'Aqua'}, ...
	  {'header' 'instid' 'AIRS'} };


end

