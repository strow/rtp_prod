function [nedt,ab,ical] = calnum_to_data(calnum,cstr);

% function [nedt,ab,ical] = calnum_to_data(calnum,cstr);
%
% Split calnum into separate calibration info variables
%
% Input:
%    calnum         - [nchan x nobs] 8-bit calibration number
%                        bits1-4 = NeDT(@250K) lookup table index-1 {0-15}
%                        bit5    = A side detector {0=off, 1=on}
%                        bit6    = B side detector {0=off, 1=on}
%                        bits7-8 = calflag&calchansummary {see ical}
%    cstr           - [string] character string describing calnum; must
%                        include substring "NEdT[" followed by 16 numbers.
%
% Output:
%    nedt           - [nchan x nobs] noise equivalent delta BT(@250K)
%    ab             - [nchan x nobs] A/B state {0=opt,1=A, 2=B}
%    ical           - [nchan x nobs] calflag&calchansummary summary
%                        {0=OK, 1=DCR, 2=moon-in-view, 3=other}
%

% Created: 02 Jun 2010, Scott Hannon
% Update: 11 Nov 2010, S.Hannon - replace outputs l1,lb,lcalflag &
%    lcalchansummary with ab & ical
% Update: 10 Jan 2011, S.Hannon - update description comment (no code changes)
% Update: 19 Oct 2011, S.Hannon - allow arbitrary nchan (was 2378 only);
%    check cstr and convert to char if cell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 2)
   error('Unexpected number of input arguments')
end
d = size(calnum);
%if (length(d) ~= 2 | d(1) ~= 2378)
if (length(d) ~= 2)
   error('Unexpected dimensions for argument "calnum"');
end
nchan= d(1);
nobs = d(2);
%
if (~ischar(cstr))
   if (iscell(cstr))
%      disp('converting cstr cell to char')
      cstr = char(cstr);
   else
      error('unexpected class for cstr')
   end
end

% Read NEdT lookup table from cstr
ii = strfind(cstr,'NEdT[');
if (length(ii) == 0)
  error('Unable to find "NEdT[" substring in cstr')
end
ii = ii+5;
junk = textscan(cstr(ii:end),'%n',16);
lutable = junk{1};
clear junk ii


% Start pulling off bits from calnum
xcalnum = calnum;

% Remove bit8
ii = find(xcalnum >= 128);
ical = zeros(nchan,nobs);
ical(ii) = 2;
xcalnum(ii) = round(xcalnum(ii) - 128); % exact integer
%
% Remove bit7
ii = find(xcalnum >= 64);
ical(ii) = ical(ii) + 1;
xcalnum(ii) = round(xcalnum(ii) - 64); % exact integer
%
% Remove bit6
ii = find(xcalnum >= 32);
ab = 3*ones(nchan,nobs);
ab(ii) = ab(ii) - 1;
xcalnum(ii) = round(xcalnum(ii) - 32); % exact integer
%
% Remove bit5
ii = find(xcalnum >= 16);
ab(ii) = ab(ii) - 2;
xcalnum(ii) = round(xcalnum(ii) - 16); % exact integer


%%% old
%% Remove bit8
%lcalchansummary = zeros(nchan,nobs);
%ii = find(xcalnum >= 128);
%lcalchansummary(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 128); % exact integer
%%
%% Remove bit7
%lcalflag = zeros(nchan,nobs);
%ii = find(xcalnum >= 64);
%lcalflag(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 64); % exact integer
%%
%% Remove bit6
%lb = zeros(nchan,nobs);
%ii = find(xcalnum >= 32);
%lb(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 32); % exact integer
%%
%% Remove bit5
%la = zeros(nchan,nobs);
%ii = find(xcalnum >= 16);
%la(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 16); % exact integer
%%%


% Convert nedt index-1 to nedt
ind = round(xcalnum + 1);
nedt = lutable(ind);

%%% end of file %%%
