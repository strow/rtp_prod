cris_paths

sdate = JOB(1);
edate = JOB(2);

model = 'ecm';
emis = 'dan'; %emis = 'wis';

version = 'Rv1.1b-Mv1.1b';
version = 'R1.9k-*-M1.9i-*';

rtpset='subset';
src='noaa_ops';

input_glob = [prod_dir '/' datestr(sdate,'yyyy/mm/dd') '/cris_sdr60_' rtpset '_' src '.' datestr(sdate,'yyyy.mm.dd') '.*.' version '.rtp'];

sarta_core(input_glob, sdate, model, emis);
