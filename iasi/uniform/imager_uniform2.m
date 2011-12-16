function [uflag, btall, btsub, nall, nsub, stdall, stdsub]=imager_uniform2(...
   IASI_Image, drnoise, dbtmaxall, dbtmaxsub, nminall, nminsub, stdmaxall, ...
   stdmaxsub);

%function [uflag, btall, btsub, nall, nsub, stdall, stdsub]=imager_uniform2(...
%   IASI_Image, drnoise, dbtmaxall, dbtmaxsub, nminall, nminsub, stdmaxall, ...
%   stdmaxsub);
%
% For each of the "n" FOVs do a spatial uniformity test on the central
% 40x40 of 64x64 imager data, and also do a uniformity tests on four
% semi-circular FOV subsets.
%
% Input:
%    IASI_Image= [n x 4096] IASI Imager radiance data
%    drnoise   = [1 x 1] imager delta R noise (2.0)
%    dbtmaxall = [1 x 1] max delta BT for entire FOV uniformity test(7.0)
%    dbtmaxsub = [1 x 1] max delta BT for sub FOV uniformity test (2.0)
%    nminall   = [1 x 1] min # pixels (of 1600) within dbtmaxall+noise (1587)
%    nminsub   = [1 x 1] min # pixels (of 221) within dbtmaxsub+noise (215)
%    stdmaxall = [1 x 1] max std dev of all fovs imager pixels (2.0)
%    stdmaxsub = [1 x 1] max std dev of each fov imager pixels (0.6)
%
% Output:
%    uflag  = [n x 4] uniform flag (0=not, 1=uniform)
%    btall  = [n x 1] mean BT of all imager pixels
%    btsub  = [n x 4] mean BT of subset imager pixels
%    nall   = [n x 1] number of imager pixels within dbtmaxall+noise of mean
%    nsub   = [n x 4] number of imager pixels within dbtmaxsub+noise of mean
%    stdall = [n x 1] std dev of all fovs IASI Imager
%    stdsub = [n x 4] std dev of each fov IASI Imager
%

% Created: 31 March 2010, Scott Hannon - based on imager_uniform.m and
%    imager_uniform_ifov.m
% Update: 03 May 2010, S.Hannon - fix reversed indices for fovs 1 & 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


% netcdf tools

% Channel freq of IASI imager channel for BT conversion
fimager = 890.0;

% Expected data dimensions
npixfov = 4;    % number of IASI "pixels" per FOV (ie 2x2 = 4)
nimager = 4096; % number of IASI Imager pixels (64 x 64)
% Note: an IASI "FOV" is composed of a 2x2 square of IASI "pixels".

% tiny default radiance to plug in when radiance is negative
rtiny = ttorad(fimager,150);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = size(IASI_Image);
if (length(d) ~= 2 | d(2) ~= nimager)
   error('unexpected dimensions for IASI_Image data')
end
nax = d(1);


% Declare empty output variables
uflag  = zeros(nax,npixfov);
nall   = zeros(nax,1);
btsub  = zeros(nax,npixfov);
btall  = zeros(nax,1);
nsub   = zeros(nax,npixfov);
stdall = zeros(nax,1);
stdsub = zeros(nax,npixfov);

%%%
%% Replace bad imager data with rtiny
%ibad = find(IASI_Image < rtiny);
%if (length(ibad) > 0)
%   IASI_Image(ibad) = rtiny;
%end
%%%

% Indices for imager central 40x40 pixels
indall = zeros(40*40,1);
ind1to40 = 1:40;
indrow = 12 + (1:40);
for jj = 1:40
   ind = (jj-1)*40 + ind1to40;
   indall(ind) = indrow + 64*(jj-1);
end

% Half dBT range
bhrall = dbtmaxall/2.0; % half range
bhrsub = dbtmaxsub/2.0; % half range


