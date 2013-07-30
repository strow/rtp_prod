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

function test_clear_1(s_vtime, e_vtime, d_vtime, pe, npe)
% function test_clear_1(s_vtime, e_vtime, d_vtime, pe, npe)
%
% s_vtime = starting time [yyyy mm dd HH MM SS]
% e_vtime = ending time   [yyyy mm dd HH MM SS]
% d_vtime = time duration on each file [yyyy mm dd HH MM SS]
% pe = this processor
% npe = number of processors
%
% Eg. 
% s_vtime = [2012,09,20,0,0,0];
% e_vtime = [2012,09,20,0,59,59.999];
% d_vtime = [0,0,0,0,10,0];  % 10 minutes;
% pe = 1;
% npe = 2; % two processors
%
% Calling from clustcmd for hourly files
%         clustcmd -n 24 -l log -q long_contrib -N CrisProc 'test_claer_1(datevec(JOB(1)), datevec(JOB(2)), datevec(JOB(2)-JOB(1)), '
%
% 
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 0 - Paralell loop setup
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert vector times into datenum

stime = datenum(s_vtime);
etime = datenum(e_vtime);
dtime = datenum(d_vtime);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Divide total time span into blocks to be dealt to the PEs
% Total number of blocks
nblocks = nearest((etime - stime)./dtime);
blocks_per_PE = ceil(nblocks./npe);
block_list = [1:bppe:nblocks];

% add the terminating point 
block_list(npe+1) = nblocks+1; %

% Compute blocks to be worked by this PE
thisPE_blocks = [block_list(pe):block_list(pe+1)-1];


% Loop over the requested blocks
for iblock = thisPE_blocks

  % Compute start and end time for this block
  
  
  sdate = stime + (iblock-1).*dtime;
  edate = stime + (iblock).*dtime;




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % 1 - Setup
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Call paths
  paths

  % Get code version number
  version = version_number();


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set data root
  root = '/home/imbiriba/git/rtp_prod/testsuit/asl'


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set rtp_prod installation  and set environment variable
  rtprod = '/home/imbiriba/git/rtp_prod';
  setenv('RTPROD',rtprod);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Download CRIS data
  %
  % I Don't know how to do that. CrIS data seems to appear magically at a 
  % default place.
  %
  % Hence, copy data manually

  % Set where data will be (relative to root) 
  asldata=[root '/data'];


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Look for input files in the time span 

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


end

end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
