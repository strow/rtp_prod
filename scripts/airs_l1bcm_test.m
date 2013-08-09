%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RTP CORE SAMPLE SCRIPT
%
% 
% AIRS CLEAR TEST 1
%
% Create one hour of clear data using 
% production routines.
%
% To generate one hour of data I need 10 L1B granules
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   Acumulate AIRS data from sdate to edate, add model
%   and compute calculations

%   Parameters:
%   sdate - matlab start date
%   edate - matlab end date
%   root  - location of the "asl" tree (/asl/)
%   rtprod - location of rtp_prod code

function airs_l1bcm_test(sdate, edate)



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation  and set environment variable
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
%  root = '/home/imbiriba/git/rtp_prod/testsuit/asl'
  root = '/asl/';


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Download AIRS data
  %
  % Set where to download (usually relative to root) and call getairs
  % This routine uses the RTPROD environment variable:

  asldata=[root '/data/airs'];
  airs_l1bcm_download(sdate, edate, asldata);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Input/Output files

  % Find existing input files (according to provided date ranges)
  file_list = airs_l1bcm_filenames(sdate,edate,asldata);

  % Make output file name
  output_file = make_rtprod_filename('AIRS', 'l1bcm', 'merra', 'udz','calc', '', [sdate edate], version,'rtp',[pwd '/dump/']);

  output_file_dir = fileparts(output_file);

  disp('Input Files:');
  for iff=1:numel(file_list)
    disp(file_list{iff});
  end

  disp('Output File:');
  disp(output_file);

  if(~exist(output_file_dir,'dir'))
    disp(['Creating output directory']);
    mkdir(output_file_dir);
  end



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Make RTP Structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read AIRS Data:
  for ifile=1:numel(file_list)
    [head hattr profi pattr] = rtpmake_airs_l1bcm_datafile(file_list(ifile)); 

    % Subset for desired time
    itime = find(profi.rtime >= AirsDate(sdate,-1) & profi.rtime< AirsDate(edate,-1));
    prof(ifile) = ProfSubset2(profi, itime);

  end
  clear profi;
  prof = structmerge(prof);

  % add version number on header attributes
  hattr = set_attr(hattr,'rev_rtp_core_hr',version);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 3 - Perform Desired Operations.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Add Model Information

  [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr,root);
  [head hattr prof pattr] = rtpadd_merra(head,hattr,prof,pattr,root);

  %% Comments: an older Scott routine used to do this:
  %  udef(1) = L1B salti, udef(2) = L1B landfrac
  %  udef(3) = model spres 

  [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
  [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr, root);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do clear selection - for now this is instrument dependent

  % Airs L1Bcm is alreay clear subset.


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 4 - Compute Calculated Radiances
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % See KlayersRun and SartaRun
    % SartaRun is not configured for running with HR cris yet. 
    disp('Computing calculated Radiances');

    tempfile = mktemp('temp.rtp');
    KlayersRun(head,hattr,prof,pattr,tempfile,11);

    [ ht htt pt ptt ] = SartaRun(tempfile, 5);
    
    prof.rcalc = pt.rcalc;
    clear ht htt pt ptt 


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Save Data
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save file

  disp('Saving data');
  rtpwrite(output_file, head, hattr, prof, pattr);


end

