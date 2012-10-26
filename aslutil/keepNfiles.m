function tmpname = keepNfiles(filename, nkeep)
%function tmpname = keepNfiles(filename, nkeep)
%
%  Keep N number of files, return a temporary name and unzip if necessary

% Written by Paul Schou - 9 May 2011


persistent in_fnames out_fnames in_fdates
if nargin < 2; nkeep = 5; end

% sanity check to make sure the file we are requesting actually exists
d = dir(filename);
if length(d) == 0; error(['Missing file ' filename]); end

% this section checks for collisions, and will return a valid file handle for a file in cache
sel = strcmp(in_fnames, filename) & d.datenum == in_fdates;
if any(sel)
  disp('found a match, testing if file exists')
  %out_fnames{find(sel,1)}
end

if any(sel) & exist(out_fnames{find(sel,1)},'file')
  disp(['  keepNfiles called on: ' filename ' (cached)'])
  tmpname = out_fnames{find(sel,1)};
  in_fnames = [{filename} in_fnames{~sel}];
  out_fnames = [{tmpname} out_fnames{~sel}];
  in_fdates = [d.datenum in_fdates(~sel)];
  return;
end
disp(['  keepNfiles called on: ' filename])

% this section will delete a file when the count is greater than nkeep
if length(out_fnames) > nkeep
  for i = min(1,nkeep):length(out_fnames)
    unlink(out_fnames{i});
    for f = findfiles([out_fnames{i} '.*'])
      disp(['  removing ' f{1}])
      unlink(f{1});
    end
  end
  in_fnames = in_fnames(1:nkeep-1);
  out_fnames = out_fnames(1:nkeep-1);
  in_fdates = in_fdates(1:nkeep-1);
end

% if we are only asked to clear out files
if isempty(filename); return; end

% create cache or gunzip the file into a cache location for use
tmpname = mktemp([tmpdir() '/keep']);

if strcmp(filename(max(1,end-2):end),'.gz')
  copyfile(filename,[tmpname '.gz']);
  delete(tmpname);
  %disp(['  gunzip ' tmpname '.gz'])
  [status result] = system(['gunzip ' tmpname '.gz']);
  if(status>0)
    disp('Error running shell gunzip:');
    disp(result);
    error('Gunzip Error');
%  try
%    gunzip([tmpname '.gz'])
%  catch
%    error(['Error gunzipping: ' tmpname '.gz, is the drive full?'])
%  end
  end
  unlink([tmpname '.gz'])
else
  %disp(['  copy ' filename])
  copyfile(filename,tmpname);
end

in_fnames = [{filename} in_fnames];
out_fnames = [{tmpname} out_fnames];
in_fdates = [d.datenum in_fdates];
