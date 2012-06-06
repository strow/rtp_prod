iasi_paths

model = 'era';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/iasi_l1c.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp_1'];

sarta_core
