function ht = p2h(pin)
%this function takes pressure in mb, and converts to height in m

load /asl/matlab/clouds/airsheights.dat
load /asl/matlab/clouds/airslevels.dat
%load airsheights.dat
%load airslevels.dat

h=airsheights;
p=airslevels;
for ii=1:100
  pavg(ii)=(p(ii+1)-p(ii))/log(p(ii+1)/p(ii));
  end
%plot(h,pavg)

ht=interp1(pavg,h,pin);

if ((isnan(ht)) | ht > 7.05e4)
  ht = 8.09e4;
  end
