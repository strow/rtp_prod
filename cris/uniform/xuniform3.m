function [dbtun, mbt] = uniform3(head, prof, idtest);

% function [dbtun, mbt] = uniform3(head, prof, idtest);
%
% Determine spatial uniformity of CrIS data.  For each FOR it
% determines the max difference in mean BT (over idtest) of the
% nine FOVs. Uses brute force searches to avoid trouble with
% data holes and thus it is a little slow. version3.
%
% Input:
%    head    - [structure] RTP header with required fields: (ichan, vchan)
%    prof    - [structure] RTP profiles with required fields: (robs1,
%                 rtime, ifov, atrack, xtrack, findex)
%    idtest  - [1 x ntest] ID of test channels
%
% Output:
%    dbtun   - [1 x nobs] max delta BT {K}; -9999 if no data
%    mbt     - [1 x nobs] mean BTobs {K} used in dbtun tests

% Created: 03 Mar 2011, Scott Hannon
% Update: 14 Mar 2011, S.Hannon - bug fix for bot & top inddbt
% Update: 04 May 2011, S.Hannon - made mbt an output variable
% Update: 05 Jun 2012, S.Hannon - version3 (intra-FOR only) created
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Required fields
hreq = {'ichan', 'vchan'};
preq = {'robs1', 'rtime', 'ifov', 'findex', 'atrack', 'xtrack'};

% Adjacent CrIS scanlines around about 8 seconds apart; round up to 9
dtamax = 9;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 3)
   error('unexpected number of input arguments')
end
d = size(idtest);
if (length(d) ~=2 | min(d) ~= 1)
   error('unexpected dimensions for argument idtest')
end
ntest = length(idtest);
for ii=1:length(hreq)
   if (~isfield(head,hreq{ii}))
      error(['head is missing required field ' hreq{ii}])
   end
end
for ii=1:length(preq)
   if (~isfield(prof,preq{ii}))
      error(['prof is missing required field ' preq{ii}])
   end
end


% Determine indices of idtest in head.ichan
[idtestx,indtest,junk] = intersect(head.ichan,idtest);
if (length(idtestx) ~= ntest)
   error('did not find all idtest in head.ichan')
end


% Determine unique scanlines (as findex*100 + atrack)
% and their mean rtime
f100a = round(100*prof.findex + prof.atrack); % exact integer
uf100a = unique(f100a);
nscan = length(uf100a);
tscan = zeros(1,nscan);
for ii=1:nscan
   jj = find(f100a == uf100a(ii));
   tscan(ii) = mean(prof.rtime(jj));
end
nobs = length(prof.findex);


% Compute BT of test channels
ftest = head.vchan(indtest);
r = prof.robs1(indtest,:);
ibad = find(r < 1E-6);
r(ibad) = 1E-6;
badbt = zeros(ntest,nobs);
badbt(ibad) = 1;
badbt = max(badbt);
mbt = mean(radtot(ftest,r)); % [1 x nobs]
clear r ibad


% Compute dbtun
dbtun = -9999*ones(1,nobs);


% Loop over the scanlines
for ii=1:nscan

disp(['doing scanline ' int2str(ii) ' of ' int2str(nscan)])

   indscan = find(f100a == uf100a(ii));

   % Determine the number of FORs in current scanline
   uix = unique( prof.xtrack(indscan) );
   nuix = length(uix);

   % Loop over FORs
   for ix = 1:nuix
      ind = indscan( find(prof.xtrack(indscan) == uix(ix)) );
      nind = length(ind); % number of FOVs in current FOR
      if (nind == 9)
         junk = mbt(ind);
         if (sum(badbt(ind)) == 0)
            dbtun(ind) = max(junk) - min(junk);
         else
            dbtun(ind) = -9999;
         end
      else
         dbtun(ind) = -9999;
      end
   end % loop over FORs

end % loop over scanlines


%%% end of routine %%%
