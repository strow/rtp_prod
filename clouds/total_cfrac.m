function [cfracw, cfraci] = total_cfrac(plevs, CC, CLWC, CIWC);

% function [cfracw, cfraci] = total_cfrac(plevs, CC, CLWC, CIWC);
%
% Estimate the mean cloud fraction for water and ice clouds over the
% total vertical extent of the profile.
%
% Input:
%    plevs    : [nlev x n] pressure grid {mb}
%    CC       : [nlev x n] Cloud Cover fraction {any}
%    CLWC     : [nlev x n] Cloud Liquid Water Content
%    CIWC     : [nlev x n] Cloud Ice Water Content {any}
%
% Output:
%    cfracw   : [1    x n] water cloud fraction
%    cfraci   : [1    x n] ice cloud fraction
%

% Created: 06 Mar 2009, Scott Hannon - created
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin ~= 4)
   error('Invalid number of arguments')
end


% Check input
d = size(plevs);
if (length(d) ~= 2)
   error('plevs must be a [nlev x n] array')
end
nlev = d(1);
n = d(2);
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


% Declare the output array
cfracw = zeros(1,n);
cfraci = zeros(1,n);

% Convert level profile to a mean layer profile
inda = 1:(nlev - 1);
indb = 2:nlev;
z= -7*log(plevs/1013);
dz90 = abs(z(inda,:) - z(indb,:));
c90 = 0.5*(   CC(inda,:) +    CC(indb,:));
w90 = 0.5*( CLWC(inda,:) +  CLWC(indb,:) + 1E-20); 
i90 = 0.5*( CIWC(inda,:) +  CIWC(indb,:) + 1E-20); 
% Note: add a tiny abmount to w90 and i90 so they are never zero

% Estimate weighted cloud fractions
cfracw = sum(c90 .* w90) ./ sum(w90);
cfraci = sum(c90 .* i90) ./ sum(i90);

%%% end of function %%%
