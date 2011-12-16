function unlink(fname)
%UNLINK Delete a file silently
%   UNLINK(File)

% Version 1.0, Written by Paul Schou - 26 Oct 2008

if(exist(fname,'dir') & (strcmp(fname(1:4),'/tmp') | strcmp(fname(1:8),'/dev/shm')))
  for f = findfiles(fname,'*')
    delete(f{1});
  end
  rmdir(fname)
elseif(exist(fname,'dir') & (strcmp(fname(1:8),'/dev/shm') | strcmp(fname(1:8),'/scratch')))
  for f = findfiles(fname,'*')
    delete(f{1});
  end
  rmdir(fname)
elseif(exist(fname,'dir'))
  disp(['WARNING: Will not delete directory ' fname]) 
elseif(exist(fname,'file') & strcmp(fname(1:4),'/tmp'))
  delete(fname)
  for f = findfiles([fname '.*'])
    delete(f{1});
  end
elseif(exist(fname,'file'))
  delete(fname)
end
