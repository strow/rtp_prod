airs_paths

model = 'ecm';
emis = 'wis';
%input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1b.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/cc.20*.rtp'];
sarta_exec='/asl/packages/sartaV108/BinV201/sarta_apr08_m140'

sarta_core
