function [foldmat new_gtops] = mkfold(gtops,varargin);
%function [foldmat new_gtops] = mkfold(gtops,varargin);
%
% Fold handler, this function will take folds made by gstatsx and reduce them
%   to indicies that are usable elsewhere.
%
%  [myFold gtops_new] =  ...
%       mkfold(gtops,field_name,field_bins[,field_name2,field_bins2...]);
%
%    gtops can either be a structure or directory with stats files
%    field_bins can be 'keep' to maintain existant bins.
%
% Example:
%   [myFold new_gtops] = mkfold(gtops,'rlat',-60:10:60);
%   [myFold new_gtops] = mkfold(gtops,'rlat','keep');
%   [myFold new_gtops] = mkfold('./gsx_directory','rlat','keep');


if nargin == 0
  error('MKFOLD: No directory/gtops specified to fold');
end

if mod(length(varargin),2) == 1
  error('MKFOLD: The field_name and field_bins must be in pairs');
end

if isstr(gtops)
  if exist(gtops,'dir')
    f = findfiles([gtops '/*.mat']);
    load(f{1},'gtops');
  else
    error(['MKFOLD: Directory ' gtops ' does not exist'])
  end
end

if isstruct(gtops)
  if isfield(gtops,'gtops')
    gtops = gtops.gtops;
  end
end

% Get all the selection fields from the gt structure
gt_names = fieldnames(gtops);
sel_names = gt_names(find(~cellfun(@isempty,regexp(gt_names,'_bins$'))));
disp('Folds found:')
for i = 1:length(sel_names)
  disp(['  ' sel_names{i}(1:end-5) ' = [' sprintf(' %g',gtops.(sel_names{i})) ' ]'])
  if nargin == 1; foldmat.(sel_names{i}) = gtops.(sel_names{i}); end
end

% if we are only looking for the details of what is in the file...
if nargin == 1
  return
end

if length(varargin) == 0
  error('MKFOLD: No fields specified to fold on');
end

new_gtops = gtops;
past_folds = {};
n_folds = 1;
fold_count = 0;
fold_vec = [];
disp('Making folds:')
for i = 1:2:length(varargin)
  % Some error checking for fields:

  % was this field specified in the binning routine?
  if ~isfield(gtops,[varargin{i} '_bins'])
    if strcmp(varargin{i+1},'keep')
      disp(['MKFOLD: field ' varargin{i} ' is not specified in gtops but not requested']);
      continue
    else
      error(['MKFOLD: field ' varargin{i} ' is not specified in gtops (no fold made with given field)']);
    end
  end

  % do we 'keep' the bins the same:
  if strcmp(varargin{i+1},'keep')
    varargin{i+1} = getfield(gtops,[varargin{i} '_bins']);
  end

  % special case for solzen
  %if isequal(varargin{i},'solzen')
  %  
  %end

  % do we don't have a selection chriteria, if not does the binning match what we have?
  if ~isfield(gtops,[varargin{i} '_sel']) 
    if isequal(getfield(gtops,[varargin{i} '_bins']),varargin{i+1})
      disp(['  -- ' varargin{i} ' (left the same)']);
      continue
    else
      disp(['Bins requested:' sprintf(' %g',varargin{i+1})])
      disp(['Bins found:' sprintf(' %g',getfield(gtops,[varargin{i} '_bins']))])
      error(['MKFOLD: field ' varargin{i} ' does not match the bin specified in gtops']);
    end
  end

  % will the binning work with the bins we already have?
  if ~isequal(reshape(intersect(getfield(gtops,[varargin{i} '_bins']),varargin{i+1}),1,[]),reshape(varargin{i+1},1,[]))
    disp(['Bins requested: ' sprintf(' %g',varargin{i+1})])
    disp(['Bins found: ' sprintf(' %g',getfield(gtops,[varargin{i} '_bins']))])
    disp(['Bins matched: ' sprintf(' %g',intersect(getfield(gtops,[varargin{i} '_bins']),varargin{i+1}))])
    error(['MKFOLD: Bins requested cannot be used as bin edges do not match'])
  end

  disp(['  -- ' varargin{i}])
  [junk ftmp] = histc(eval(['gtops.' varargin{i} '_bins(gtops.' varargin{i} '_sel)']),varargin{i+1});
  ftmp(ftmp == 0 | ftmp == length(varargin{i+1})) = nan;

  n = length(varargin{i+1})-1;
  if isempty(fold_vec)
    fold_vec = ftmp;
  else
    fold_vec = (ftmp - 1) * n_folds + fold_vec;
  end

  new_gtops = setfield(new_gtops,[varargin{i} '_bins'],varargin{i+1});
  % begin by folding the previous bins
  for pf = past_folds
    new_gtops = setfield(new_gtops,pf{1},repmat(getfield(new_gtops,pf{1}),[1 n]));
  end
  temp = (repmat(1:n,[n_folds 1]));
  new_gtops = setfield(new_gtops,[varargin{i} '_sel'],reshape(temp,[1 n_folds*n]));

  n_folds = n_folds * n;
  fold_count = length(getfield(gtops,[varargin{i} '_sel']));
  past_folds = [past_folds [varargin{i} '_sel']];
end

% here we change the folds from a 1D reference list into a 2D matrix:
foldmat = zeros([fold_count n_folds]);
for j = 1:size(foldmat,1)
  if ~isnan(fold_vec(j))
    foldmat(j,fold_vec(j)) = 1;
  end
end
foldmat = logical(foldmat);

gt_names = fieldnames(gtops);
sel_names = gt_names(find(~cellfun(@isempty,regexp(gt_names,'_sel$'))));
for i = 1:length(sel_names)
  % remove selections with just ones:
  if all(getfield(new_gtops,sel_names{i}) == 1)
    new_gtops = rmfield(new_gtops,sel_names{i});
    continue;
  end

  % skip over folds we have already [re]binned:
  if ismember(sel_names{i},past_folds); continue; end

  % continue to folds that still need removing:
  cursel = getfield(gtops,sel_names{i});
  curbins = getfield(gtops,[sel_names{i}(1:end-4) '_bins']);

  new_gtops = rmfield(new_gtops,sel_names{i});
  new_gtops = setfield(new_gtops,[sel_names{i}(1:end-4) '_bins'],curbins([1 end]));
end
