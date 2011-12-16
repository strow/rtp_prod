function dname=dirname(fname)
%DIRNAME Strip non-directory suffix from file name
%   d_name = DIRNAME(File) - Returns the directory in which the
%                            file is located

% Version 1.0, Written by Paul Schou - 26 Oct 2008

[dname file ext]=fileparts(fname);

if strcmp(dname,'')
  dname = '.';
end
