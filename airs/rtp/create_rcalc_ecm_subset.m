airs_paths

% fix if it's string
if(isstr(JOB))
  JOB = datenum(JOB,'yyyymmdd');
end

model = 'ecm';
emis = 'wis';
input_glob = [prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/airs_l1bcm.' datestr(JOB(1),'yyyy.mm.dd') '*.rtp'];

sarta_core
