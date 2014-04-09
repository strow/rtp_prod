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
% function cris_clear_proc(flist)
%
%   Acumulate CrIS data in files in flist, add model
%   and compute radiances. 
%
%   Input:
%   flist - a cell array list of file names
%
% B.I. Oct.2013

function cris_fname_proc(flist)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation and set 
  % environment variable

  % At this point no path has been set. 
  % Look at the shell environment variables.
  % If they don't exist, set to default pathes.
  
  rtprod = getenv('RTPROD');
  if(strcmp(rtprod,''))
    disp('rtprod does not exist - using default /asl/rtprod/');
    rtprod = '/asl/rtp_prod';
    setenv('RTPROD',rtprod);
  end

  matlib = getenv('MATLIB');
  if(strcmp(matlib,''))
    disp('matlib does not exist - using default /asl/matlib/');
    matlib = '/asl/matlib';
    setenv('MATLIB',matlib);
  end

  % Define code pathes - (needs rtprod - a bit circular...)
  disp(['rtprod is ' rtprod]);
  disp(['matlib is ' matlib]);
  addpath(rtprod);
  paths
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get code version number
  version = version_number();


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set data root - for input and output
  root = '/asl/';



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Input / Output files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % If flist is a string, put it in a cell 
  % array
  if(iscell(flist))
    file_list = flist;
  elseif(isstr(flist))
    file_list = {flist};
  end

  % Compute start time and end time for each file.
  % If the list contain repetitions, take the newest ones.
  % (based on cris' file ctime)
  [sdate edate file_list] = cris_noaa_ops_date_from_file(file_list);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Make output file name - we will split obs and calcs
  %
  % We use the rtp_str2name.m function that takes a predefined
  % name structure and convert it on a filename string.

  % output obs filename
  str_obs1.root 	= ['/asl/'];
  str_obs1.instr	= 'cris';
  str_obs1.sat_data	= 'sdr60_noaa_ops';
  str_obs1.atm_model 	= 'ecmwf';	% Will contain profile information
  str_obs1.surfflags 	= 'umw'; 	% Will contain usgs topo (u),
                                        % base model stemp (m), Wisc emis (w)
  str_obs1.calc 	= '';
  str_obs1.subset 	= '';	% clear subset only 
  str_obs1.infix 	= '';
  str_obs1.mdate 	= [min(sdate) max(edate)];
  str_obs1.ver 		= version;
  str_obs1.file_type 	= 'rtp';

  output_file_obs1 = rtp_str2name(str_obs1);

  % output calc filename
  str_calc 		= str_obs1;
  str_calc.calc 	= 'calc';	% Same as obs, but with calc
  str_calc.file_type	= 'rtpZ';	% Will be an rtpZ file
  output_file_calc = rtp_str2name(str_calc);

  % Get output directory
  output_file_dir = fileparts(output_file_obs1);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output Files:');
  disp(output_file_obs1);
  disp(output_file_calc);

  if(~exist(output_file_dir,'dir'))
    disp(['Creating output directory']);
    mkdir(output_file_dir);
  end

  % Test for file existence
  if(exist(output_file_calc ,'file') & exist(output_file_obs1 ,'file'))
    disp(['Attention: Output files "' output_file_obs1 '" and "' output_file_calc '" already exists. Skipping...']); 
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
    [head hattr profi pattr] = sdr2rtp_h5(file_list{ifile}); 

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
  instrument='CRIS'; %'IASI','CRIS'
  [head hattr prof pattr summary] = ...
                   compute_clear_wrapper(head, hattr, prof, pattr, instrument);


  %%%%%% DON'T %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Do subset, if wanted. (remove coasts (16) also).
  %%iclear = find(prof.iudef(1,:)>0 & prof.iudef(1,:)<16); 
  %%[head prof] = subset_rtp(head, prof, [],[],iclear);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Save Obs File + Model information
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  disp(['Saving ' output_file_obs1]);
  rtpwrite(output_file_obs1, head,hattr,prof,pattr);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 6 - Compute Calculated Radiances
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % See KlayersRun and SartaRun
    % SartaRun is not configured for running with HR cris yet. 
    disp('Computing calculated Radiances');

    tempfile = mktemp('temp.rtp');
    KlayersRun(head,hattr,prof,pattr,tempfile,11);

    [ head hattr prof pattr] = SartaRun(tempfile, 12);
    


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 7 - Save Calc Data - but remove ATM model 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Trim and save file

  disp(['Saving data ' output_file_calc]);
  [head hattr prof pattr] = rtptrim_ptype_0(head, hattr, prof, pattr, output_file_obs1);
  rtpwrite(output_file_calc, head, hattr, prof, pattr);


% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
