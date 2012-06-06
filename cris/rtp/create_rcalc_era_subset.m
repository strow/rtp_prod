cris_paths

model = 'era';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/cris_sdr*sub*.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
