iasi_paths

for f = findfiles([prod_dir '/' datestr(JOB(1),'yyyy/mm/dd') '/ecm.iasi_l1c*'])
  disp(['Loading ' f{1}])
  [h ha p pa] = rtpread(f{1});
  disp(get_attr(ha,'rtpfile'))
  [h2 ha2 p2 pa2] = rtpgrow(h,ha,p,pa);
  if ~isequal(size(p2.rcalc),size(p2.robs1))
    disp('different sizes')
    unlink(f{1})
  end
  if ~isequal(size(p.rtime),size(p2.rtime))
    disp('different rtimes')
  end
  %get_attr(ha2,'rtpfile')
end
