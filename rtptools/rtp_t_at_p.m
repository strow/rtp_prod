function [t] = rtp_t_at_p(p, head, prof, lextrap);

% function [t] = rtp_t_at_p(p, head, prof, lextrap);
%
% Return interpolated temperature at stated pressure for given profiles.
%
% Input:
%    p     = [1 x 1] or [1 x n] pressure {mb, aka hPa}
%    head  = RTP header structure
%    prof  = RTP profile structure
%    optional: lextrap = allow extrapolation outside profile range?
%              0=false {default}, 1=true
%
% Output:
%    t = [1 x n] temperature {Kelvin}
%
% Note: returns "-9999" if p is outside the profile range and
%    extrapolation is not specified.
%

% Created: 25 February 2005, Scott Hannon
% Update: 12 Sep 2005, S.Hannon - fix message typos; fix pmin assignment;
%    add optional extrap argument.
% Update: 04 Feb 2009, S.Hannon - changes for rtpV201 (no prof.plays)
  % Update: 05 Mar 2009, S.Hannon - change p from [1 x 1] to [1 x n]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 3)
   disp('Error in rtp_t_at_p: insufficient arguments')
   return
else
   if (nargin == 4)
      lex = lextrap;
   else
      lex = 0; % default is no extrapolation
   end
end

% Check input
d = size(p);
if (length(d) ~= 2 | min(d) ~= 1)
   disp('Error in rtp_t_at_p: p must be a [1 x 1] scaler or [1 x n] array')
   return
end

if (isfield(head,'ptype'))
   ptype = head.ptype;
else
   disp('Error in rtp_t_at_p: head is missing required field ptype')
   return
end

if (isfield(prof,'nlevs'))
   nlevs = prof.nlevs;
else
   disp('Error in rtp_t_at_p: prof is missing required field nlevs')
   return
end

if (isfield(prof,'ptemp'))
   ptemp = prof.ptemp;
else
   disp('Error in rtp_t_at_p: prof is missing required field ptemp')
   return
end

if(ptype == 0 | ptype == 2)
   % WARNING! not sure if this is correct for ptype=2
   if (isfield(prof,'plevs'))
      pl = prof.plevs;
   else
      disp('Error in rtp_t_at_p: prof is missing required field plevs')
      return
   end
else
   pl = prof.plevs;
   nlevs = nlevs - 1;
   for ii=1:max(nlevs);
      p1=max([prof.plevs(ii,:), 1E-4]);
      p2=max([prof.plevs(ii+1,:),1E-4]);
      pl(ii,:) = (p2-p1)/log(p2/p1);
   end
end

% Declare output array
n = length(nlevs);   % number of profiles
t = -9999*ones(1,n); % no data (yet)

if (length(p) == 1)
   px = p*ones(1,n);
else
   px = p;
end


% Determine min & max pressure of each profile
% pmin = pl(1,:); % assumes pmin is first entry which might not be true
ibad = find( pl <= 0.0 );
junk = pl;
junk(ibad) = 1E+16;
pmin = min(junk);
pmax = max(pl);

% Determine which profiles can be processed
if (lex == 1)
   iok = 1:n;
else
   iok = find(px >= pmin & px <= pmax);
end
nok = length(iok);

% Loop over profiles for processing
if (nok > 0)
   for ii = 1:nok
      ip = iok(ii);
      lnp = log(px(ip));
      ind = 1:nlevs(ip);
      lnpin = log(pl(ind,ip));
      tin = ptemp(ind,ip);
      t(ip) = interp1(lnpin, tin, lnp, 'linear','extrap');
   end
end
%%% end of function %%%
