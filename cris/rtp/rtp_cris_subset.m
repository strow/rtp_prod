function [head hattr prof pattr summary] = rtp_cris_subset(head_in,hattr_in,prof_in,pattr_in,subset)

% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program xuniform_clear_template
%
% Run the CrIS xuniform.m and xfind_clear.m codes for a Proxy data
% file and save some results. The input RTP should contain unapodized
% (ie boxcar) radiance along with profile and emissivity.
% The following variables must be set above:
%    RTPIN   : [string] name of input RTP file to read
%    RTPOUT  : [string] name of output RTP file to create
%    SUMOUT  : [string] name of output matlab summary file to create
%

% Created: 05 May 2011, Scott Hannon - based on xuniform_clear_example.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed

% Uniformity test channel ID numbers
idtestu = [272; 499; 732];
% The corresponding approximate channel freqs [wn] are:
%          [820 960 1231]

% Clear test channel IDs must include all those internally hardcoded
% in "find_clear.m".
idtestc=[  272;   332;    421;   499;   631;    675;     694;   710;     732];
% The corresponding approximate channel freqs [wn] are:
%      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

% Name of KLAYERS and SARTA executables for clear detection calcs
KLAYERS='/asl/packages/klayersV205/BinV201/klayers_airs';
SARTA='/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_wcon_nte';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%addpath /asl/matlab/aslutil        % mktemp
%addpath /asl/matlab/h4toolsV201    % rtpread, rtpwrite
%addpath /asl/matlab/rtptoolsV201   % subset_rtp
%addpath /asl/matlab/cris/uniform   % xuniform, site_dcc_random
%addpath /asl/matlab/cris/clear     % xfind_clear, proxy_box_to_ham
%addpath /asl/matlab/cris/unapod    % xfind_clear, proxy_box_to_ham


% Load the CrIS proxy data file
%disp(['loading data: ' RTPIN])
%[head, hattr, prof, pattr] = rtpread(RTPIN);
% Use the data stored in memory
disp(['loading data: '])
head = head_in; hattr = hattr_in; prof = prof_in; pattr = pattr_in;


% Convert boxcar (ie unapodized) to Hamming apodization
disp('running proxy_box_to_ham')

%replaces proxy_box_to_ham
prof.robs1 = boxg4_to_ham(head.ichan, prof.robs1);

% Note: the RTP structures are now temporary variables with boxcar
% apodized radiances. Before outputing the subsetted RTP it will be
% necessary to re-read the input file.


% Run xuniform
disp('running xuniform')
[dbtun, mbt] = xuniform(head, prof, idtestu);
nobs = length(dbtun);
ibad1 = find(mbt < 150);


% Run site_dcc_random
% Note: can use the same channels used in the uniform test
disp('running site_dcc_random')
[iflagso, isite] = site_dcc_random(head, prof, idtestu);
ibad2 = find(iflagso >= 32);
ibad = setdiff(ibad1,ibad2);
iflagso(ibad) = iflagso(ibad) + 32;
% Keep 2=site, 4=DCC, 8=random even if coastal=16 but not coastal only
iother = setdiff(find(iflagso >= 2 & iflagso <= 30),find(iflagso == 16));
disp(['nother=' int2str(length(iother))])


% Get names of tmp rtp files
disp('generating tmp RTP filenames')
tmp_rtp1 = mktemp('/tmp/rtp1_');
tmp_rtp2 = mktemp('/tmp/rtp2_');
tmp_jout = mktemp('/tmp/jout_');

% Subset RTP for the clear test channels (to speed up calcs)
disp('subsetting RTP to clear test channels')
[head, prof] = subset_rtp(head, prof, [], idtestc, []);

% Write RTP to tmp_rtp1
disp('writing pre-klayers tmp RTP file')
rtpwrite(tmp_rtp1,head,hattr,prof,pattr);

% Run klayers and SARTA
disp('running klayers')
eval(['! ' KLAYERS ' fin=' tmp_rtp1 ' fout=' tmp_rtp2 ' > ' tmp_jout]);
disp('running sarta')
eval(['! ' SARTA ' fin=' tmp_rtp2 ' fout=' tmp_rtp1 ' > ' tmp_jout]);
disp('loading sarta output RTP')
[head, hattr, prof, pattr] = rtpread(tmp_rtp1);

% Remove tmp RTP files
eval(['! rm -f ' tmp_rtp1 ' ' tmp_rtp2 ' ' tmp_jout]);

