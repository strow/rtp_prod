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
base = '';
re = regexp(dir,'/[^/]*','match'); % Dies if improper dimensionality is requested
for j = 1:length(re)
  base = [base re{j}];
  if ~exist(base,'dir')
    %disp(['mkdir ' base]);
    mkdir(base);
    if(nargin > 1)
      fileattrib(base,perms,groups);
    end
  end
end
