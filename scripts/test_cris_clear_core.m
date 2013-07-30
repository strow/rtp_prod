%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RTP CORE SAMPLE SCRIPT
%
% 
% CRIS CLEAR TEST 1
%
% Create one hour of clear data using 
% production routines.
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   Acumulate CrIS data from sdate to edate, add model
%   and compute calculations

%   Parameters:
%   sdate - matlab start date
%   edate - matlab end date
%   root  - location of the "asl" tree (/asl/)
%   rtprod - location of rtp_prod code

function test_cris_clear_core(sdate, edate)

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
  paths

  % Export environment variable
  setenv('RTPROD',rtprod);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get code version number
  version = version_number();


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set data root - for input and output
  root = '/home/imbiriba/git/rtp_prod/testsuit/asl'



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



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Input/Output files


  % Find existing input files (according to provided date ranges)
  file_list = cris_noaa_ops_filenames(sdate,edate,asldata,'sdr60');


  % Make output file name
  output_file = make_rtprod_filename('CRIS', 'sdr60_noaa_ops', 'merra', 'udz','calc', '', sdate, 1, 24, version,'rtp',root);




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 2 - Make RTP Structure
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read CrIS Data:
  for ifile=1:numel(file_list)
    [head hattr profi pattr] = sdr2rtp_h5(file_list{ifile}); 
    prof(ifile) = profi;

  end
  clear profi;
  prof = structmerge(prof);

  % add version number on header attributes
  hattr = set_attr(hattr,'version',version);




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
  instrument='CRIS'; %'IASI','CRIS'
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

    KlayersRun(head,hattr,prof,pattr,tempfile,11);

    [ ht htt pt ptt ] = SartaRun(tempfile, 11);
    
    prof.rcalc = pt.rcalc;
    clear ht htt pt ptt 


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 5 - Save Data
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save file


  rtpwrite(output_file, head, hattr, prof, pattr);


% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
