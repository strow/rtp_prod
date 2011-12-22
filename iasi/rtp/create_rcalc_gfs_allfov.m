iasi_paths

model = 'gfs';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/iasi_l1c_allfov.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
