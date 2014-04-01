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
% function airs_l1b_ecmwf_umw(sdate, edate, root)
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

function airs_l1bct_ecmwf_umw(sdate, edate, root)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Say that I'm starting
  disp(['Running ' mfilename()])



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Setup Cloudy parameters:

  run_sarta.clear = +1;
  run_sarta.cloud = +1;
  run_sarta.cumsum = 9999;

  %codeX = 0; %% use default with A. Baran params
  codeX = 1; %% use new     with B. Baum, P. Yang params

  % 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
  disp('Not trying to download data...');
  %airs_l1b_download(sdate, edate, asldata);




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Input / Output files
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Find existing input files (according 
  %                to provided date ranges)
  file_list = airs_l1b_filenames(sdate,edate,asldata);

  if(numel(file_list)==0)
    disp('No AIRS file found.');
    return
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Make output file name
  % output_file = make_rtprod_filename('AIRS', 'l1bcm', 'merra', 'udz','calc', '', [sdate edate], version,'rtp',[pwd '/dump/']);
  %
  % We use the rtp_str2name.m function that takes a predefined
  % name structure and convert it on a filename string.

  % output obs filename
  %str_obs1.root 	= [pwd '/dump'];
  str_cld.root 	= ['/asl'];
  str_cld.instr	= 'airs';
  str_cld.sat_data	= 'l1b';
  str_cld.atm_model 	= 'era';	% Will contain profile information
  str_cld.surfflags 	= 'umw'; 	% Will contain the following:
                         %  1. Topography: 'u' - usgs      / '_' - none
                         %  2. Stemp     : 'd' - diurnal   / 'm' - model default
                         %  3. Emissivity: 'z' - DanZhou's / 'w' - Wiscounsin

                                        % sergio's stemp (d), Wisc's emis (w)
  str_cld.calc 	= '';
  str_cld.subset 	= 'ctrtrk';	% clear subset only 

  % Set Type of cloudy calc (sarta) and corresponding file name.
  if(codeX==0)
    str_cld.infix         = 'sarta_baran_ice';
    run_sarta.sartacloud_code = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte';
  elseif(codeX==1)
    str_cld.infix         = 'sarta_baum_ice';
    run_sarta.sartacloud_code = '/home/sergio/SARTA_CLOUDY/BinV201/sarta_apr08_m140x_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3';
  else
    error('Wrong cloudy code version - set "codeX" to 0 or 1.');
  end

  str_cld.mdate 	= [sdate edate];
  str_cld.ver 		= version;
  str_cld.file_type 	= 'rtp';

  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  output_file_cld = rtp_str2name(str_cld);

  % Get output directory
  output_file_dir = fileparts(output_file_cld);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output Files:');
  disp(output_file_cld);

  if(~exist(output_file_dir,'dir'))
    disp(['Creating output directory']);
    mkdir(output_file_dir);
  end


  % I'll check if the output file already exists 
  % i.e. NO OVERWRITE

  if(exist(output_file_cld,'file'))

    disp(['File ' output_file_cld ' already exists.']);
    return

  else

    disp(['Creating ' output_file_cld '.']);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 3 - Make RTP Structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read AIRS Data:
  for ifile=1:numel(file_list)
    [head hattr prof pattr] = rtpmake_airs_l1b_datafile(file_list(ifile)); 
    % L1b files are Granule Files. 

    % I want to have the clear flag in it. 
    % This requires running the clear detection, which 
    % for AIRS, requires have more than just a center track
    % (needs 3x3s)
    % 
    % So I'll do the necessary operations inside the loop, 
    % the strip the center track, and then merge.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % 4 - Perform Desired Operations.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Add Model Information

    [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr,root);

    cldfields = {'SP','SKT','10U','10V','TCC','CI','T','Q','O3',...  
	      'CC','CIWC','CLWC'};
    [head hattr prof pattr] = rtpadd_era_data(head,hattr,prof,pattr,cldfields);

    %[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
    %[head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr, root);
    [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do clear selection - for now this is instrument dependent
    instrument='AIRS'; %'IASI','CRIS'
    [head hattr prof pattr summary] = ...
		     compute_clear_wrapper(head, hattr, prof, pattr, instrument);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Center Track Subset
    % keep only center track data - xtrack=[44 45]
    ictrtrk = find(prof.xtrack == 45 | prof.xtrack == 46);
    prof = ProfSubset2(prof, ictrtrk);


    % Now save just the stripped guy:
    % using cell array here to facilitate the manual joining.
    profx{ifile} = prof;  
  end
  clear prof;


  % There's an issue with emissivity: Ice emissivity is had 100 points.
  % this usually is not a problem we're calling the emissivity routine for
  % the whole file, but here we're calling for each file then merging 
  % manually. Hence we must make sure we got the dimensions right.
  % 
  % I'll *remove* the emissivity fields (nemis,emis,efreq,nrho,rho) now
  % merge all the structure, and then add it again for the whole thing.

  for ii=1:numel(profx)
    profx{ii} = rmfield(profx{ii},{'nemis','emis','efreq','nrho','rho'});
  end
  prof = structmerge(profx);
  clear profx;
  % Now, add emissivity:
  [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
  % add version number on header attributes
  hattr = set_attr(hattr,'version',version);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Running Cloudy Wrapper
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Run Sergio's wrapper
  prof = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
  % Same sarta executable name
  hattr = set_attr(hattr,'sarta',run_sarta.sartacloud_code);
  % Set pfields to indicate calcs
  [pf1 pf2 pf3] = pfields2bits(head.pfields);
  pf2=1;
  head.pfields = bits2pfields(pf1, pf2, pf3);




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 6 - Save Cld File + Model information
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  disp(['Saving ' output_file_cld]);
  rtpwrite(output_file_cld, head,hattr,prof,pattr);

  end



  farewell(mfilename());
  
end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
