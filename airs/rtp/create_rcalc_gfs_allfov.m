airs_paths

model = 'gfs';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1b.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
