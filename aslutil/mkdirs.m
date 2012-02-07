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
if ~exist(dir,'dir')
  if(nargin > 1)
    mkdirs(fileparts(dir),perms,groups);
  else
    mkdirs(fileparts(dir));
  end
  mkdir(dir);
end

if(nargin > 1)
  fileattrib(dir,perms,groups);
end
