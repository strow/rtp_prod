cris_paths

model = 'era';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/cris_sdr60_full49ch_*.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
