iasi_paths

model = 'ecm';
emis = 'dan';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/iasi_l1c.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
