function [cfrac, tavg]=slab_cfrac(plevs,ptemp,CC,CLWC,CIWC,iceflag,ptop,pbot);

%function [cfrac,tavg]=slab_cfrac(plevs,ptemp,CC,CLWC, CIWC,iceflag,ptop,pbot);
%
% Estimate cloud cover fraction and average temperature for a slab cloud
% spanning the pressure range pbot to ptop. 
%
% Input:
%    plevs    : [nlev x n] pressure grid {mb}
%    ptemp    : [nlev x n] temperature profile {K}
%    CC       : [nlev x n] Cloud Cover fraction {any}
%    CLWC     : [nlev x n] Cloud Liquid Water Content
%    CIWC     : [nlev x n] Cloud Ice Water Content {any}
%    iceflag  : [1    x n] ice flag {1=ice, 0=water}
%    ptop     : [1    x n] cloud top pressure {mb}
%    pbot     : [1    x n] cloud bottom pressure {mb}
%
% Output:
%    cfrac    : [1    x n] cloud fraction
%
% Note: returns cfrac=0 and tavg=-9999 if ptop or pbot are outside plev range
%

% Created: 06 Mar 2009, Scott Hannon - created
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin ~= 8)
   error('Invalid number of arguments')
end


% Check input
d = size(plevs);
if (length(d) ~= 2)
   error('plevs must be a [nlev x n] array')
end
nlev = d(1);
n = d(2);
d = size(ptemp);
if (length(d) ~= 2 | d(1) ~= nlev | d(2) ~= n)
   error('ptemp must be a [nlev x n] array')
end
d = size(CC);
if (length(d) ~= 2 | d(1) ~= nlev | d(2) ~= n)
   error('CC must be a [nlev x n] array')
end
d = size(CLWC);
if (length(d) ~= 2 | d(1) ~= nlev | d(2) ~= n)
   error('CLWC must be a [nlev x n] array')
end
d = size(CIWC);
if (length(d) ~= 2 | d(1) ~= nlev | d(2) ~= n)
   error('CIWC must be a [nlev x n] array')
end
d = size(iceflag);
if (length(d) ~= 2 | d(1) ~= 1 | d(2) ~= n)
   error('iceflag must be a [1 x n] array')
end
d = size(ptop);
if (length(d) ~= 2 | d(1) ~= 1 | d(2) ~= n)
   error('ptop must be a [1 x n] array')
end
d = size(pbot);
if (length(d) ~= 2 | d(1) ~= 1 | d(2) ~= n)
   error('pbot must be a [1 x n] array')
end
ibad = find(ptop > pbot);
if (length(ibad) > 0)
   error('Must have all ptop < pbot');
end


% Declare the output array
cfrac = zeros(1,n);
tavg = zeros(1,n);


% Determine which profiles have ptop & pbot within min/max of plevs
pmin = min(plevs(1,:),plevs(nlev,:));
pmax = max(plevs(1,:),plevs(nlev,:));
iok = find( ptop >= pmin & pbot <= pmax);
ical = zeros(1,n);
ical(iok) =  1;
ibad = find(ical == 0);
cfrac(ibad) = 0;
tavg(ibad) = -9999;

% Determine which profile indices are ice and which are water
indi = find(iceflag == 1 & ical == 1);
indw = find(iceflag ~= 1 & ical == 1);
ni = length(indi);
nw = length(indw);

% Loop over ice clouds
for ii = 1:ni
   ip = indi(ii);

   % Interpolate data to a 10 point grid spanning pbot to ptop
   dp = (pbot(ip) - ptop(ip))/9;
   pgrid = pbot(ip) - (0:9)*dp;
   tgrid = interp1(plevs(:,ip),ptemp(:,ip),pgrid,'linear','extrap');
   cgrid = interp1(plevs(:,ip),   CC(:,ip),pgrid,'linear','extrap');
   igrid = interp1(plevs(:,ip), CIWC(:,ip),pgrid,'linear','extrap');

   % Weight first and last point half as much as other points
   igrid( 1) = 0.5*igrid(1);
   igrid(10) = 0.5*igrid(10);

   ci = cgrid .* igrid;
   sci = sum(ci);
   tavg(ip) = sum( ci .* tgrid ) ./ sci;
   cfrac(ip) = sci ./ sum( igrid);

%%%
%if (isnan(cfrac(ip)) == 1)
%keyboard
%end
%%%


end

% Loop over water clouds
for ii = 1:nw
   ip = indw(ii);

   % Interpolate data to a 10 point grid spanning pbot to ptop
   dp = (pbot(ip) - ptop(ip))/9;
   pgrid = pbot(ip) - (0:9)*dp;
   tgrid = interp1(plevs(:,ip),ptemp(:,ip),pgrid,'linear','extrap');
   cgrid = interp1(plevs(:,ip),   CC(:,ip),pgrid,'linear','extrap');
   wgrid = interp1(plevs(:,ip), CLWC(:,ip),pgrid,'linear','extrap');

   % Weight first and last point half as much as other points
   wgrid( 1) = 0.5*wgrid(1);
   wgrid(10) = 0.5*wgrid(10);

   cw = cgrid .* wgrid;
   scw = sum(cw);
   tavg(ip) = sum( cw .* tgrid ) ./ scw;
   cfrac(ip) = scw ./ sum( wgrid);

end

%%% end of function %%%
