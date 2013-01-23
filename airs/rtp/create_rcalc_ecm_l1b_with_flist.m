airs_paths

model = 'ecm';
emis = 'wis';
input_glob = JOB;

% This is a QUICK FIX to  be able to run this SHIT!!!

% /asl/data/rtprod_airs/yyyy/mm/dd/airs_l1b.yyyy.mm.dd.ggg.rtp

thisdate = datenum(str2num(JOB([43:46])), str2num(JOB([48:49])), str2num(JOB([51:52])) ,str2num(JOB([54:56]))/10,0,0);
JOB=thisdate;

say(['File: ' input_glob ]);
say(['This date: ' datestr(thisdate)]);


sarta_core
