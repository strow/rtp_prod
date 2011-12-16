function isgood = lockfile(fname,failtime)
%function isgood = lockfile(fname,failtime)
%
% This function creates a temporary lock file in the directory of the directory of the given
%   file name prefixed with a '.' and postfixed with '.lock'.  It will return a 1 or a 0 indicating
%   if it is good to continue or not.
%
%   if ~lockfile(fout); continue; end
%

  if strcmp(fname,'clean')
    clear lockfile_handles
    return
  end

  global lockfile_handles
  [a b c] = fileparts(fname);
  if isempty(a); a = pwd; end
  if a(1) ~= '/'; a = [pwd '/' a]; end
  lockname = [a '/.' b c '.lock'];

  if nargin < 2
    failtime = 0.1;
  end

  % declare we are working on this day so we don't have two processes working on the same day
  if exist(lockname,'file') % if the file already exists, test to see if the age is old:
    g=dir(lockname); if now-g.datenum < failtime; isgood = 0; return; end
  end
  fh=fopen(lockname,'w');fclose(fh);  % create an empty lock file
  isgood = 1;

  c = onCleanup(@()unlink(lockname));
  lockfile_handles = [lockfile_handles c];

end
