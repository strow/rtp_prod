cris_paths

model = 'ecm';
emis = 'wis';

% JOB comes from a list of rtp_1 files

input_glob = JOB;

% This is a QUICK FIX to  be able to run this SHIT!!!

% /asl/data/rtprod_cris/yyyy/mm/dd/cris_sdr60_noaa_ops.2012.08.10.123.v1.rtp

thisdate = datenum(str2num(JOB([54:57])), str2num(JOB([59:60])), str2num(JOB([62:63])) ,str2num(JOB([65:67]))/144*24,0,0);
JOB=thisdate

say(['File: ' input_glob ]);
say(['This date: ' datestr(thisdate)]);


sarta_core
