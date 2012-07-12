airs_paths

for f = findfiles(['/asl/data/rtprod_airs/' datestr(JOB(1),'yyyy/mm/dd') '/airs_ctr.*.rtp'])

bn=basename(f{1});
outfile_cld = [dirname(f{1}) '/cld_era_38ch.' bn];
outfile_clr = [dirname(f{1}) '/clr_era_38ch.' bn];
if ~lockfile(outfile_cld); disp(['Lock file found, skipping ' outfile_cld]); continue; end
if exist(outfile_cld, 'file'); disp(['File found, skipping ' outfile_cld]); continue; end

% Min allowed cloud fraction
cmin = 0.001;

% Max allowed cngwat[1,2]
cngwat_max = 500;

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

%datestr(mdate(isnan(prof.cc(1,:))))

[nlev nprof] = size(prof.ptemp);


profX = prof;
ecmwfcld2sartacld
% wait quite a bit of time

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set rtpV201 cloud2 fields
%%%%%%%%%%%%%%%%%%%%%%%%%%%
prof.cngwat2 = prof.udef(11,:);
prof.cpsize2 = prof.udef(12,:);  % replaced later
prof.cprtop2 = prof.udef(13,:);
prof.cprbot2 = prof.udef(14,:);
prof.cfrac2  = prof.udef(15,:);  % replaced later
prof.cfrac12 = prof.udef(16,:);  % replaced later
prof.ctype2  = prof.udef(17,:);


% Replace cfrac info
[cfracw, cfraci] = total_cfrac(profX.plevs,profX.cc,profX.clwc,profX.ciwc);
tcc = profX.cfrac;
[prof.cfrac, prof.cfrac2, prof.cfrac12] = fake_cfracs(tcc, cfracw, cfraci, ...
   prof.ctype, prof.ctype2);

prof.clwc = profX.clwc;
prof.ciwc = profX.ciwc;
prof.cc = profX.cc;
clear profX

% Compute cloud temperature
pavg = 0.5*(prof.cprtop + prof.cprbot);
ibad = find(prof.cfrac == 0);
pavg(ibad) = 500; % safe dummy value
tavg1 = rtp_t_at_p(pavg, head, prof);
pavg = 0.5*(prof.cprtop2 + prof.cprbot2);
ibad = find(prof.cfrac2 == 0);
pavg(ibad) = 500; % safe dummy value
tavg2 = rtp_t_at_p(pavg, head, prof);
clear ibad

% Replace cpsize and cpsize2
iceflag = zeros(1,nprof);
ii = find(prof.ctype == 201);
iceflag(ii) = 1;
prof.cpsize  = fake_cpsize(tavg1, iceflag, 1);
%
iceflag = zeros(1,nprof);
ii = find(prof.ctype2 == 201);
iceflag(ii) = 1;
prof.cpsize2 = fake_cpsize(tavg2, iceflag, 1);
clear iceflag tavg1 tavg2

% Remove cloud fractions less than some minimum
hcmin = 0.5*cmin;

ix=find(prof.cfrac < cmin);
prof.cfrac(ix)  = 0;
prof.cfrac12(ix)= 0;
prof.cngwat(ix) = 0;
prof.ctype(ix)  = -1;
prof.cprtop(ix) = -9999;
prof.cprbot(ix) = -9999;

ix=find(prof.cfrac2 < cmin);
prof.cfrac2(ix)  = 0;
prof.cfrac12(ix) = 0;
prof.cngwat2(ix) = 0;
prof.ctype2(ix)  = -1;
prof.cprtop2(ix) = -9999;
prof.cprbot2(ix) = -9999;

ix = find(prof.cfrac12 >= hcmin & prof.cfrac12 < cmin);
prof.cfrac12(ix) = cmin;
ix = find(prof.cfrac12 < hcmin);
prof.cfrac12(ix) = 0;
junk = prof.cfrac(ix) + prof.cfrac2(ix);
ii = ix( find(junk > 1) );
ii1 = ii( find(prof.cfrac(ii) > prof.cfrac2(ii)) );
ii2 = setdiff(ii,ii1);
prof.cfrac(ii1) = prof.cfrac(ii1)-hcmin;
prof.cfrac2(ii2) = prof.cfrac2(ii2)-hcmin;

% Error check for cloud fractions
ii = prof.cfrac12 > prof.cfrac | prof.cfrac12 > prof.cfrac2;
prof.cfrac12(ii) = min(prof.cfrac(ii), prof.cfrac2(ii));

prof.cprbot(prof.cprbot > prof.spres) = prof.spres(prof.cprbot > prof.spres);
prof.cprbot2(prof.cprbot2 > prof.spres) = prof.spres(prof.cprbot2 > prof.spres);
% Error: CPRTO2 > CPRBO2
prof.cprtop2(prof.cprtop2 > prof.cprbot2) = prof.cprbot2(prof.cprtop2 > prof.cprbot2);
% CPRTO1 outside allowed PLEVS1 to  SPRES range
prof.cprtop(prof.cprtop > prof.spres) = prof.spres(prof.cprtop > prof.spres);

% extra check
prof.cprtop(prof.cprtop > prof.cprbot) = prof.cprbot(prof.cprtop > prof.cprbot);


clwc = prof.clwc;
ciwc = prof.ciwc;
cc = prof.cc;
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
