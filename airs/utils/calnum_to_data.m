function [nedt,ab,ical] = calnum_to_data(calnum,cstr);

% function [nedt,ab,ical] = calnum_to_data(calnum,cstr);
%
% Split calnum into separate calibration info variables
%
% Input:
%    calnum         - [2378 x nobs] 8-bit calibration number
%                        bits1-4 = NeDT(@250K) lookup table index-1 {0-15}
%                        bit5    = A side detector {0=off, 1=on}
%                        bit6    = B side detector {0=off, 1=on}
%                        bits7-8 = calflag&calchansummary {see ical}
%    cstr           - [string] character string describing calnum; must
%                        include substring "NEdT[" followed by 16 numbers.
%
% Output:
%    nedt           - [2378 x nobs] noise equivalent delta BT(@250K)
%    ab             - [2378 x nobs] A/B state {0=opt,1=A, 2=B}
%    ical           - [2378 x nobs] calflag&calchansummary summary
%                        {0=OK, 1=DCR, 2=moon-in-view, 3=other}
%

% Created: 02 Jun 2010, Scott Hannon
% Update: 11 Nov 2010, S.Hannon - replace outputs l1,lb,lcalflag &
%    lcalchansummary with ab & ical
% Update: 10 Jan 2011, S.Hannon - update description comment (no code changes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 2)
   error('Unexpected number of input arguments')
end
d = size(calnum);
if (length(d) ~= 2 | d(1) ~= 2378)
   error('Unexpected dimensions for argument "calnum"');
end
nobs = d(2);


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
ical = zeros(2378,nobs);
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
ab = 3*ones(2378,nobs);
ab(ii) = ab(ii) - 1;
xcalnum(ii) = round(xcalnum(ii) - 32); % exact integer
%
% Remove bit5
ii = find(xcalnum >= 16);
ab(ii) = ab(ii) - 2;
xcalnum(ii) = round(xcalnum(ii) - 16); % exact integer


%%% old
%% Remove bit8
%lcalchansummary = zeros(2378,nobs);
%ii = find(xcalnum >= 128);
%lcalchansummary(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 128); % exact integer
%%
%% Remove bit7
%lcalflag = zeros(2378,nobs);
%ii = find(xcalnum >= 64);
%lcalflag(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 64); % exact integer
%%
%% Remove bit6
%lb = zeros(2378,nobs);
%ii = find(xcalnum >= 32);
%lb(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 32); % exact integer
%%
%% Remove bit5
%la = zeros(2378,nobs);
%ii = find(xcalnum >= 16);
%la(ii) = 1;
%xcalnum(ii) = round(xcalnum(ii) - 16); % exact integer
%%%


% Convert nedt index-1 to nedt
ind = round(xcalnum + 1);
nedt = lutable(ind);

%%% end of file %%%
