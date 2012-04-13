function [iatrack, ixtrack] = l2_ind2track(ind);

% function [iatrack, ixtrack] = l2_ind2track(ind);
%
% Convert AIRS Level 2 1-D array indices to along-track and
% cross-track 2-D array indices.
%
% Input:
%    ind = [1 x n] AIRS level2 granule file 1-D array index {1-1350}
%
% Output:
%    iatrack = [1 x n] AIRS L2 along-track index {1-45}
%    ixtrack = [1 x n] AIRS L2 cross-track index {1-30}
%

% Created: 19 May 2005, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% along-track and cross-track dimensions
natrack = 45;
nxtrack = 30;
nobs = natrack * nxtrack;


% Declare empty output vars
iatrack = [];
ixtrack = [];


% Check ind
d = size(ind);
if (length(d) ~= 2 | min(d) ~= 1)
   disp('Error: ind must be a [1 x n] vector')
   return
end
if (min(ind) < 1 | max(ind) > nobs)
   disp(['Error: ind must be within range 1-' num2int(nobs)]);
   return
end
n0 = length(ind);


% Determine output arrays
% Note: ind = ixtrack + (iatrack-1)*nxtrack
iatrack = floor( (ind - 0.999)/nxtrack ) + 1;
ixtrack = ind - ( nxtrack*(iatrack - 1) );

%%% end of function %%%
