%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       CRIS CLEAR PRODUCTION M FUNCTION
%
% This script is part of the CrIS Clear production
% See "cris_clear_proc_run.sh" to know how to 
% run this on the TARA cluster.
% 
% (C) ASL Group - 2013 - GPL V.3
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% function cris_clear_proc(sdate, edate)
%
%   Acumulate CrIS data from sdate to edate, add model
%   and compute radiances. 
%
%   Input:
%   sdate - matlab start date 
%   edate - matlab end date
%
% B.I. Aug.2013

function cris_ccast_hr(sdate, edate, root)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation and set 
  % environment variable


  rtprod = getenv('RTPROD');
  if(strcmp(rtprod,''))
    rtprod = '/asl/rtp_prod';
    setenv('RTPROD',rtprod);
  end

  matlib = getenv('MATLIB');
  if(strcmp(matlib,''))
    matlib = '/asl/matlib';
    setenv('MATLIB',matlib);
  end



  % Define code pathes
  addpath(rtprod);
  paths

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get code version number
  version = version_number();


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set data root - for input and output
  %root = '/home/imbiriba/git/rtp_prod/testsuit/asl'
  if(nargin()<3)
    root = '/asl/';
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Download CRIS data
  %
  % I Don't know how to do that. 
  % CrIS data seems to appear magically at a 
  % default place.
  %
  % Hence, copy data manually


  % Set where data will be (relative to root) 
  asldata=[root '/data'];



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Input / Output files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Find existing input files (according 
  %                to provided date ranges)
  file_list = cris_ccast_filenames(sdate,edate,asldata,'ccast_sdr60');


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Make output file name - CrIS HighRes has not fast model - we use
  % IASI's sarta, which has to be done for all the channels. 
  % As the clear detection code has to run calcs, in the HR case we
  % keep the calcs in the RTP structure. 
  % Hence we will have only one output file, the calc file.
  % 
  % We use the rtp_str2name.m function that takes a predefined
  % name structure and convert it on a filename string.

  % output obs filename
  str_obs1.root 	= [pwd '/dump'];
  str_obs1.instr	= 'cris';
  str_obs1.sat_data	= 'ccast_hr';
  str_obs1.atm_model 	= 'ecmwf';	% Will contain profile information
  str_obs1.surfflags 	= 'umw'; 	% Will contain usgs topo (u),
                                        % Model stemp (m), Wisc emis (w)
  str_obs1.calc 	= 'calc';
  str_obs1.subset 	= '';	% clear subset only 
  str_obs1.infix 	= '';
  str_obs1.mdate 	= [sdate edate];
  str_obs1.ver 		= version;
  str_obs1.file_type 	= 'rtp';

  output_file_obs1 = rtp_str2name(str_obs1);


  % Get output directory
  output_file_dir = fileparts(output_file_obs1);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output Files:');
  disp(output_file_obs1);

  if(~exist(output_file_dir,'dir'))
    disp(['Creating output directory']);
    mkdir(output_file_dir);
  end

  % Test for file existence
  if(exist(output_file_obs1 ,'file'))
    disp(['Attention: Output file "' output_file_obs1 '" already exist. Skipping...']); 
    return
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 3 - Make RTP Structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read CrIS Data:
  for ifile=1:numel(file_list)
    [head hattr profi pattr] = sdr2rtp_bc(file_list{ifile}); 

    % Sometimes you'd like to to a time subsetting here
    % but this is not necessary for sdr60 data which will
    % "spill over" the time bin just a little bit.

    % Subset for desired time
    %itime = find(profi.rtime >= mattime2tai(sdate,2000) & ...
    %             profi.rtime <  mattime2tai(edate,2000));
    %prof(ifile) = ProfSubset2(profi, itime);

    prof(ifile) = profi;

  end
  clear profi;
  prof = structmerge(prof);
  head.ngas = 0;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Remove buggy CrIS rtime, rlat, and rlon
  [head prof] = cris_filter_bad_data(head, prof);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
  % add version number on header attributes
  hattr = set_attr(hattr,'version',version);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 4 - Perform Desired Operations.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Add Model Information

  [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr,root);
  [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);

  %[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
  [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);
 

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do clear selection - for now this is instrument dependent
  % 
  % For CrIS 888 (high res) we also perform the calculations.
  % 
  instrument='CRIS_888'; %'IASI','CRIS'
  [head hattr prof pattr summary] = ...
                   compute_clear_wrapper(head, hattr, prof, pattr, instrument);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Save Obs File + Model information
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [dd, ~, ~] = fileparts(output_file_obs1);
  if(~exist(dd,'dir'))
    system(['mkdir -p ' dd]);
  end 
  disp(['Saving ' output_file_obs1]);
  rtpwrite(output_file_obs1, head,hattr,prof,pattr);



% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
