function [head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr)
%function [head, hattr, prof, pattr] = rtpklayers(head, hattr, prof, pattr)
%
%  A simple function to run klayers on a file and return the result

%if isfield(head,'gunit') && head.gunit(1) == 1

if isfield(prof,'rcalc'); prof = rmfield(prof,'rcalc'); end
if isfield(prof,'robs1'); robs1 = prof.robs1; prof = rmfield(prof,'robs1'); end
if isfield(prof,'calflag'); calflag = prof.calflag; prof = rmfield(prof,'calflag'); end

klayers_exec = get_attr(hattr,'klayers_exec');
sarta_exec = get_attr(hattr,'sarta_exec');
hattr = rm_attr(hattr,'klayers');
hattr = rm_attr(hattr,'sarta');

if ~isempty(klayers_exec)
  tmp1 = mktemp();
  tmp2 = mktemp();
  rtpwrite(tmp1, head, hattr, prof, pattr);
  clear hattr pattr
  if head.ptype > 0
    disp('  rtpklayers: Already in levels, skipping')
    movefile(tmp1, tmp2);
  else
    disp(['    ' klayers_exec ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
    system([klayers_exec ' fin=' tmp1 ' fout=' tmp2 ' > /dev/null']);
    delete(tmp1)
  end
  disp(['    ' sarta_exec ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
  system([sarta_exec ' fin=' tmp2 ' fout=' tmp1 ' > /dev/null']);
  [head2, hattr, prof2, pattr] = rtpread(tmp1);
  delete(tmp2)
  delete(tmp1)
  prof.rcalc = prof2.rcalc;
else
  error('Cannot run klayers / sarta')
end

if exist('robs1','var'); prof.robs1 = robs1; end
if exist('calflag','var'); prof.calflag = calflag; end
