%
% NAME
%
%   simpcat -- simple concatenation of RTP profile sets
%
% SYNOPSIS
%
%   simpcat(f1, f2);
%   simpcat(f1, f2, f3);
%
% INPUTS
% 
%   f1   - RTP input file #1 name
%   f2   - RTP input file #2 name
%   f3   - RTP output file name (optional)
%
% OUTPUT
%
%   the file f3, a concatenation of f1 and f2
%   if f3 is not specified, f2 is appended to f1
%
% DISCUSSION
%
%   simpcat concatenates RTP files with identical field sets.
%   The field sets and the order of the field names, as returned 
%   by "fieldnames", must match or simpcat returns an error.
%
%   The header and attributes of f3 are taken from f1, and any 
%   separate header or attribute info in f2 is lost.
%
%   On errors, simpcat prints a warning and returns, but it does 
%   not call the matlab error function.  This allows processing to
%   continue when it is called from inside a loop with occasional 
%   bad data.
%
% H. Motteler, 15 Oct 02
%

function simpcat(f1, f2, f3);

% append f2 to f1 if only two filenames are given
if nargin == 2
  f3 = f1;
end

% read the input files
[h1, ha1, p1, pa1] = rtpread(f1);
[h2, ha2, p2, pa2] = rtpread(f2);

% get the profile field names
pfields1 = fieldnames(p1);
pfields2 = fieldnames(p2);

% get file parts for error messages
[path1,fn1,ex1] = fileparts(f1);  fn1 = [fn1,ex1];
[path2,fn2,ex2] = fileparts(f2);  fn2 = [fn2,ex2];

% check that the field sets match
if isequal(pfields1, pfields2)

  % loop on field sets
  for i = 1 : length(pfields1)

    % concatenate fields
    fname = pfields1{i};

    % check that fields have the same number of rows
    eval(sprintf('[m1,n1]=size(p1.%s);', fname));
    eval(sprintf('[m2,n2]=size(p2.%s);', fname));
    if m1 ~= m2
      fprintf(2, 'simpcat warning -- field sizes do not match:\n')
      fprintf(2, '   file %s field %s has %d rows\n', f1, fname, m1)
      fprintf(2, '   file %s field %s has %d rows\n', f2, fname, m2)
      return
    end

    % append the p2 field to the corresponding p1 field
    % e.g., p1.plevs = [p1.plevs, p2.plevs];
    eval(sprintf('p1.%s = [p1.%s, p2.%s];', fname, fname, fname));
  end

else
  % report that the field sets do not match
  fprintf(2, ...
	  'simpcat warning -- field sets in %s and %s do not match\n', ...
          f1, f2)
  return
end

% save p1, the updated profile set
rtpwrite(f3, h1, ha1, p1, pa1);

