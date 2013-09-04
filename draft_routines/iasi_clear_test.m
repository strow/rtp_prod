%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RTP CORE SAMPLE SCRIPT
%
% 
% IASI CLEAR TEST 1
%
% Create one hour of clear data using 
% production routines.
%
% To generate one hour of data I need 10 L1B granules
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   Acumulate IASI data from sdate to edate, add model
%   and compute calculations

%   Parameters:
%   sdate - matlab start date
%   edate - matlab end date
%   root  - location of the "asl" tree (/asl/)
%   rtprod - location of rtp_prod code

function iasi_clear_test(sdate, edate)



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
  % Download IASI data
  %
  % I don't know how to download IASI data, so the data must be 
  % magically there already.

  asldata=[root '/data/iasi'];



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Input/Output files

  % Find existing input files (according to provided date ranges)
  file_list = iasi_l1c_filenames(sdate,edate,asldata);

  % Make output file name
  output_file = make_rtprod_filename('IASI', 'l1c', 'merra', 'udz','calc', '', sdate, version,'rtp',[pwd '/dump/']);

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
  % Read IASI Data:

  for ifile=1:numel(file_list)

    [head hattr profi pattr] = rtpmake_iasi_l1c_datafiles(file_list(ifile)); 
    prof(ifile) = profi;

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
  % Make a wrapper
  instrument='IASI'; %'IASI','CRIS'
  [head hattr prof pattr summary] = compute_clear_wrapper(head, hattr, prof, pattr, instrument);
  %  continuing comment:
  %  udef(4) = dBTun, udef(5) = mmH2O. Maybe I should keep these.



  %% Do subset, if wanted!
  %% [head prof] = subset_rtp(head, prof, [],[],iclear);


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

