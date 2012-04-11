function [cfrac1,cfrac2,cfrac12]=fake_cfracs(tcc,cfracw,cfraci,ctype1,ctype2);

%function [cfrac1,cfrac2,cfrac12]=fake_cfracs(tcc,cfracw,cfraci,ctype1,ctype2);
%
% Generate fake cloud fractions based on estimates of water and ice cloud
% cover fractions and the total cloud cover fraction.
%
% Input:
%    tcc     = [1 x n] total cloud cover fraction {0.0 to 1.0}
%    cfracw  = [1 x n] water cloud cover fraction {0.0 to 1.0}
%    cfraci  = [1 x n] ice cloud cover fraction {0.0 to 1.0}
%    ctype1  = [1 x n] cloud1 type {negative=none, 101=water, or 201=ice}
%    ctype2  = [1 x n] cloud2 type {negative=none, 101=water, or 201=ice}
%
% Output:
%    cfrac1  = [1 x n] cloud1 non-exclusive fraction {0.0 to 1.0}
%    cfrac2  = [1 x n] cloud2 non-exclusive fraction {0.0 to 1.0}
%    cfrac12 = [1 x n] cloud1+2 fraction {0.0 to 1.0}
%

% Created: 09 Mar 2009, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Min allowed non-zero cloud fraction
cfracmin = 0.001;

% Check input
if (nargin ~= 5)
   error('Incorrect number of input arguments')
end
d = size(tcc);
if (length(d) ~= 2 | min(d) ~= 1)
   error('tcc must be a [1 x n] array')
end
n = max(d);
if (min(tcc) < 0 | max(tcc) > 1)
  error('some values of tcc outside expected range of 0-1')
end
d = size(cfracw);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n)
   error('cfrac1 must be a [1 x n] array')
end
if (min(cfracw) < 0 | max(cfracw) > 1)
  error('some values of cfracw outside expected range of 0-1')
end
d = size(cfraci);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n)
   error('cfrac2 must be a [1 x n] array')
end
if (min(cfraci) < 0 | max(cfraci) > 1)
  error('some values of cfraci outside expected range of 0-1')
end
d = size(ctype1);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n)
   error('ctype1 must be a [1 x n] array')
end
%ipos = find(ctype1 > 0);
%junk = setdiff(unique(ctype1(ipos)),[101, 201]);
%if (length(junk) > 0)
%  error('some values of ctype1 outside expected set of {negative, 101, 201}');
%end
d = size(ctype2);
if (length(d) ~= 2 | min(d) ~= 1 | max(d) ~= n)
   error('ctype2 must be a [1 x n] array')
end
%ipos = find(ctype2 > 0);
%junk = setdiff(unique(ctype2(ipos)),[101, 201]);
%if (length(junk) > 0)
%  error('some values of ctype2 outside expected set of {negative, 101, 201}');
%end


% Declare output arrays
cfrac1 = zeros(1,n);
cfrac2 = zeros(1,n);
cfrac12= zeros(1,n);


% Seed random number generater
rand('state',sum(100*clock));


% Determine which of siz possible cases apply for each index in n
% case1 = no clouds
% case2 = one water cloud
% case3 = one ice cloud
% case4 = two water clouds
% case5 = two ice clouds
% case6 = one water and one ice clouds
% note: case1 is default with zero cloud fractions
ic1 = find(ctype1+ctype2 < 0 | tcc < cfracmin);
ic21 = find(ctype1 == 101 & ctype2 < 0 & tcc >= cfracmin);
ic22 = find(ctype2 == 101 & ctype1 < 0 & tcc >= cfracmin);
ic31 = find(ctype1 == 201 & ctype2 < 0 & tcc >= cfracmin);
ic32 = find(ctype2 == 201 & ctype1 < 0 & tcc >= cfracmin);
ic4 = find(ctype1 == 101 & ctype2 == 101 & tcc >= cfracmin);
ic5 = find(ctype1 == 201 & ctype2 == 201 & tcc >= cfracmin);
ic61 = find(ctype1 == 101 & ctype2 == 201 & tcc >= cfracmin);
ic62 = find(ctype2 == 101 & ctype1 == 201 & tcc >= cfracmin);

%disp(['n1 = ' int2str(length(ic1))]);

% Do case2: one water cloud
cfrac1(ic21) = tcc(ic21);
cfrac2(ic22) = tcc(ic22);
%disp(['n21 = ' int2str(length(ic21))]);
%disp(['n22 = ' int2str(length(ic22))]);

% Do case3: one ice cloud
cfrac1(ic31) = tcc(ic31);
cfrac2(ic32) = tcc(ic32);
%disp(['n31 = ' int2str(length(ic31))]);
%disp(['n32 = ' int2str(length(ic32))]);

