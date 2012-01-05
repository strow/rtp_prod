function [nun, indun, dbtun] = uniform2(freq, rad, calflag, itest, dbtmax, ...
   flagmax);

% function [nun, indun, dbtun] = uniform2(freq, rad, calflag, itest, dbtmax,...
%    flagmax);
%
% Performs a test on a 3-D matrix of granule radiances and returns the
% indices of the uniform FOVs found in each scanline.  The uniformity
% test calcs the mean brightness temperature (BT) of the test channels
% for all FOVs.  For each FOV, it compares the BT of all adjacent FOVs
% and declares the FOV uniform only if the maximum difference in BT
% is less than dbtmax.
% uniform2.m is the same as uniform.m except it also returns dbtun. 
%
% Input:
%    freq   : [nchan x 1] approximate channel frequency (cm-1)
%     rad   : [nchan x nxtrack x natrack] radiance (mW/m2 1/cm-1 1/steradian)
%    calflag: [nchan x natrack] radiance calibration bit flags
%    itest  : [ntest x 1] indices of channels to be used in the uniformity test
%    dbtmax : [1 x 1] max difference in BT for uniformity (Kelvin)
%    flagmax: [1 x 1] max passing calflag
%
% Output:
%    nun   : [natrack x 1] number of uniform FOVs in each scanline
%    indun : [natrack x nxtrack] indices of uniform FOVs for each scanline
%       Only the first nun(ia) entries are filled for each scanline ia=1:135
%    dbtun : [natrack x nxtrack] max abs delta BT of uniform FOVs
%       Only the first nun(ia) entries are filled for each scanline ia=1:135
%
% Where
%    natrack = along-track dimension (ie scanlines)
%    nxtrack = cross-track dimension (ie FOVs per scanline)
%    nchan   = number of channels
%    ntest   = number of test channels
%

% Created: 12 Nov 2002, Scott Hannon - based on uniform.m
% Update: 05 Oct 2005, S.Hannon - correct a serious bug affecting the
%    "next scanline" calc (using "ia" where it should be "ia+1"). As
%    a result of the bug, the atrack index was off by 1, and a repeated
%    scanline was used in testing atrack=2 & 3.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[nchan, nxtrack, natrack]=size(rad);

% Check if the the dimensions are obviously wrong
mtest=max(itest);
if (mtest > nchan)
   error('uniform: index in itest exceeds nchan')
end
if (nxtrack < 3)
   error('uniform: cross-track dimension is too small');
end
if (natrack < 3)
   error('uniform: along-track dimension is too small');
end
if (length(freq) ~= nchan)
   error('uniform: freq and rad have different nchan');
end
if (length(dbtmax) ~= 1)
   error('uniform: dbtmax must be a scaler, not an array')
end


% rtiny = tiny default radiance to plug in when radiance is negative
rtiny=1E-15;


% Pull of the test channel freqs
f=freq(itest);


% Calc btmean for all FOVs in the first scanline
ia=1;
r=squeeze( rad(itest,:,ia) );
r( find(r < 0) )=1E-15;  % tiny value
btmean2=mean( radtot(f,r) );
flag2=max( calflag(itest,ia) );

% Calc btmean for all FOVs in the second scanline
ia=2;
r=squeeze( rad(itest,:,ia) );
r( find(r < 0) )=1E-15;
btmean3=mean( radtot(f,r) );
flag3=max( calflag(itest,ia) );

% Cross-track indices to be used to calc adjacent FOV BT differnce
ix=2:(nxtrack-1);
ixm1=ix-1;
ixp1=ix+1;

% Declare an array to use for the BT differences of the 8 adjacent FOVs
dbt=zeros(8,length(ix));

% Declare the output arrays
nun=zeros(natrack,1);
indun=zeros(natrack,nxtrack);
dbtun=zeros(natrack,nxtrack);

% Loop over the scanlines
for ia=2:(natrack-1)
   btmean1=btmean2;   % previous scanline = ia-1
   btmean2=btmean3;   % current scanline = ia
   flag1=flag2;
   flag2=flag3;
   % next scanline = ia+1
   r=squeeze( rad(itest,:,ia+1) );
   r( find(r < 0) )=1E-15;
   btmean3=mean( radtot(f,r) );
   flag3=max( calflag(itest,ia+1) );

   iflag=max([flag1,flag2,flag3]);
   if (iflag <= flagmax)
      % Calc dbt for each of the 8 adjacent FOVs
      dbt(1,:)=abs( btmean2(ix) - btmean1(ixm1) );
      dbt(2,:)=abs( btmean2(ix) - btmean1(ix)   );
      dbt(3,:)=abs( btmean2(ix) - btmean1(ixp1) );

      dbt(4,:)=abs( btmean2(ix) - btmean2(ixm1) );
      dbt(5,:)=abs( btmean2(ix) - btmean2(ixp1) );

      dbt(6,:)=abs( btmean2(ix) - btmean3(ixm1) );
      dbt(7,:)=abs( btmean2(ix) - btmean3(ix)   );
      dbt(8,:)=abs( btmean2(ix) - btmean3(ixp1) );

      % Find indices of uniform observations
      xdbt=max(dbt);
      iok=find( xdbt < dbtmax );
      ixok=ix( iok );
      nok=length(ixok);

      % Put current scanline results in output arrays
      nun(ia)=nok;
      indun(ia,1:nok)=ixok;
      dbtun(ia,1:nok)=xdbt(iok);
   end

end

%%% end of function %%%
