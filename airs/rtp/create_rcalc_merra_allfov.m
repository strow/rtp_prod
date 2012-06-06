airs_paths

model = 'merra';
emis = 'wis';
%input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1b.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/AIRS_*.rtp'];

sarta_core
