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

function test_cris_clear_driver(s_vtime, e_vtime, d_vtime, pe, npe)
% function test_cris_clear_driver(s_vtime, e_vtime, d_vtime, pe, npe)
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
  % 1 - Call Processing script
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  test_cris_clear_core(sdate, edate)
   

end
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
