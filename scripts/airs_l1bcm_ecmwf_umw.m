%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       AIRS L1BCM PRODUCTION M FUNCTION
%
% This script is part of the AIRS L1bCM production
% See "airs_l1bcm_proc_run.sh" to know how to 
% run this on the TARA cluster.
% 
% (C) ASL Group - 2013 - GPL V.3
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% function airs_l1bcm_proc(sdate, edate)
%
%   Acumulate AIRS data from sdate to edate, add model
%   and compute radiances. 
%
%   Input:
%   sdate - matlab start date (inclusive)
%   edate - matlab end date (exclusive)
%
% B.I. Aug.2013

function airs_l1bcm_ecmwf_umw(sdate, edate, root)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %greetings('airs_l1bcm_ecmwf_umw');

  % To make edate exclusive, the simplest way is to 
  % remove 1s from it. 

  edate = edate - 1.1573e-5;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation and set 
  % environment variable

  % Get or Set Environment Variables
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
  % Download AIRS data
  %
  % Set where to download (usually relative to root) and call getairs
  % This routine uses the RTPROD environment variable:

  % Set where data will be (relative to root) 
  asldata=[root '/data/airs'];
  system('echo $RTPROD');
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
  % output_file = make_rtprod_filename('AIRS', 'l1bcm', 'merra', 'udz','calc', '', [sdate edate], version,'rtp',[pwd '/dump/']);
  %
  % We use the rtp_str2name.m function that takes a predefined
  % name structure and convert it on a filename string.

  % output obs filename
  str_obs1.root 	= [pwd '/dump/' ];
  str_obs1.instr	= 'airs';
  str_obs1.sat_data	= 'l1bcm';
  str_obs1.atm_model 	= 'ecmwf';	% Will contain profile information
  str_obs1.surfflags 	= 'umw'; 	% Will contain the following:
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

  % Replace rtprod_airs by rtprod_airs_0
  irpl = strfind(output_file_obs1,'rtprod_airs');
  output_file_obs1([irpl:end+2]) = ['rtprod_airs_0/' output_file_obs1(irpl+12:end)];
  irpl = strfind(output_file_calc,'rtprod_airs');
  output_file_calc([irpl:end+2]) = ['rtprod_airs_0/' output_file_calc(irpl+12:end)];



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
    [head hattr profi pattr] = rtpmake_airs_l1bcm_datafile(file_list(ifile)); 
    % L1bcm files are daily. 
    % We must subset for the desired time span
    % Subset for desired time
    %itime = find(profi.rtime >= mattime2tai(sdate,1993) & profi.rtime< mattime2tai(edate,1993));
    %prof(ifile) = ProfSubset2(profi, itime);
    
    % I don't want to subset, want the whole daily file.
    prof(ifile) = profi;
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
  [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);

  %[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
  %[head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr, root);
  [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % This data set is already a "clear" set
  % Airs L1Bcm is alreay clear subset.


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
    [ head hattr profx pattr] = SartaRun(tempfile, 5);
    % I don't care about all the irrelevant fields created here.
    % Simply extract rcalc    
    prof.rcalc = profx.rcalc;
    clear profx

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 7 - Save Calc Data - but remove ATM model 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Trim and save file

  disp(['Saving data ' output_file_calc]);
  prof = rmfield(prof,{'gas_1','gas_2','gas_3','gas_4','gas_5','gas_6',...
                       'gas_9','gas_12','plevs','palts','ptemp'});
  [head hattr prof pattr] = rtptrim(head,hattr,prof,pattr,'parent',...
                                    output_file_obs1);

  rtpwrite(output_file_calc, head, hattr, prof, pattr);
  %greetings('airs_l1bcm_ecmwf_umw');

end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