% Do case4 and 5: two water or two ice clouds
% Assume probability of no cloud overlap=(1 - TCC)
ic45 = union(ic4,ic5);
n45 = length(ic45);
%disp(['n4 = ' int2str(length(ic4))]);
%disp(['n5 = ' int2str(length(ic5))]);
if (n45 > 0)
   cfrac1(ic45) = rand(1,n45).*tcc(ic45);
   ioverlap = ic45( find(rand(1,n45) < tcc(ic45)) );
   if (length(ioverlap) > 0)
      cfrac12(ioverlap) = rand(1,length(ioverlap)).*cfrac1(ioverlap);
   end
   cfrac2(ic45) = tcc(ic45) - cfrac1(ic45) + cfrac12(ic45);
end


% Do case6: one water and one ice cloud
% Assume probability of no cloud overlap=(1 - TCC)
n61 = length(ic61);
if (n61 > 0)
   stcc = tcc(ic61);
   scfracw = cfracw(ic61);
   scfraci = cfraci(ic61);
   %
   ibad = find(scfracw > stcc);
   scfraci(ibad) = scfraci(ibad).*stcc(ibad)./scfracw(ibad);
   scfracw(ibad) = stcc(ibad);
   ibad = find(scfraci > stcc);
   scfracw(ibad) = scfracw(ibad).*stcc(ibad)./scfraci(ibad);
   scfraci(ibad) = stcc(ibad);
   %
   ibad = find(scfracw < cfracmin);
   scfracw(ibad) = cfracmin;
   ibad = find(scfraci < cfracmin);
   scfraci(ibad) = cfracmin;
   %
   sumcfracwi = scfracw + scfraci;
   ibad = find(sumcfracwi < stcc);
   nbad = length(ibad);
%disp(['n61 = ' int2str(n61) ', nbad ic61 = ' int2str(nbad)])
   if (nbad > 0)
      smin = stcc(ibad)./sumcfracwi(ibad);
      smax = stcc(ibad)./max(scfracw(ibad),scfraci(ibad));
      ioverlap = find(rand(1,nbad) < stcc(ibad));
      scale = smin;
      if (length(ioverlap) > 0)
         scale(ioverlap) = smin(ioverlap) + ...
            rand(1,length(ioverlap)).*(smax(ioverlap) - smin(ioverlap));
      end
      scfracw(ibad) = scfracw(ibad).*scale;
      scfraci(ibad) = scfraci(ibad).*scale;
   end
   cfrac1(ic61) = scfracw;
   cfrac2(ic61) = scfraci;
   cfrac12(ic61) = scfracw + scfraci - stcc;
   % WARNING: slightly negative values of cfrac12 possible
end
%
n62 = length(ic62);
if (n62 > 0)
   stcc = tcc(ic62);
   scfracw = cfracw(ic62);
   scfraci = cfraci(ic62);
   %
   ibad = find(scfracw > stcc);
   scfraci(ibad) = scfraci(ibad).*stcc(ibad)./scfracw(ibad);
   scfracw(ibad) = stcc(ibad);
   ibad = find(scfraci > stcc);
   scfracw(ibad) = scfracw(ibad).*stcc(ibad)./scfraci(ibad);
   scfraci(ibad) = stcc(ibad);
   %
   ibad = find(scfracw < cfracmin);
   scfracw(ibad) = cfracmin;
   ibad = find(scfraci < cfracmin);
   scfraci(ibad) = cfracmin;
   %
   sumcfracwi = scfracw + scfraci;
   ibad = find(sumcfracwi < stcc);
   nbad = length(ibad);
%disp(['n62 = ' int2str(n62) ', nbad ic62 = ' int2str(nbad)])
   if (nbad > 0)
      smin = stcc(ibad)./sumcfracwi(ibad);
      smax = stcc(ibad)./max(scfracw(ibad),scfraci(ibad));
      ioverlap = find(rand(1,nbad) < stcc(ibad));
      scale = smin;
      if (length(ioverlap) > 0)
         scale(ioverlap) = smin(ioverlap) + ...
            rand(1,length(ioverlap)).*(smax(ioverlap) - smin(ioverlap));
      end
      scfracw(ibad) = scfracw(ibad).*scale;
      scfraci(ibad) = scfraci(ibad).*scale;
   end
   cfrac1(ic62) = scfraci;
   cfrac2(ic62) = scfracw;
   cfrac12(ic62) = scfracw + scfraci - stcc;
   % WARNING: slightly negative values of cfrac12 possible
end
ibad = find(cfrac12 < 0);
cfrac12(ibad) = 0;

%%% end of function %%%
