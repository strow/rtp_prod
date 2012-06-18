airs_paths

model = 'era';
emis = 'wis';
%input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1b.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_ctr.*.rtp'];

sarta_core
