% Produce RTP files (obs and calcs) from AIRS L1BCM data and MODEL.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       AIRS L1BCM PRODUCTION M FUNCTION
%
% This script is part of the AIRS L1bCM production
% See "airs_l1bcm_****_run.sh" to know how to 
% run this on the TARA cluster.
% 
% (C) ASL Group - 2013 - GPL V.3
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% function airs_l1b_merra_udz(sdate, edate, root)
%
%   Acumulate AIRS data from sdate to edate, add model
%   and compute radiances. 
%
%   Input:
%   sdate - matlab start date 
%   edate - matlab end date

%   Optional Input: 
%   root  - Root directory of the data tree (default = "$PWD/dump/")
%           For most of the code we assume 
%           that files are saved bellow a "root" 
%           directory: 
%           $root/data/rtprod_airs/....
%           
%           This is a bit rigid, but lets you have 
%           your own repository of data with the same
%           file structure.

% B.I. Aug.2013

function airs_l1b_merra_udz(sdate, edate, root)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Say that I'm starting
  greetings(mfilename())


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation and set 
  % environment variable.

  % At this point no path has been set. 
  % Look at the shell environment variables.
  % If they don't exist, set to default pathes.

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

  % Set code pathes
  addpath(rtprod);
  paths

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get code version number
  version = version_number();


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Define the "data root" - 
  % Set data root - for input and output
  %root = '/home/imbiriba/git/rtp_prod/testsuit/asl'
  if(nargin()<3)
    root = '/asl/';
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Download AIRS data
  %
  % Set where to download (usually relative to root) and call getairs
  % This routine uses the RTPROD environment variable:

  % Set where data will be (relative to root) 
  asldata=[root '/data/airs'];
  airs_l1bcm_download(sdate, edate, asldata);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Input / Output files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Find existing input files (according 
  %                to provided date ranges)
  file_list = airs_l1bcm_filenames(sdate,edate,asldata);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Make output file name
  %
  % We use the rtp_str2name.m function that takes a predefined
  % name structure and convert it on a filename string.

  % output obs filename
  str_obs1.root 	= [pwd '/dump'];
  str_obs1.instr	= 'airs';
  str_obs1.sat_data	= 'l1b';
  str_obs1.atm_model 	= 'merra';	% Will contain profile information
  str_obs1.surfflags 	= 'udz'; 	% Will contain the following:
                         %  1. Topography: 'u' - usgs      / '_' - none
                         %  2. Stemp     : 'd' - diurnal   / 'm' - model default
                         %  3. Emissivity: 'z' - DanZhou's / 'w' - Wiscounsin

                                        % sergio's stemp (d), Wisc's emis (w)
  str_obs1.calc 	= '';
  str_obs1.subset 	= '';	% clear subset only 
  str_obs1.infix 	= '';
  str_obs1.mdate 	= [sdate edate];
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



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 3 - Make RTP Structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read AIRS Data:
  for ifile=1:numel(file_list)
    [head hattr profi pattr] = rtpmake_airs_l1b_datafile(file_list(ifile)); 
    % L1b files are Granule Files. 
    % Keep them as they are

  end
  clear profi;
  prof = structmerge(prof);

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
  [head hattr prof pattr] = rtpadd_merra(head,hattr,prof,pattr,root);

  [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
  %[head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr, root);
  %[head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);
  [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr, root);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do clear selection - for now this is instrument dependent
  instrument='AIRS'; %'IASI','CRIS'
  [head hattr prof pattr summary] = ...
                   compute_clear_wrapper(head, hattr, prof, pattr, instrument);


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

  % See help SartaRun for the types of Sarta available
  [ headx hattrx profx pattrx] = SartaRun(tempfile, 5);

  % Grab rcalc and the Sarta name attribute
  sartaname = get_attr(hattrx,'sarta');
  hattr = set_attr(hattr, 'sarta', sartaname);
  prof.rcalc = profx.rcalc;
  head.pfields = headx.pfields;

  clear headx hattrx profx pattrx

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 7 - Save Calc Data - but remove ATM model 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Trim and save file

  disp(['Saving data ' output_file_calc]);

  [head hattr prof pattr] = rtptrim(head,hattr,prof,pattr,'parent',...
                                    output_file_obs1,'allowempty');

  rtpwrite(output_file_calc, head, hattr, prof, pattr);
  farewell(mfilename());
  
end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
