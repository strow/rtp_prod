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
%   sdate - matlab start date 
%   edate - matlab end date
%
% B.I. Aug.2013

function co2_lsqret_airs_l1bcm_merra_udw(sdate, edate, root)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set paths for CO2 retrieval

  addpath /home/imbiriba/projects/CO2_process/code
  startup_breno

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation and set 
  % environment variable

  rtprod = '/home/imbiriba/git/rtp_prod';
  matlib = '/home/imbiriba/git/matlib';

  % Define code pathes
  addpath(rtprod);
  paths

  % Export environment variable
  setenv('RTPROD',rtprod);


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
  str_obs1.root 	= [pwd '/dump'];
  str_obs1.instr	= 'airs';
  str_obs1.sat_data	= 'l1bcm';
  str_obs1.atm_model 	= 'merra';	% Will contain profile information
  str_obs1.surfflags 	= 'udw'; 	% Will contain the following:
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

%  % output calc filename
%  str_calc 		= str_obs1;
%  str_calc.calc 	= 'calc';	% Same as obs, but with calc
%  str_calc.file_type	= 'rtpZ';	% Will be an rtpZ file
%  output_file_calc = rtp_str2name(str_calc);

  % Get output directory
  output_file_dir = fileparts(output_file_obs1);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output Files:');
%  disp(output_file_obs1);
%  disp(output_file_calc);

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
    itime = find(profi.rtime >= mattime2tai(sdate,1993) & profi.rtime< mattime2tai(edate,1993));
    prof(ifile) = ProfSubset2(profi, itime);

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
  [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % This data set is already a "clear" set
  % Airs L1Bcm is alreay clear subset.


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 6 - Retrieve CO2 using the LSQ LW and SW 
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [yyyy mm dd] = datevec(sdate);
  par = struct(... 
         'dirname',str_obs1.root, ...
         'dataorigin',[str_obs1.instr '_' str_obs1.sat_data],...
	 'profileorigin',[str_obs1.atm_model '_' str_obs1.surfflags],...
	 'date',[yyyy mm dd],...
	 'filetype',str_obs1.file_type,...
	 ...
	 'instr','AIRS',...
	 'klayers','klayersV205_BinV201_wetwater',...
	 'sarta','sarta_apr08_m140 lrhot=true',...
	 'retrievalmethod','reset',...
	 'co2prior','385ppm',...
	 'robs',str_obs1.sat_data,...
	 'wave','sw_2389_2392_2415_2418',...
	 'keepfile',false,...
	 'rundiags',true,...
	 'deltas',[1.01 1],...
	 'psaveopt','basic/chans/alts',...
	 'dojac100',true,...
	 'dodCdCi',true,...
	 'dodCdTi',true,...
	 'dodCdWi',true,...
	 'do_jac_after_reset',true,...
	 'jac_append_locally',false);

  CO2process_RTP(head, hattr, prof, pattr, par);

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
    [ head hattr prof pattr] = SartaRun(tempfile, 5);
    


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

end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
