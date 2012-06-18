airs_paths
for f = findfiles(['/asl/data/rtprod_airs/' datestr(JOB(1),'yyyy/mm/dd') '/AIRS*CTR*'])
  [head hattr prof pattr] = rtpread(f{1}); 
  mtime=tai2mattime(nanmean(prof.rtime));
  infile = f{1};
  outfile = ['/asl/data/rtprod_airs/' datestr(mtime,'yyyy/mm/dd') '/airs_ctr.' datestr(mtime,'yyyy.mm.dd') '.' datestr(mtime,'HH') '.rtp'];
  if exist(outfile,'file'); continue; end
  hattr = set_attr(hattr,'rtpfile',outfile);
  %get_attr(hattr)
  rtpwrite(outfile,head,hattr,prof,pattr);
end
