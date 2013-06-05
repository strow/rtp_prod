airs_paths

addpath /home/sergio/MATLABCODE/matlib/clouds/sarta
addpath /home/sergio/MATLABCODE/matlib/clouds/pcrtm


if isnumeric(JOB)
  list = findfiles(['/asl/data/rtprod_airs/' datestr(JOB(1),'yyyy/mm/dd') '/cld_era_41ch.airs_ctr*.rtp'])
else
  list = {JOB};
end

for file = list
  infile = file{1}
  outfile = [dirname(file{1}) '/cldpcr_' basename(file{1})]

  if exist(outfile,'file')
    continue;
  end
  % declare we are working on this day so we don't have two processes working on the same day
  if ~lockfile(outfile); 
    say(['Warning: lockfile for ' outfile ' already exists. Continuing...']);
    continue; 
  end

  run_sarta.clear = +1;
  run_sarta.cloud = +1;
  run_sarta.cumsum=+9999;

  [h,ha,p,pa] = rtpread(infile);
  [h,ha,p,pa] = rtpgrow(h,ha,p,pa);
%  [h,p] = subset_rtp_allcloudfields(h,p,[],[],10);
%  run_sarta.ncol0 = -1;
%  tic
    p1 = driver_pcrtm_cloud_rtp(h,ha,p,pa,run_sarta);
%  toc
  p1 = rmfield(p1,'robs1');
  rtpwrite(outfile,h,ha,p1,pa);
end

