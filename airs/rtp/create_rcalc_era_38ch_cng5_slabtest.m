airs_paths

for f = findfiles(['/asl/data/rtprod_airs/' datestr(JOB(1),'yyyy/mm/dd') '/airs_ctr.*.rtp'])

bn=basename(f{1});
outfile_cld = [dirname(f{1}) '/cld_era_38ch_cng5_slab.' bn];
outfile_clr = [dirname(f{1}) '/clr_era_38ch_cng5_slab.' bn];
if ~lockfile(outfile_cld); disp(['Lock file found, skipping ' outfile_cld]); continue; end
if exist(outfile_cld, 'file'); disp(['File found, skipping ' outfile_cld]); continue; end

disp(['Processing ' f{1}])

[head hattr prof pattr] = rtpread(f{1});
%[head hattr prof pattr] = rtpgrow(head, hattr, prof, pattr);
head.nchan = length(head.ichan);
head.vcmin = min(head.vchan);
head.vcmax = max(head.vchan);
prof = ProfSubset2(prof,prof.rtime > 1000 & prof.rlat > -100);
pattr=set_attr(pattr,'rtime','Seconds since 1 Jan 1993');
mdate = datenum(1993,1,1,0,0,prof.rtime);

  tic
for d = unique(sort(round([mdate-.1 mdate mdate+.1] * 8) / 8));
  disp(['reading era file for: ' datestr(d)])
  %[Y M D h m s]= datevec(d);
  [head, hattr, prof, pattr] = rtpadd_era_data(head,hattr,prof,pattr,{'CC','CIWC','CLWC','SP','SKT','10U','10V','TCC','CI','T','Q','O3'});
  [head, hattr, prof, pattr] = rtpadd_emis_wis(head,hattr,prof,pattr);
  toc
end


airs_cloudy


[head,prof] = subset_rtp(head,prof,[],sort([41   54  181  273  317  359  445  449  532  758  903  904 1000 1020 1034 1055 1075 1103 1249 1282 1291 1447 1475 1557 1604 1614 1618 1660 1790 1866 1867 1868 1878 1888 2112 2140 2321 2333]),[]);
prof.clwc = clwc;
prof.ciwc = ciwc;
prof.cc = cc;
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';

hattr = set_attr(hattr,'rtpfile',outfile_clr);

if JOB(1) < datenum(2003,10,01)
  sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte';
else
  sarta_exec='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte';
end
hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);

% write out clear
keyboard
[head1 hattr1 prof1 pattr1] = rtpsarta(head,hattr,prof,pattr);
rtpwrite(outfile_clr,head1,hattr1,prof1,pattr1);


sarta_exec = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte';
hattr = set_attr(hattr,'sarta_exec',sarta_exec);
hattr = set_attr(hattr,'klayers_exec',klayers_exec);

% write out cloudy
[head2 hattr2 prof2 pattr2] = rtpsarta(head,hattr,prof,pattr);
[head2 hattr2 prof2 pattr2] = rtptrim(head2,hattr2,prof2,pattr2);
rtpwrite(outfile_cld,head2,hattr2,prof2,pattr2);




end
