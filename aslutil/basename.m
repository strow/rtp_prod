function bname=basename(fname,ending)
%BASENAME Strip directory and suffix from filenames
%   FILENAME = BASENAME(File) - Returns the name of the file without 
%                               a directory prefix
%
%   FILENAME = BASENAME(File, Suffix) - Returns the file name 
%                                       less the given suffix

% Version 1.0, Written by Paul Schou - 26 Oct 2008

[dname file ext]=fileparts(fname);
bname = [file ext];
try
 if(nargin == 2)
  ending_len = length(ending);
  if(bname(end-ending_len+1:end) == ending)
     bname = bname(1:end-ending_len);
  end
 end
catch
end
