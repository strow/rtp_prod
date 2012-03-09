function dat = getudef(prof,pattr,field)
%function dat = getudef(prof,pattr,field)
% Scan the rtp udef fields for given field name and return the result.
%
% If no field is given a structure is returned instead.
%
% Example:
%   reason = getudef(prof,pattr,'reason');
%   udef_struct = getudef(prof,pattr);

dat = [];
if nargin == 3 & isempty(field)
  error('Error: no field name specified')
end

for i = 1:length(pattr)
  t = regexp(pattr{i}{3},'{[a-zA-Z0-9_]*}','match');
  if ~isempty(t)
    fname = t{1}(2:end-1);
    if strcmp(fname(max(1,end-3):end),'_bit'); fname= fname(1:end-4); end
  else
    fname = [];
  end

  sname = pattr{i}{2};
  % add some backwards compatibility for L1bCM
  if strcmp(sname(1:min(6,end)),'L1bCM '); sname = sname(7:end); end

  if nargin < 3
    dat.(fname) = eval(['prof.' sname]);
  elseif strcmp(fname,field)
    %disp(['  ' field '= prof.' sname]);
    dat = eval(['prof.' sname]);
    return
  elseif strcmp(pattr{i}{3}(1:min(length(field),end)),field)
    %disp(['  ' field '= prof.' sname]);
    dat = eval(['prof.' sname]);
    return
  end
end

if nargin == 3
  disp(['Warning [getudef]: field {' field '} not found in pattr']);
end
