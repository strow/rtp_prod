function [cmdata pattr nominal_freq] = readl1bcm_v5_rtp(fn);

%function [cmdata, pattr, freq] = readl1bcm_v5_rtp(fn);
%
% Reads a daily AIRS-suite L1B clear matchup HDF file and return a matlab
% structure of all the data.  Updated for version5 files (will not
% work with v4 files).
%
% Input:
%    fn = (string) Name of a daily clear matchup file, something like
%         AIRS.2007.07.21.L1B.Cal_Subset.v5.0.16.0.G07205235835.hdf
%
% Output:
%    cmdata = (rtp structure) matlab data structure with the HDF file variables
%    pattr  = profile attributes describing the data
%    freq   = [2378 x 1] nominal channel frequencies
%

% Created: 29 March 2005, Scott Hannon
% Update: 25 July 2007, S.Hannon - update for v5 files
% Update: 01 Jun 2010, S.Hannon - add CalChanSummary, NeN, spectral_freq
% Update: 08 Jun 2010, Paul Schou - merged the calflag and modified fields
%    to rtp spec
% Update: 09 Jun 2010, S.Hannon - add clrflag; modify some pattr strings
% Update: 14 March 2011, Paul Schou - switched calflag to calnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% AIRS-suite channel dimensions
nAIRSchan = 2378;
nAMSUchan = 15; % note: HSB is dead so this is AMSU-A only
nVISchan  = 3;

% Fixed site range (in km)
range_km = 55.5;



% Check fn
if ~exist(fn,'file')
   disp(['Error, bad fn: ' fn])
   return
end


% Open file
file_name = fn;
file_id   = hdfsw('open',file_name,'read');
%%% v4
% swath_id  = hdfsw('attach',file_id,'L1B_AIRS_ClearMatch');
%%%


%%% Granule statistics: NeN and CalChanSummary
swath_id  = hdfsw('attach',file_id,'L1B_AIRS_Cal_Subset_Gran_Stats');
%
fstr = 'NeN';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval([fstr ' = junk;']);
%
fstr = 'CalChanSummary';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval([fstr ' = junk;']);
%
s = hdfsw('detach',swath_id);
%%%


swath_id  = hdfsw('attach',file_id,'L1B_AIRS_Cal_Subset');
%%%
fstr = 'nominal_freq';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval([fstr ' = junk;']);
%%%
%% Read Clear Filter Version attribute
%fstr = 'CF_Version';
%[junk,s] = hdfsw('readattr',swath_id,fstr);
%if s == -1; disp(['Error reading ' fstr]);end;
%eval(['cmdata.' fstr ' = junk;']);


%
% Note: No AMSU & VIS channel freq info in file

%
fstr = 'Time';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.rtime = junk'';']);
nobs = length(cmdata.rtime);


% Read satellite height above sea level
fstr = 'satheight';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.zobs = junk'';']);

% Read in the AIRS Latitude, Longitude, and Time
fstr = 'Latitude';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.rlat = junk'';']);
%
fstr = 'Longitude';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.rlon = junk'';']);


% Declare the udef arrays
cmdata.iudef = zeros(10,nobs);
cmdata.udef = zeros(20,nobs);


% Read Granule, scan(atrack), and footprint(xtrack) indices
%
fstr = 'granule_number';  % findex
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.findex = junk'';']);
%
fstr = 'scan';  % atrack
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.atrack = junk'';']);
%
fstr = 'footprint';  % xtrack
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.xtrack = junk'';']);
%
fstr = 'scan_node_type';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.iudef(4,:) = junk'';']);

mtime = tai2mattime(nanmean(cmdata.rtime));

calflag = zeros(2378,nobs,'uint8');
gdata.dustflag=nan(1,nobs);
gdata.topog=nan(1,nobs);
gdata.scanang=nan(1,nobs);
gdata.glint=nan(1,nobs);

