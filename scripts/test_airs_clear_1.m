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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 1 - Setup
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call paths
paths


% Set data root
root = '/home/imbiriba/git/rtp_prod/testsuit/asl'


% Set rtp_prod installation  and set environment variable
rtprod = '/home/imbiriba/git/rtp_prod';
setenv('RTPROD',rtprod);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Download AIRS data

% Set where to download (usually relative to root) and call getairs
asldata=[root '/data/airs'];
system(['$RTPROD/bin/getairs 20120920 1 AIRIBRAD.005 1:10 ' asldata ]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Look for input files for one hour

sdate = datenum(2012,09,20,0,0,0);
edate = datenum(2012,09,20,1,0,0);

file_list = airs_l1b_filenames(sdate,edate,asldata);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 2 - Make RTP Structure
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read AIRS Data:
for ifile=1:numel(file_list)
  [head hattr profi pattr] = rtpmake_airs_l1b_datafiles(file_list(ifile)); 
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
instrument='AIRS'; %'IASI','CRIS'
[head hattr prof pattr summary] = compute_clear_wrapper(head, hattr, prof, pattr, instrument);
%  continuing comment:
%  udef(4) = dBTun, udef(5) = mmH2O. Maybe I should keep these.



[head prof] = subset_rtp(head, prof, [],[],iclear);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 4 - Save Data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save file

rtpwrite(output_file, head, hattr, prof, pattr);




