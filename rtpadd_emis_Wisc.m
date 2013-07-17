function [head hattr prof pattr] = rtpadd_emis_Wisc(head, hattr, prof, pattr)
% function [head hattr prof pattr] = rtpadd_emis_Wisc(head, hattr, prof, pattr)
%
% Add the Wiscounsin emissivity data into profile
%
% Breno Imbiriba - 2013.06.27


  sy = get_attr(pattr,'rtime');
  sy = sy(end-3:end);
  sy = str2num(sy);

  if(sy~=1993 & sy~=2000)
    warning('Bad rtime attribute - it should be either 1993 or 2000 - will use 2000.');
    sy=2000;
  end
  mtime = tai2mattime(prof.rtime, sy);

  % Separate data in months:
  vtime = datevec(mtime);

  nprof = numel(mtime);

  prof.nemis = -9999*ones(1,nprof);
  prof.emis  = -9999*ones(1,nprof);
  prof.efreq = -9999*ones(1,nprof);
  prof.nrho  = -9999*ones(1,nprof);
  prof.rho   = -9999*ones(1,nprof);
 


  for yyyy = min(vtime(:,1)):max(vtime(:,1))
    for mm = min(vtime(:,2)):max(vtime(:,2))
      ifind = find(vtime(:,1) == yyyy & vtime(:,2) == mm);

      [hin pin] = subset_rtp(head,prof,[],[],ifind); 

      pout = Prof_add_emis(pin, yyyy, mm, 15, 0, 'nearest', 2, 'all');

      % Add data back to prof
      ne1 = size(pout.emis,1);

      prof.nemis(1,ifind) = pout.nemis(1,:);
      prof.emis(1:ne1,ifind)  = pout.emis;
      prof.efreq(1:ne1,ifind) = pout.efreq;
      prof.nrho(1,ifind)  = pout.nrho(1,:);
      prof.rho(1:ne1,ifind)   = pout.rho;

    end
  end

  pattr = set_attr(pattr,'emis','Wiscounsin');

end 

