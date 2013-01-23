iasi_paths

model = 'ecm';
emis = 'wis';

% JOB comes from a list of rtp_1 files

input_glob = JOB;

% This is a QUICK FIX to  be able to run this SHIT!!!

% /asl/data/rtprod_airs/yyyy/mm/dd/iasi_l1c_full.yyyy.mm.dd.ggg.rtp

thisdate = datenum(str2num(JOB([48:51])), str2num(JOB([53:54])), str2num(JOB([56:57])) ,str2num(JOB([59:61]))/144*24,0,0);
JOB=thisdate

say(['File: ' input_glob ]);
say(['This date: ' datestr(thisdate)]);


sarta_core
