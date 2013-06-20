cris_paths

model = 'ecm';
emis = 'dan';

% JOB comes from a list of rtp_1 files

input_glob = JOB;

% This is a QUICK FIX to  be able to run this SHIT!!!

[path fname ext] = fileparts(input_glob);

% 0        1         2         3         4         5         6
% 123456789012345678901234567890123456789012345678901234567890
% cris_cspp_dev.2012.09.20.143.Rv1.1d-Mv1.1c-1-g90d9ac4.rtp

thisdate = datenum(str2num(fname([15:18])), str2num(fname([20 21])), ...
                   str2num(fname([23 24])), str2num(fname([26:28]))/144*24,0,0);

yyyymmdd = datestr(thisdate,'yyyymmdd');

say(['File: ' input_glob ]);
say(['This date: ' datestr(thisdate)]);


sarta_core(input_glob, yyyymmdd, model, emis);

