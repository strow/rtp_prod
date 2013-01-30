iasi_paths

model = 'era';
emis = 'wis';
sarta= 'cld';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/iasi_l1c_full2345ctr.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
