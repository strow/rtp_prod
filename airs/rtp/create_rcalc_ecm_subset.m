airs_paths

model = 'ecm';
emis = 'dan';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/l1bcm.ecmwf.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