if any(cmdata.findex == 0) & exist(['/asl/data/airs/META_DATA/' datestr(mtime-1,'yyyy') '/AIRS_' datestr(mtime-1,'yyyymmdd') '.mat'],'file');
  % load previous day for gran 0
  %d = load(['/asl/data/airs/META_DATA/' datestr(mtime-1,'yyyy') '/AIRS_' datestr(mtime-1,'yyyymmdd') '.mat'],'CalFlag','dust_flag','topog','scanang','sun_glint_distance');
  disp(['reading /asl/data/rtprod_airs/raw_meta_data/' datestr(mtime-1,'yyyy') '/' num2str(jday(mtime-1),'%03d') '/meta_cdtssll.240']);
  [sa sgd top cf df lat lon time] = getdata_opendap_file(['/asl/data/rtprod_airs/raw_meta_data/' datestr(mtime-1,'yyyy') '/' num2str(jday(mtime-1),'%03d') '/meta_cdtssll.240']);

  for i = find(cmdata.findex == 0)
    calflag(:,i) = cf(:,cmdata.atrack(i));
    cmdata.dustflag(1,i)=df(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.topog(1,i)=top(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.scanang(1,i)=sa(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.glint(1,i)=sgd(cmdata.xtrack(i),cmdata.atrack(i));
  end
end

% load current day for every other findex
%d = load(['/asl/data/airs/META_DATA/' datestr(mtime,'yyyy') '/AIRS_' datestr(mtime,'yyyymmdd') '.mat'],'CalFlag','dust_flag','topog','scanang','sun_glint_distance');
for gran = unique(sort(cmdata.findex(cmdata.findex > 0)))
  disp(['reading /asl/data/rtprod_airs/raw_meta_data/' datestr(mtime,'yyyy') '/' num2str(jday(mtime),'%03d') '/meta_cdtssll.' num2str(gran,'%03d')]);
  [sa sgd top cf df lat lon time] = getdata_opendap_file(['/asl/data/rtprod_airs/raw_meta_data/' datestr(mtime,'yyyy') '/' num2str(jday(mtime),'%03d') '/meta_cdtssll.' num2str(gran,'%03d')]);
  for i = find(cmdata.findex == gran)
    calflag(:,i) = cf(:,cmdata.atrack(i));
    cmdata.dustflag(1,i)=df(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.topog(1,i)=top(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.scanang(1,i)=sa(cmdata.xtrack(i),cmdata.atrack(i));
    cmdata.glint(1,i)=sgd(cmdata.xtrack(i),cmdata.atrack(i));
  end
end


%plot(CalChanSummary(661,:))

[cmdata.calflag, cstr] = data_to_calnum_l1bcm(nominal_freq, NeN, ...
   CalChanSummary, calflag, cmdata.rtime, cmdata.findex);


% Read reason & site info
%
% reason code numbers (bit flags):
%    1=clear
%    2=calibration site
%    4=high clouds
%    8=randomly selected
% note: sites may be selected for more than one reason
fstr = 'reason';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.iudef(1,:) = junk;']);
%
% site code numbers:
%    1=Egypt           27.12 N,   26.10 E
%    2=Simpson desert  24.50 N,  137.00 E
%    3=Dome Concordia -75.10 N,  123.40 E
%    4=Mitu Columbia    1.50 N,  -69.50 E
%    5=Boumba Cameroon  3.50 N,   14.50 E
fstr = 'site';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.iudef(2,:) = junk;']);

% add the additional gv sites
[sind, snum] = fixedsite(cmdata.rlat, cmdata.rlon, range_km);
cmdata.iudef(2,sind(snum>100)) = snum(snum>100);


% Read satellite and solar zenith angles
%
fstr = 'satzen';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.' fstr ' = junk'';']);
%
fstr = 'solzen';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.' fstr ' = junk'';']);
%
fstr = 'sun_glint_distance';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.glint = junk'';']);


% Read surface info
%
fstr = 'LandFrac';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.landfrac = junk'';']);
%
fstr = 'topog';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.salti = junk'';']);


% Read MW surface info
%
%fstr = 'amsu_landFrac';
%[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
%if s == -1; disp(['Error reading ' fstr]);end;
%eval(['cmdata.' fstr ' = junk;']);
%
%fstr = 'amsu_topog';
%[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
%if s == -1; disp(['Error reading ' fstr]);end;
%eval(['cmdata.' fstr ' = junk;']);


% Read the spatial coherence variables
%
fstr = 'cx1231';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(12,:) = junk;']);
%
fstr = 'cx2395';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(9,:) = junk;']);
%
fstr = 'cx2616';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(13,:) = junk;']);
%
% total water
fstr = 'cxq2';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(14,:) = junk;']);
%
% lapse rate
fstr = 'cxlpn';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(8,:) = junk;']);

% New fields for v5
%
% climatological lapse rate derived from 2395 cm^-1 channel?
fstr = 'lp2395clim';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(7,:) = junk;']);
%
% SO2 delta BT
fstr = 'BT_diff_SO2';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(6,:) = junk;']);
%
% Dust flag
fstr = 'dust_flag';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.iudef(3,:) = junk;']);

% Read the surface BT variables
%
fstr = 'bt1231';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(4,:) = junk;']);
%
fstr = 'sst1231r5';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(11,:) = junk;']);
%
fstr = 'avnsst';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(10,:) = junk;']);


% Read the radiances
%
fstr = 'VisMean';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(18,:) = junk(1,:);']);
eval(['cmdata.udef(19,:) = junk(2,:);']);
eval(['cmdata.udef(20,:) = junk(3,:);']);
%
fstr = 'VisStdDev';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.udef(15,:) = junk(1,:);']);
eval(['cmdata.udef(16,:) = junk(2,:);']);
eval(['cmdata.udef(17,:) = junk(3,:);']);
%
%fstr = 'amsu_bt';
%[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
%if s == -1; disp(['Error reading ' fstr]);end;
%eval(['cmdata.' fstr ' = junk;']);
%
fstr = 'radiances';
[junk,s] = hdfsw('readfield',swath_id,fstr,[],[],[]);
if s == -1; disp(['Error reading ' fstr]);end;
eval(['cmdata.robs1 = junk;']);


% Set clrflag
cmdata.clrflag = zeros(1,nobs);         % default not-clear
ii = find(mod(cmdata.iudef(1,:),2)==1); % odd "reason" is clear
cmdata.clrflag(ii) = 1;


% Close HDF file
%
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L1B clear matchup');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L1B clear matchup');end;

% Assign pattr
pattr={ {'profiles' 'robs1' fn}, ...
        {'profiles' 'rtime' 'Seconds since 0z, 1 Jan 1993'}, ...
        {'profiles' 'calflag' cstr}, ...
        {'profiles' 'landfrac' 'AIRS Landfrac'}, ...
        {'profiles' 'iudef(1,:)' 'Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}'}, ...
        {'profiles' 'iudef(2,:)' 'Fixed site number {sitenum}'}, ...
        {'profiles' 'iudef(3,:)' 'Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}'}, ...
        {'profiles' 'iudef(4,:)' 'Node char [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}'}, ...
        {'profiles' 'udef(4,:)' 'Brightness Temperature of 1231 wn {bt1231}'}, ...
        {'profiles' 'udef(5,:)' 'Total column water vapor {mm_H2O}'}, ...
        {'profiles' 'udef(6,:)' 'SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}'}, ...
        {'profiles' 'udef(7,:)' 'Climatological pseudo lapse rate threshold {lp2395clim}'}, ...
        {'profiles' 'udef(8,:)' 'Spacial coherence of pseudo lapse rate {cxlpn}'}, ...
        {'profiles' 'udef(9,:)' 'Spacial coherence of 2395 wn {cx2395}'}, ...
        {'profiles' 'udef(10,:)' 'Aviation forecast sea surface temp {AVNSST}'}, ...
        {'profiles' 'udef(11,:)' 'Surface temp estimate {sst1231r5}'}, ...
        {'profiles' 'udef(12,:)' 'Spacial coherence of 1231 wn {cx1231}'}, ...
        {'profiles' 'udef(13,:)' 'Spacial coherence of 2616 wn {cx2616}'}, ...
        {'profiles' 'udef(14,:)' 'Spacial coherence of water vapor {cxq2}'}, ...
        {'profiles' 'udef(15,:)' 'Visible channel 1 STD {VIS_1_stddev}'}, ...
        {'profiles' 'udef(16,:)' 'Visible channel 2 STD {VIS_2_stddev}'}, ...
        {'profiles' 'udef(17,:)' 'Visible channel 3 STD {VIS_3_stddev}'}, ...
        {'profiles' 'udef(18,:)' 'Visible channel 1 {VIS_1_mean}'}, ...
        {'profiles' 'udef(19,:)' 'Visible channel 2 {VIS_2_mean}'}, ...
        {'profiles' 'udef(20,:)' 'Visible channel 3 {VIS_3_mean}'} };


%%% end of function %%%
