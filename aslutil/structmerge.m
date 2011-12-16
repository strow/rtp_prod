function [out] = structmerge(dat, dim)
%
% STRUCTMERGE - Takes an array of structures and combines them all together with pre-declaring the array size for efficiency.
%
%   all_profs = structmerge(profs,2)
%   all_heads = structmerge(heads,1)

% Written by Paul Schou - 1 July 2009  (paulschou.com)
if(nargin < 2)
  dim = 2;
end

if(numel(dat) == 1)
  out = dat;
  return
end

if iscell(dat)
  dat = cell2mat(dat);
end

out = struct;
fields = fieldnames(dat(1));
for i = 1:length(fields)
  count = [];
  % check to see that the field exists in every struct
  for j = 1:length(dat)
    if(~isfield(dat(j),fields{i}))
      error('Field names are not the same');
    end
  
    % count up the number of fields
    if(~isempty(getfield(dat(j),fields{i})))
      if(isempty(count))
        % start the count of the field sizes
        count = size(getfield(dat(j),fields{i}));
        if(length(count) < dim) count(length(count)+1:dim) = 1; end
      else
        % add sizes along the specified dimension
        %if(count(3-dim) ~= size(getfield(dat(j),fields{i}),3-dim))
        %  error('dimensions change')
        %else
          count(dim) = count(dim) + size(getfield(dat(j),fields{i}),dim);
        %if(length(size(getfield(dat(j),fields{i}))) == 2 && dim == 3)
        %  count(3) = count(3) + 1
        %end
        %end
      end
    end
  end

  % if the field is a sub structure, skip it
  try
  if(isstruct(getfield(dat(1),fields{i}))); continue; end
  catch e
    fields{i}
    keyboard
  end

  % pre-declare the size of the array
  if(sum(count) == 0)
    t = [];
  elseif ischar(getfield(dat(1),fields{i}))
    t = char(zeros(count,'uint8'));
  else
    %fields{i}
    %class(getfield(dat(1),fields{i}))
    t = zeros(count,class(getfield(dat(1),fields{i})));
  end
  st = 1;

  for j = 1:length(dat)
    if(~isempty(getfield(dat(j),fields{i})))
      en = st + size(getfield(dat(j),fields{i}),dim) - 1;
      if(dim == 1)
        t(st:en,:) = getfield(dat(j),fields{i});
      elseif(dim == 2)
        t(:,st:en) = getfield(dat(j),fields{i});
      elseif(dim == 3)
        try
        t(:,:,st:en) = getfield(dat(j),fields{i});
        catch
         disp(['st=' num2str(st) ' en=' num2str(en) ' size=[' num2str(size(getfield(dat(j),fields{i}))) '] field=' fields{i}])
        end
      elseif(dim == 4)
        try
        t(:,:,:,st:en) = getfield(dat(j),fields{i});
        catch
         disp(['st=' num2str(st) ' en=' num2str(en) ' size=[' num2str(size(getfield(dat(j),fields{i}))) '] field=' fields{i}])
        end
      end
      st = en + 1;
    end
  end
  out = setfield(out,fields{i},t);
  dat = rmfield(dat,fields{i});
end

end %function
