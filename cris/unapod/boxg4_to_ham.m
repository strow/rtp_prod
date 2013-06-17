function [rham] = boxg4_to_ham(ichan, rbox);

% function [rham] = boxg4_to_ham(ichan, rbox);
%
% Convert CrIS "g4" radiance from boxcar (unapodized) data to
% Hamming apodized.
%
% Input:
%    ichan  -  [nchan x 1] channel IDs using the "g4" 1306-1329
%       numbering for the guard channels.
%    rbox   -  [nchan x nobs] unapodized (boxcar) radiance
%
% Output:
%    rham   - [nchan x nobs] Hamming apodized radiance.  All
%       channels are returned, but any channel lacking a low
%       and/or high adjacent neighbor channel is NaN.
%

% Created: 04 Jan 2012, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 2)
   error('Unexpected number of input arguments')
end
d = size(ichan);
if (length(d) ~= 2 | min(d) ~= 1)
   error('Unexpected dimensions for argument ichan')
end
nchan = max(d);
[n,nobs] = size(rbox);
if (n ~= nchan)
   error('Lead dimension of rbox must match length of ichan')
end


% All "g4" channels in order with gaps denoted by "x"
x = -9999; % No data
idx = [x,1306:1309,1:713,1310:1313,x,1314:1317,714:1146,1318:1321,x, ...
	1322:1325,1147:1305,1326:1329,x];

% Declare output
rham = NaN*ones(nchan,nobs,class(rbox));


% Loop over the channels
for ic=1:nchan
   id = ichan(ic); % current channel ID
   %
   % Find index of id in idx
   ii = find(id == idx);
   %
   if (length(ii) == 1)
      % Adjacent channel IDs
      idlo = idx(ii-1);
      idhi = idx(ii+1);
      % 
      % Find adjacent channels IDs in ichan
      if (min([idlo, idhi]) > 0);
         ilo = find(idlo == ichan);
         ihi = find(idhi == ichan);
         if (length(ilo) == 1 & length(ihi) == 1)
            % Compute Hamming
            rham(ic,:) = 0.23*rbox(ilo,:) + 0.54*rbox(ic,:) + 0.23*rbox(ihi,:);
         end
      end
   else
      error(['Unexpected g4 channel ID = ' int2str(id)])
   end
end

%%% end of program %%%
