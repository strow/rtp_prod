function [head hattr prof pattr] = rtpmake_airs_l1b_datafiles(files)
% function [head hattr profi pattr] = rtpmake_airs_l1b_datafiles(files)
% 
% files - list of l1b AIRS files
%
% Breno Imbiriba - 2013.09.04
% Based on excerpts of Paul's rtp_core.m 



  nodata = -9999;

  if(~iscell(files))
    files={files};
  end

  for ifile = 1:length(files)  % loop over granule files for a day

    disp(['Loading file ' files{ifile}]);


    %%%%%%
    % 
    % Read AIRS Data File
    %
    %%%%%%

    [eq_x_tai, f, data] = readl1b_all(files{ifile});

    prof(ifile) = data;

  end   % loop over files

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Construct PROFILE structure
  % 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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


  % Declare pattr:
  pattr = set_attr('profiles','robs1',files{ifile});
  pattr = set_attr(pattr, 'rtime','Seconds since 0z, 1 Jan 1993');
  pattr = set_attr(pattr, 'landfrac','AIRS Landfrac');


end

