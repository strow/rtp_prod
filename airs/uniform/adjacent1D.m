function [adjdata] = adjacent1D(nx, na, xtrack, atrack, data);

% function [adjdata] = adjacent1D(nx, na, xtrack, atrack, data);
%
% For each FOV in the input it determines the data in the
% 8 adjacent FOVs (ie the 8 points adjacent to the center
% point of a 3 x 3 grid).
%
% Input:
%    nx     : [1 x 1] full cross-track dimension {eg 90}
%    na     : [1 x 1] full along-track dimension {eg 135}
%    xtrack : [1 x nobs] cross-track index {1 to nx}
%    atrack : [1 x nobs] along-track index {1 to na}
%    data   : [1 x nobs] some data field
%
% Output:
%    adjdata : [8  x nobs] adjacent data; NaN if no available data
%       The (delta_xtrack, delta_atrack) for the 8 FOVs are:
%       index 1=(-1,-1), 2=(0,-1), 3=(+1,-1), 4=(-1,0), 5=(+1,0),
%       6=(-1,+1), 7=(0,+1), 8=(+1,+1)
%

% Created: 28 Jun 2006, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
%
if (nargin ~= 5)
   error('some required arguments are missing')
end
d = size(nx);
if (length(d) ~= 2 | max(d) ~= 1)
   error('nx must be dimension [1 x 1]')
end
if (abs(round(nx) - nx) > 0)
   error('nx must be an exact integer');
end
%
d = size(na);
if (length(d) ~= 2 | max(d) ~= 1)
   error('na must be dimension [1 x 1]')
end
if (abs(round(na) - na) > 0)
   error('na must be an exact integer');
end
%
d = size(xtrack);
if (length(d) ~= 2 | min(d) ~= 1)
   error('xtrack must be dimension [1 x nobs]')
end
if (max(abs(round(xtrack) - xtrack)) > 0)
   error('xtrack must be an exact integers');
end
if (min(xtrack) < 1 | max(xtrack) > nx)
   error('some values of xtrack are outside 1 to nx range')
end
nobs = max(d);
%
d = size(atrack);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= nobs)
   error('atrack must be dimension [1 x nobs]')
end
if (max(abs(round(atrack) - atrack)) > 0)
   error('atrack must be an exact integers');
end
if (min(atrack) < 1 | max(atrack) > na)
   error('some values of atrack are outside 1 to na range')
end
%
d = size(data);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= nobs)
   error('data must be dimension [1 x nobs]')
end


% Create expanded data array
nxp2 = nx + 2;
nap2 = na + 2;
xtrackp1 = xtrack + 1;
atrackp1 = atrack + 1;
nobsx = nxp2 * nap2;
datax = NaN*ones(1,nobsx);
indx = xtrackp1 + (atrackp1 - 1)*nxp2;
datax(indx) = data;


% Calculate indices of adjacent FOVs in expanded data array
ind1 = indx - 1 - nxp2;
ind2 = indx     - nxp2;
ind3 = indx + 1 - nxp2;
ind4 = indx - 1;
ind5 = indx + 1;
ind6 = indx - 1 + nxp2;
ind7 = indx     + nxp2;
ind8 = indx + 1 + nxp2;


% Assign output
adjdata = zeros(8,nobs);
adjdata(1,:) = datax(ind1);
adjdata(2,:) = datax(ind2);
adjdata(3,:) = datax(ind3);
adjdata(4,:) = datax(ind4);
adjdata(5,:) = datax(ind5);
adjdata(6,:) = datax(ind6);
adjdata(7,:) = datax(ind7);
adjdata(8,:) = datax(ind8);

%%% end of function %%%
