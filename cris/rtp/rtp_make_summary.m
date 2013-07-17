function summary = rtp_make_summary(head,hattr,prof,pattr, idtestu,dbtun,mbt,bto1232,btc1232,iflagsc,ireason,isite)
% function summary = rtp_make_summary(head,hattr,prof,pattr, idtestu,dbtun,mbt,bto1232,btc1232,iflagsc,ireason,isite)
%
% Make the summary data structure - a light data structure to help locate and sellect data before having to access the 
% large radicance/profiles arrays.
%
% The 'summary' structure contains:
%
% -- Geo Info -- Directly from RTP files
%
%  rlat    	- fov latitude
%  rlon    	- fov longitude
%  rtime   	- fov rtime (TAIxxxx)
%  solzen  	- solar zenith angle
%  landfrac	- land fraction (0-ocean 1-land)
%  findex  	- granule ID
%  atrack  	- scan line index
%  xtrack  	- cross track index
%  ifov    	- FoV index on focal plane (For CrIS: 1 to 9)
%  satzen  	- satellite zenith angle (from Zenith down)
%  satazi  	- satellite azimuth angle (from North through East?)
%
% -- Spatial uniformity test fields
%
%  uniform_idtest - Test channels for uniformity test 
%  uniform_dbt    - max delta BT {K}			(see xuniform3.m)
%  uniform_mbt    - mean BTobs {K} used in dbtun tests 	(see xuniform3.m)
%
% 
% -- Clear test fields
%  
%  bto1232       - BT Obs 1232 wn
%  btc1232       = BT Cal 1232 wn
%  cleartest     = uint8(iflagsc);
%  cleartest_str = '0=clear, 1=big dbt1232, 2=cirrus, 4=dust/ash';
%
% -- Selection reason fields
%
%  reason     = uint8(ireason);
%  reason_str = '1=clear, 2=site, 4=DCC, 8=random, 16=coast, 32=bad';
%  site_number = uint16(isite);
%
%
% Paul Schou
% Breno Imbiriba - 2013.06.04


% Create summary file
% disp('creating summary file')
% RTP fields
  summary.rlat    = single(prof.rlat);
  summary.rlon    = single(prof.rlon);
  summary.rtime   = prof.rtime;
  summary.solzen  = single(prof.solzen);
  summary.landfrac= single(prof.landfrac);
  summary.findex  = uint32(prof.findex);
  summary.atrack  = uint8(prof.atrack);
  summary.xtrack  = uint8(prof.xtrack);
  summary.ifov    = uint8(prof.ifov);
  summary.satzen  = single(prof.satzen);
  summary.satazi  = single(prof.satazi);

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


end
