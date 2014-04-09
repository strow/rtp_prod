function [head hattr prof pattr] = rtpadd_co2(head, hattr, prof, pattr, type)
% function [head hattr prof pattr] = rtpadd_co2(head, hattr, prof, pattr, type)
%
% Add CO2 to the RTP structure.
%
% type = 1 - Linear growth formula:
%            
%            CO2ppm = 370 + Rate*(Days_since_2002) - where Rate = 2/365.25 (it's a daily rate)
%
% B.I. 2014/04/08

if(type==1)

  dtime = tai2mattime(prof.rtime)-datenum(2002,1,1);
  prof.co2ppm = 372 + 2.*(dtime/365.25);

  pattr = set_attr(pattr,'co2ppm','370 + Rate*(Days_since_2002), Rate = 2/365.25');
  
else
  error('Bad CO2 type')
end

end
