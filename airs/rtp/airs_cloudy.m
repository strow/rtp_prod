%
%  Compute the cloudy sarta fields using Scott's SlabCloud reader
%
%   Based on: /asl/matlab/gribtools/readecmwf_nearest_slabcloud.m
%
%  Written by: Paul Schou  (Jan 2013)

% Min allowed cloud fraction
cmin = 0.001;

% Max allowed cngwat[1,2]
cngwat_max = 500;


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

% Error checks:

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
%[head,prof] = subset_rtp(head,prof,[],sort([1291 903 445 1614 1557 359]),[]);
prof.clwc = clwc;
prof.ciwc = ciwc;
prof.cc = cc;
