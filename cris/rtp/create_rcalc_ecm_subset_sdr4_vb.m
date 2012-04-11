cris_paths

model = 'ecm';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/cris_v33b*.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
