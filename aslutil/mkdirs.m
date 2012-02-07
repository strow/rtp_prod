function mkdirs(dir,perms,groups)
% function mkdirs(dir,perms,groups)
%
% A simple function to make a directory tree and set the user mod
%
% Example 1:
%   mkdirs('/tmp/test/me/here');
% Example 2:
%   mkdirs('/tmp/mod/me','+w +x','o g');

% Written by Paul Schou - 1 July 2009  (paulschou.com)
if ~exist(dir)

  % check to see if the parent exists by calling this function recursively
  if(nargin > 1)  % if we should pass the attributes to the parent tests
    mkdirs(fileparts(dir),perms,groups);
  else
    mkdirs(fileparts(dir));
  end

  % make the needed directory
  mkdir(dir);

  % if we should set the attributes do so here
  if(nargin > 1)
    fileattrib(dir,perms,groups);
  end
end