% The IASI IFOV map to the Imager 64x64 pixel grid as approximate circles
% of diameter 17 pixels centered at (21,21), (21,44), (44,21), and (44,44).
% symmetric ifov mask index offset (relative to center at index=0)
% Note: index in 1D array of 64^2 elements
ifovmaskindexoffset = round([(-2:2)+(-8*64), (-4:4)+(-7*64), ...
   (-5:5)+(-6*64), (-6:6)+(-5*64), (-7:7)+(-4*64), (-7:7)+(-3*64), ...
   (-8:8)+(-2*64), (-8:8)+(-1*64), (-8:8), (-8:8)+(1*64), ...
   (-8:8)+(2*64), (-7:7)+(3*64), (-7:7)+(4*64), (-6:6)+(5*64), ...
   (-5:5)+(6*64), (-4:4)+(7*64), (-2:2)+(8*64)])'; %'
nmask = length(ifovmaskindexoffset);
%
% ifov center index
% Note: index in 1D array of 64^2 elements
%% old
%ifovcenterindex=round([21+(43*64), 44+(43*64), 44+(20*64), 21+(20*64)]);
%%% fix 03 May 2010
ifovcenterindex=round([ 44+(20*64), 44+(43*64), 21+(43*64), 21+(20*64)]);
%%%

%
% Indices for imager ifov subsets
indsub = ifovmaskindexoffset*ones(1,npixfov) + ones(nmask,1)*ifovcenterindex;


% Loop over the IASI imager FOVs
for ii = 1:nax

   % IASI Imager data for central 40x40 pixels
   rall = IASI_Image(ii,indall);

   % Find obvious bad imager data
   ibad = find(rall < rtiny);
   iok = find(rall > rtiny);
   nbad = length(ibad);
   nok = length(iok);
   if (nbad > 0)
      rall(ibad) = rtiny;
   end


   % Do uniformity tests if most pixels are OK
%   if (nok > nminall)
      % BT of 40x40 central imager pixels
      bta = radtot(fimager,rall);

      % Mean BT and std dev of BT of all imager pixels
      btall(ii) = mean(bta(iok));
      stdall(ii) = std(bta(iok));

      % Convert delta R noise to delta BT noise
      rmean = ttorad(fimager,btall(ii));
      junk = radtot(fimager,rmean+drnoise);
      bhnoise = (junk - btall(ii))/2; % half delta BT noise
      bqnoise = bhnoise/2; % quarter delta BT noise

      % Find imager pixels within "all" dbt range
      bhralln = bhrall + bhnoise;
      ipass = find( bta > (btall(ii) - bhralln) & bta < (btall(ii) + bhralln));
      nall(ii) = length(ipass);


      % Loop over the "sub" FOVs if "all" FOV passes test
%      if (nall(ii) > nminall & stdall(ii) <= stdmaxall+bqnoise)
         for jj=1:npixfov

            % Find bad radiance and replace it with rtiny
            rsub = IASI_Image(ii,indsub(:,jj));
            ibad = find(rsub < rtiny);
            iok = find(rsub > rtiny);
            rsub(ibad) = rtiny;

            % Convert radiance to BT
            bts = radtot(fimager,rsub);

            % Mean BT and std dev of BT of subset
            btsub(ii,jj) = mean(bts(iok));
            stdsub(ii,jj) = std(bts(iok));

            % Convert delta R noise to delta BT noise
            rmean = ttorad(fimager,btsub(ii,jj));
            junk = radtot(fimager,rmean+drnoise);
            bhnoise = (junk - btsub(ii,jj))/2; % half delta BT noise
            bqnoise = bhnoise/2; % quarter delta BT noise

            % Find imager pixels within "sub" dbt range
            bhrsubn = bhrsub + bhnoise;
            ipass = find( bts > (btsub(ii,jj) - bhrsubn) & ...
                          bts < (btsub(ii,jj) + bhrsubn) );
            nsub(ii,jj) = length(ipass);

            % Find passing FOVs and set uniformity flag
            if (stdsub(ii,jj) < stdmaxsub+bqnoise & nsub(ii,jj) >= nminsub)
               uflag(ii,jj) = 1;
            end
         end % for npixfov
%      end % FOV pass test

%   end % nok

end % for nax

%%% end of function %%%
