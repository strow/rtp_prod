function [total] = totalgas_rtp(gasid, head, prof);
%
% function [total] = totalgas_rtp(gasid, head, prof);
%
% RTP utility program to calculate the total column of the
% specified gases from the sum of the profile layer amounts.
% The profile must be either "layers" or "pseudo-levels", the
% structures must include the requested gases, and the gas units
% must be molecules/cm^2.
%
% Input:
%    gasid = [ngas x 1] HITRAN ID numbers of desired gases
%    head  = {structure} RTP "head" with fields: ptype, glist, & gunit
%    prof  = {structure} RTP "prof" with fields: nlevs, gas_*
%
% Output:
%    total = {ngas x nprof} total gas column (molec/cm^2)
%

% Created: 2 June 2005, Scott Hannon - based on mmwater_rtp.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check gasid dimensions
d = size(gasid);
if (length(d) ~= 2 | min(d) ~= 1)
   error('gasid must be a [ngas x 1] array')
end
ngas = max(d);
ibad = find(gasid > 100 | gasid < 1);
if (length(ibad) > 0)
   error('unexpected gasid value(s)')
end


% Check ptype
if (~isfield(head,'ptype'))
   error('head field ptype not found')
else
   if (head.ptype < 1)
      error('head field ptype must "layers" or "pseudo-levels" (ptype=1 or 2)')
   end
end


% Check glist
if (~isfield(head,'glist'))
   error('head field glist not found')
else
   gind = zeros(ngas,1);
   for ii = 1:ngas
      jj = gasid(ii);
      kk = find( head.glist == jj );
      if (length(kk) == 1)
         gind(ii) = kk;
      else
        error(['head field glist must contain exactly one entry for gasid=' ...
        int2str(jj)]);
      end
   end
end


% Check gunit
if (~isfield(head,'gunit'))
   error('head field gunit not found')
else
   for ii = 1:ngas
      jj = gasid(ii);
      kk = head.gunit( gind(ii) );
      if (kk ~= 1)
         error(['head field gunit must have code=1 (molec/cm^2) for gasid=' ...
         int2str(jj)]);
      end
   end
end


% Check nlevs
if (~isfield(prof,'nlevs'))
   error('prof field nlevs not found')
end
nprof = length(prof.nlevs);


% Check spres
if (~isfield(prof,'spres'))
   error('prof field spres not found')
end


% Check plevs
if (~isfield(prof,'plevs'))
   error('prof field plevs not found')
end


% Check gas_*
for kk = 1:ngas
   gstr = ['gas_' int2str(gasid(kk))];
   if (~isfield(prof,gstr))
      error(['prof field ' gstr ' not found'])
   end
end


% Declare output array
total = zeros(ngas,nprof);
if (head.ptype == 1)
   allnlay = prof.nlevs - 1;
else
   % ptype == 2
   allnlay = prof.nlevs;
end


% Loop over the profiles
for ii = 1:nprof

   nlay = allnlay(ii);

   % Calc bottom (fractional) layer multiplier
   blmult=( prof.spres(ii)        - prof.plevs(nlay,ii) ) / ...
          ( prof.plevs(nlay+1,ii) - prof.plevs(nlay,ii) );

   % Loop over the gases
   for kk = 1:ngas
      gstr = ['gas_' int2str(gasid(kk))];
      eval(['amount=prof.' gstr '(1:nlay,ii);']);
      amount(nlay) = amount(nlay)*blmult;
      total(kk,ii) = sum(amount);
   end

end

%%% end of file %%%
