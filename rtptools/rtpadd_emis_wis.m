function [head hattr prof pattr] = rtpadd_emis_wis(head,hattr,prof,pattr)

mtime = rtpdate(prof, pattr);
dv = datevec(nanmean(mtime));

  try
    [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
  catch
    if dv(3) > 15
       dv = datevec(JOB(1) + 30);
      [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
    else
       dv = datevec(JOB(1) - 30);
      [prof emis_qual emis_str] = Prof_add_emis(prof, dv(1), dv(2), dv(3), 0, 'nearest', 2, 'all');
    end
  end
  pattr = set_attr(pattr,'emis',emis_str);

prof.nrho= prof.nemis;
prof.rho = (1.0 - prof.emis)/pi;

