cris_paths

model = 'ecm';
emis = 'dan';

% JOB comes from a list of rtp_1 files

input_glob = JOB;

% This is a QUICK FIX to  be able to run this SHIT!!!

[path fname ext] = fileparts(input_glob);

<<<<<<< HEAD
% 0        1         2         3         4         5         6
% 123456789012345678901234567890123456789012345678901234567890
% cris_cspp_dev.2012.09.20.143.Rv1.1d-Mv1.1c-1-g90d9ac4.rtp

thisdate = datenum(str2num(fname([15:18])), str2num(fname([20 21])), ...
                   str2num(fname([23 24])), str2num(fname([26:28]))/144*24,0,0);

yyyymmdd = datestr(thisdate,'yyyymmdd');
=======
%          1         2         3         4         5         6         7         8         9     
% 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
% /asl/data/rtprod_cris/2013/04/01/cris_sdr60_noaa_ops.2013.04.01.135.Rv1.1b-Mv1.1b.rtp
thisdate = datenum(str2num(JOB([54:57])), str2num(JOB([59:60])), str2num(JOB([62:63])) ,str2num(JOB([65:67]))/144*24,0,0);

JOB=thisdate
>>>>>>> 3bb8a0afda90860d184f79719d4526fbccaac4c6

say(['File: ' input_glob ]);
say(['This date: ' datestr(thisdate)]);

yyyymmdd = datestr(thisdate,'yyyymmdd');

sarta_core(input_glob, yyyymmdd, model, emis);

<<<<<<< HEAD
sarta_core(input_glob, yyyymmdd, model, emis);

=======
>>>>>>> 3bb8a0afda90860d184f79719d4526fbccaac4c6
