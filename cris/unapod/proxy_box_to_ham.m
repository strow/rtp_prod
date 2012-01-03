% Convert CrIS proxy data apodization from boxcar (ie unapodized) to Hamming
%

% Created: 12 April 2011, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[nchan,nobs] = size(prof.robs1);

% Band1
i1lo = 1307;
i1 = 1:713;
n1 = length(i1);
i1hi = 1308;
ind1lo = find(head.ichan == i1lo);
[junk, ind1, junk2] = intersect(head.ichan,i1);
v1 = head.vchan(ind1);
ind1hi = find(head.ichan == i1hi);
ind1x = [ind1lo, ind1, ind1hi];
clear i1lo i1hi ind1lo ind1hi ind1

% Band2
i2lo = 1311;
i2 = 714:1146;
n2 = length(i2);
i2hi = 1312;
ind2lo = find(head.ichan == i2lo);
[junk, ind2, junk2] = intersect(head.ichan,i2);
v2 = head.vchan(ind2);
ind2hi = find(head.ichan == i2hi);
ind2x = [ind2lo, ind2, ind2hi];
clear i2lo i2hi ind2lo ind2hi ind2

% Band3
i3lo = 1315;
i3 = 1147:1305;
n3 = length(i3);
i3hi = 1316;
ind3lo = find(head.ichan == i3lo);
[junk, ind3, junk2] = intersect(head.ichan,i3);
v3 = head.vchan(ind3);
ind3hi = find(head.ichan == i3hi);
ind3x = [ind3lo, ind3, ind3hi];
clear i3lo i3hi ind3lo ind3hi ind3 junk junk2

% Convert Boxcar to Hamming
[r1x] = box_to_ham(prof.robs1(ind1x,:));
[r2x] = box_to_ham(prof.robs1(ind2x,:));
[r3x] = box_to_ham(prof.robs1(ind3x,:));
clear ind1x ind2x ind3x

% Replace RTP Boxcar data with Hamming data
n = n1+n2+n3;
head.nchan = n;
head.ichan = [1:n]'; %'
head.vchan = [v1; v2; v3];
prof.robs1 = zeros(n,nobs);
prof.robs1(i1,:) = r1x(2:(n1+1),:);
prof.robs1(i2,:) = r2x(2:(n2+1),:);
prof.robs1(i3,:) = r3x(2:(n3+1),:);
clear v1 v2 v3 r1x r2x r3x

%%% end of program %%%
