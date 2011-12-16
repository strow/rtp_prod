function p = p60_ecmwf(psfc, lhalf);

% function [p] = p37_ecmwf( psfc, lhalf );
%
% Return the fixed 37 ECMWF "full-level" pressures based upon the
% surface pressure.  If optional argument "lhalf" equals 1 then
% it returns "half-level" pressures instead.
%
% Input:
%    psfc  : (1 x nprof) surface pressure (mb)
%    lhalf : OPTIONAL (1 x 1) output half-levels? {1=true, 0=false=default}
%
% Output:
%    p     : (60 x nprof) ECMWF pressure levels (mb)
%

% Taken from Walter Wolf's grib package
%
% Note:  ecmwf_a/b assume using Pascal's, so you will see
%        some *100 and /100's in the code to switch from
%        mbar to Pascals
%
% V1.0:  LLS, 8/17/01
% V1.1:  Scott Hannon, 28 August 2001 - changes so psfc can be a (1 x nprof)
% Update: 07 Apr 2009, S.Hannon - added code for optional half-levels output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 1 | nargin > 2)
   error('Unexpected number of input arguments')
end
if (nargin == 1)
   lhalf = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sigma to half-level coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
ecmwf_a = [0 1 2 3 5 7 10 20 30 50 70 100 125 150 175 200 225 250 300 350 ...
  400 450 500 550 600 650 700 750 775 800 825 850 875 900 925 950 975 1000]';
%


%%%%%%%%%%%%
% Check psfc
%%%%%%%%%%%%
[nrow,ncol]=size(psfc);
if (nrow ~= 1)
   disp('Error: psfc must be a (1 x nprof) vector!')
   return
else
   nprof=ncol;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate pressure levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Half-level pressures
phalf = ( ecmwf_a*ones(1,nprof) );

if (lhalf == 1)
   % Average full-levels to get half-level pressures
   p = ( phalf(1:end-1,:) + phalf(2:end,:) )/2;
else
   p = phalf(2:end,:);
end

%%% end of function %%%
