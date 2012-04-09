airs_paths

model = 'ecm';
emis = 'wis';
%input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1b.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/AIRS_L1B_2*.rtp'];

sarta_core
