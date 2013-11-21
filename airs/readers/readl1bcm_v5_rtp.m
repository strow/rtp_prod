function [cmdata pattr nominal_freq] = readl1bcm_v5_rtp(fn);
% function [cmdata pattr nominal_freq] = readl1bcm_v5_rtp(fn);
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
%
%
% Breno Imbiriba - 2013.06.07

% Created: 29 March 2005, Scott Hannon
% Update: 25 July 2007, S.Hannon - update for v5 files
% Update: 01 Jun 2010, S.Hannon - add CalChanSummary, NeN, spectral_freq
% Update: 08 Jun 2010, Paul Schou - merged the calflag and modified fields
%    to rtp spec
% Update: 09 Jun 2010, S.Hannon - add clrflag; modify some pattr strings
% Update: 14 March 2011, Paul Schou - switched calflag to calnum
% Update: Ignore CalFlag. Cleaner.
%         As this is now, there's no CalFlag
%         Based on Scott's readl1bcm_v5_rtp
% Update: 2013.11.21 - I need CalFlag! 
%         Go back to older code and reinstate relevant lines.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup


  % Check filename
  if ~exist(fn,'file')
    disp(['Error, bad fn: ' fn])
    return
  end


  % AIRS-suite channel dimensions
  nAIRSchan = 2378;
  nAMSUchan = 15; % note: HSB is dead so this is AMSU-A only
  nVISchan  = 3;

  % Fixed site range (in km)
  range_km = 55.5;


  % Open file
  file_name = fn;
  file_id   = hdfsw('open',file_name,'read');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read Granule Statistics

  swath_id  = hdfsw('attach',file_id,'L1B_AIRS_Cal_Subset_Gran_Stats');

  NeN = read_hdfsw_l('NeN',swath_id);
  CalChanSummary =  read_hdfsw_l('CalChanSummary',swath_id);

  s = hdfsw('detach',swath_id);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read Granule Data


  swath_id  = hdfsw('attach',file_id,'L1B_AIRS_Cal_Subset');

  % Channel frequency list
  nominal_freq = read_hdfsw_l('nominal_freq',swath_id);
 
  % Basic GEO info
  cmdata.rtime = read_hdfsw_l('Time',swath_id);
  cmdata.rlat  = single(read_hdfsw_l('Latitude',swath_id));
  cmdata.rlon  = single(read_hdfsw_l('Longitude',swath_id));
  cmdata.zobs  = read_hdfsw_l('satheight',swath_id);
  cmdata.rtime = read_hdfsw_l('Time',swath_id);

  % Basic METRO info

  cmdata.findex = read_hdfsw_l('granule_number',swath_id);
  cmdata.atrack = read_hdfsw_l('scan',swath_id);
  cmdata.xtrack = read_hdfsw_l('footprint',swath_id);
 
  % Other variables
  cmdata.satzen = read_hdfsw_l('satzen',swath_id);
  cmdata.solzen = read_hdfsw_l('solzen',swath_id);
  cmdata.glint = read_hdfsw_l('sun_glint_distance',swath_id);
  cmdata.landfrac = read_hdfsw_l('LandFrac',swath_id);
  cmdata.salti = read_hdfsw_l('topog',swath_id);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % (i)udef variables
  % Declare (i)udef variables
  nobs = length(cmdata.rtime);
  cmdata.iudef = zeros(10,nobs,'uint16');
  cmdata.udef  = zeros(20,nobs);

  
  % Reason
  cmdata.iudef(1,:) = read_hdfsw_l('reason',swath_id);
  cmdata.iudef(2,:) = read_hdfsw_l('site',swath_id);
  % site code numbers:
  %    1=Egypt           27.12 N,   26.10 E
  %    2=Simpson desert  24.50 N,  137.00 E
  %    3=Dome Concordia -75.10 N,  123.40 E
  %    4=Mitu Columbia    1.50 N,  -69.50 E
  %    5=Boumba Cameroon  3.50 N,   14.50 E
  % Add aditional GV sites...
  [sind, snum] = fixedsite(cmdata.rlat, cmdata.rlon, range_km);
  cmdata.iudef(2,sind(snum>100)) = snum(snum>100);
  cmdata.iudef(3,:) = read_hdfsw_l('dust_flag',swath_id);
  cmdata.iudef(4,:) = read_hdfsw_l('scan_node_type',swath_id);

  % Clear/Uniformity Variables
  cmdata.udef(12,:) = read_hdfsw_l('cx1231',swath_id);
  cmdata.udef(9,:) = read_hdfsw_l('cx2395',swath_id);
  cmdata.udef(13,:) = read_hdfsw_l('cx2616',swath_id);

  cmdata.udef(14,:) = read_hdfsw_l('cxq2',swath_id);
  cmdata.udef(8,:) = read_hdfsw_l('cxlpn',swath_id);
  cmdata.udef(7,:) = read_hdfsw_l('lp2395clim',swath_id);
  cmdata.udef(6,:) = read_hdfsw_l('BT_diff_SO2',swath_id);

  cmdata.udef(4,:) = read_hdfsw_l('bt1231',swath_id);
  cmdata.udef(11,:) = read_hdfsw_l('sst1231r5',swath_id);
  cmdata.udef(10,:) = read_hdfsw_l('avnsst',swath_id);

  % Visible - vectors have to be transposed
  cmdata.udef([18 19 20],:) = read_hdfsw_l('VisMean',swath_id)';
  cmdata.udef([15 16 17],:) = read_hdfsw_l('VisStdDev',swath_id)';

  % Radiances - vectors have to be transposed
  cmdata.robs1 = read_hdfsw_l('radiances',swath_id)';


  % clear flag
  cmdata.clrflag =  zeros(1,nobs);         % default not-clear
  ii = find(mod(cmdata.iudef(1,:),2)==1); % odd "reason" is clear
  cmdata.clrflag(ii) = 1;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Read missing variables
  % CalFlag, dust_flag, topog, scanang, sun_glint_distance
  % These variables have already been download by the 
  % airs_l1bcm_download.m code
  %
  % *** Very important ***
  % For some reason L1bCM data has the last day's granule in it. 
  % We need granule 240 from the previous day to obtain the missing variables.


  mtime = tai2mattime(nanmean(cmdata.rtime));

  % Predeclare arrays with NaNs
  calflag = zeros(2378,nobs,'uint8');
  gdata.dustflag=nan(1,nobs);
  gdata.topog=nan(1,nobs);
  gdata.scanang=nan(1,nobs);
  gdata.glint=nan(1,nobs);

  disp(['reading /asl/data/rtprod_airs/raw_meta_data/' datestr(mtime,'yyyy') '/' num2str(jday(mtime),'%03d') '/meta_cdtssll.']);

  % Loop over granules of the data (findex)
  for gran = unique(sort(cmdata.findex)) 
    
    % nice display   
    fprintf('%03d ',gran); if(mod(gran,20)==0); fprintf('\n');end


    % If granule==0 load granule 240 from previous day
    if(gran == 0) 
      rmdfn = ['/asl/data/rtprod_airs/raw_meta_data/' datestr(mtime-1,'yyyy')...
       '/' num2str(jday(mtime-1),'%03d') '/meta_cdtssll.240'];
      if(~exist(rmdfn,'file'))
        error(['File ' rmdfn ' does not exist']);
      end

      [scanang satazi solazi sun_glint_distance topog ...
       CalFlag dust_flag Latitude Longutide Time] = getdata_opendap_file(rmdfn);

     else 
      % Otherwise, load all the granules of this day
      rmdfn = ['/asl/data/rtprod_airs/raw_meta_data/' datestr(mtime,'yyyy') ...
       '/' num2str(jday(mtime),'%03d') '/meta_cdtssll.' num2str(gran,'%03d')];
      if(~exist(rmdfn,'file'))
        error(['File ' rmdfn ' does not exist']);
      end
    
      [scanang satazi solazi sun_glint_distance topog ...
       CalFlag dust_flag Latitude Longutide Time] = getdata_opendap_file(rmdfn);

    end 

    % Match extra data in this granule to the l1bcm data (using xtrack/atrack)
    for i = find(cmdata.findex == gran)
      calflag(:,i)         = CalFlag(:,cmdata.atrack(i));
      cmdata.dustflag(1,i) = dust_flag(cmdata.xtrack(i),cmdata.atrack(i));
      cmdata.topog(1,i)    = topog(cmdata.xtrack(i),cmdata.atrack(i));
      cmdata.scanang(1,i)  = scanang(cmdata.xtrack(i),cmdata.atrack(i));
      cmdata.glint(1,i)    = sun_glint_distance(cmdata.xtrack(i),cmdata.atrack(i));
    end
  end

  % Compute calflag
  [cmdata.calflag, cstr] = data_to_calnum_l1bcm(nominal_freq', NeN', ...
     CalChanSummary', calflag, cmdata.rtime, cmdata.findex);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % Close HDF file
  %
  s = hdfsw('detach',swath_id);
  if s == -1; disp('Swatch detach error: L1B clear matchup');end;
  s = hdfsw('close',file_id);
  if s == -1; disp('File close error: L1B clear matchup');end;


  % Declare pattr:
  pattr = set_attr('profiles','robs1',fn);
  pattr = set_attr(pattr, 'rtime','Seconds since 0z, 1 Jan 1993');
  %%pattr = set_attr(pattr, 'calflag',cstr);
  pattr = set_attr(pattr, 'landfrac','AIRS Landfrac');
  pattr = set_attr(pattr, 'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
  pattr = set_attr(pattr, 'iudef(2,:)','Fixed site number {sitenum}');
  pattr = set_attr(pattr, 'iudef(3,:)','Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}');
  pattr = set_attr(pattr, 'iudef(4,:)','Node char [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}');
  pattr = set_attr(pattr, 'udef(4,:)','Brightness Temperature of 1231 wn {bt1231}');
  pattr = set_attr(pattr, 'udef(5,:)','Total column water vapor {mm_H2O}');
  pattr = set_attr(pattr, 'udef(6,:)','SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}');
  pattr = set_attr(pattr, 'udef(7,:)','Climatological pseudo lapse rate threshold {lp2395clim}');
  pattr = set_attr(pattr, 'udef(8,:)','Spacial coherence of pseudo lapse rate {cxlpn}');
  pattr = set_attr(pattr, 'udef(9,:)','Spacial coherence of 2395 wn {cx2395}');
  pattr = set_attr(pattr, 'udef(10,:)','Aviation forecast sea surface temp {AVNSST}');
  pattr = set_attr(pattr, 'udef(11,:)','Surface temp estimate {sst1231r5}');
  pattr = set_attr(pattr, 'udef(12,:)','Spacial coherence of 1231 wn {cx1231}');
  pattr = set_attr(pattr, 'udef(13,:)','Spacial coherence of 2616 wn {cx2616}');
  pattr = set_attr(pattr, 'udef(14,:)','Spacial coherence of water vapor {cxq2}');
  pattr = set_attr(pattr, 'udef(15,:)','Visible channel 1 STD {VIS_1_stddev}');
  pattr = set_attr(pattr, 'udef(16,:)','Visible channel 2 STD {VIS_2_stddev}');
  pattr = set_attr(pattr, 'udef(17,:)','Visible channel 3 STD {VIS_3_stddev}');
  pattr = set_attr(pattr, 'udef(18,:)','Visible channel 1 {VIS_1_mean}');
  pattr = set_attr(pattr, 'udef(19,:)','Visible channel 2 {VIS_2_mean}');
  pattr = set_attr(pattr, 'udef(20,:)','Visible channel 3 {VIS_3_mean}');




end

function field = read_hdfsw_l(fstr, swath_id)

  [junk, s] = hdfsw('readfield',swath_id, fstr, [],[],[]);
  if(s == -1)
    disp(['Error reading ' fstr]); 
  end
  field = junk';

end