% Run xfind_clear
disp('running xfind_clear')
[iflagsc, bto1232, btc1232] = xfind_clear(head, prof, 1:nobs);
iclear_sea    = find(iflagsc == 0 & abs(dbtun) < 0.5 & prof.landfrac <= 0.01);
iclear_notsea = find(iflagsc == 0 & abs(dbtun) < 1.0 & prof.landfrac >  0.01);
iclear = union(iclear_sea, iclear_notsea);

% Re-load the CrIS proxy data file
disp('re-loading original RTP data')
%[head, hattr, prof, pattr] = rtpread(RTPIN);
% Use the data stored in memory
head = head_in; hattr = hattr_in; prof = prof_in; pattr = pattr_in;


% Determine all indices to keep
iclrflag = zeros(1,nobs);
iclrflag(iclear) = 1;
ireason = iclrflag + iflagso;
% Reject any coastal clear FOVs that are not site or random
ireject = find(ireason == 17);
if (length(ireject) > 0)
   iclear = setdiff(iclear,ireject);
end
ikeep = union(iclear, iother);
nkeep = length(ikeep);
disp(['nclear=' int2str(length(iclear))])
disp(['nkeep=' int2str(nkeep)])


% Create summary file
disp('creating summary file')
% RTP fields
summary.rlat    = single(prof.rlat);
summary.rlon    = single(prof.rlon);
summary.rtime   = prof.rtime;
summary.solzen  = single(prof.solzen);
summary.landfrac= single(prof.landfrac);
summary.findex  = uint8(prof.findex);
summary.atrack  = uint8(prof.atrack);
summary.xtrack  = uint8(prof.xtrack);
summary.ifov    = uint8(prof.ifov);
% Spatial uniformity test fields
summary.uniform_idtest = uint16(idtestu);
summary.uniform_dbt    = single(dbtun);
summary.uniform_mbt    = single(mbt);
% Clear test fields
summary.bto1232       = single(bto1232);
summary.btc1232       = single(btc1232);
summary.cleartest     = uint8(iflagsc);
summary.cleartest_str = '0=clear, 1=big dbt1232, 2=cirrus, 4=dust/ash';
% Selection reason fields
summary.reason     = uint8(ireason);
summary.reason_str = '1=clear, 2=site, 4=DCC, 8=random, 16=coast, 32=bad';
summary.site_number = uint16(isite);
%summary.parent_file = RTPIN;
%eval(['save  ' SUMOUT ' summary'])


% Subset RTP and save output
if (nkeep > 0)
   % Subset to RTP for {clear, site, DCC, random}
   if(subset ~= 1)
     ikeep = 1:nobs;
   end
   [head, prof] = subset_rtp(head,prof,[],[],ikeep);
   isite = isite(ikeep);
   iclrflag = iclrflag(ikeep);
   ireason = ireason(ikeep);

   % Cut ireason to 4 bits
   icut = find(ireason > 32);
   ireason(icut) = ireason(icut) - 32;
   icut = find(ireason > 16);
   ireason(icut) = ireason(icut) - 16;

   prof.clrflag = iclrflag;  
   if (~isfield(prof,'udef'))
      prof.udef = zeros(20,nkeep);
   end
   prof.udef(13,:) = dbtun(ikeep);
   prof.udef(14,:) = bto1232(ikeep);
   prof.udef(15,:) = btc1232(ikeep);
   if (~isfield(prof,'iudef'))
      prof.iudef = zeros(10,nkeep);
   end
   prof.iudef(1,:) = ireason;
   prof.iudef(2,:) = isite;

   pattr = set_attr(pattr, 'udef(13,:)', 'spatial uniformity test dBT {dbtun}');
   pattr = set_attr(pattr, 'udef(14,:)', 'BTobs 1232 wn {bto1232}');
   pattr = set_attr(pattr, 'udef(15,:)', 'BTcal 1232 wn {btc1232}');
   pattr = set_attr(pattr, 'iudef(1,:)', ...
      'selection reason: 1=clear, 2=site, 4=DCC, 8=random {reason}');
   pattr = set_attr(pattr, 'iudef(2,:)', 'fixed site number {sitenum}');

   % Write output RTP
   %rtpwrite(RTPOUT,head,hattr,prof,pattr);

else
   disp('no FOVs selected, so no output RTP')
   prof = [];
end


%%% end of program %%%