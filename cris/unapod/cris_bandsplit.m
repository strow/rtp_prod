function [r1, r2, r3] = cris_bandsplit(id, rad);

% function [r1, r2, r3] = cris_bandsplit(id, rad);
%
% Split a CrIS radiance array into separate arrays for each of
% the three CrIS bands, with 10 fake channels appended to each
% end of each band. Returns non-empty output only for those
% bands for which complete input data was supplied.
%
% Input:
%   id   -  [nchan x 1] channel IDs {1 to 1305 or 1329 for UMBC "g4" RTA}
%   rad  -  [nchan x nobs] radiance {mW/cm^2 per cm^-1 per steradian}
%
% Output:
%    r1  -  [713+20=733 x nobs] or [] band1 radiance
%    r2  -  [433+20=453 x nobs] or [] band2 radiance
%    r3  -  [159+20=179 x nobs] or [] band3 radiance
%

% Created: 23 July 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fake matched channels

iduse_g4m6=[...
     70     71     70     71     69     71 ...
   1310    705    679    679    708    707;
    725    725   1315    731    731    731 ...
   1125   1319   1128   1128   1130   1122;
   1154   1148   1323   1323   1323   1324 ...
   1299   1304   1327   1327   1327   1327]';%'
rmult_g4m6=[...
 1.1156 1.1157 1.1032 1.1077 1.1020 1.1135 ...
 0.9910 0.9734 0.9266 0.9234 0.9763 0.9714;
 1.1057 1.0976 1.0107 1.1185 1.1163 1.1155 ...
 0.8148 0.9593 0.8372 0.8224 0.8850 0.8101;
 1.1507 1.0931 1.0118 0.9441 1.0259 1.0928 ...
 0.8947 0.9859 0.9686 0.9257 0.9014 0.8883]';%'

iduse_m10=[...
     70     71     70     71     69     71      2      2     21     22 ...
    710    710    710    710    710    705    679    679    708    707;
    725    725    729    731    731    731    734    719    734    719 ...
   1146   1115   1126   1126   1125   1116   1128   1128   1130   1122;
   1154   1148   1150   1150   1150   1147   1150   1150   1149   1149 ...
   1303   1302   1302   1301   1299   1304   1302   1303   1303   1303]';%'
rmult_m10=[...
 1.1156 1.1157 1.1032 1.1077 1.1020 1.1135 0.9989 1.0098 1.0510 1.0131 ...
 0.9968 0.9965 0.9956 0.9920 0.9878 0.9734 0.9266 0.9234 0.9763 0.9714;
 1.1057 1.0976 1.1495 1.1185 1.1163 1.1155 1.1425 1.0569 1.1303 1.0494 ...
 1.0177 0.8250 0.9085 0.9254 0.8148 0.8080 0.8372 0.8224 0.8850 0.8101;
 1.1507 1.0931 1.1516 1.0753 1.1681 1.1348 1.1842 1.1383 1.0907 1.0609 ...
 0.9547 0.9195 0.9202 0.9178 0.8947 0.9859 0.8906 0.8768 0.8537 0.8414]';%'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
d = size(id);
if (length(d)~= 2)
   error('Unexpected number of dimensions for id')
end
if (min(d) ~= 1)
   error('id must be a 1D array')
end
nchan = max(d);
%
d = size(rad);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rad')
end
if (d(1) ~= nchan)
   error('Lead dimension of rad must match length of id')
end
nobs = d(2);
%
if (min(id) < 1 | max(id) > 1329)
  error('id out of expected 1-1329 range')
end


% Pull out data for band1
%
% Look for required channels
[idfound, ind, indreq] = intersect(id,1:713);
if (length(idfound) == 713)
   r1 = zeros(733,nobs);
   ind(indreq) = ind; % Re-order to 1:713
   r1(11:723,:) = rad(ind,:);
   %
   % Look for g4 channels
   idg4 = 1306:1313; % g4 channels in desired order
   [idfound, indg, indgreq] = intersect(id,idg4);
   if (length(idfound) == 8)
      % Plug in data for found g4 channels
      indg(indgreq) = indg; % Re-order to idg4
      r1(7:10,:) = rad(indg(1:4),:);
      r1(724:727,:) = rad(indg(5:8),:);
      %
      % Compute and then plug in fake matched channels
      iduse = iduse_g4m6(:,1);
      rmult = rmult_g4m6(:,1);
      idusex = iduse;
      idx = find(iduse >= 1306 & iduse <= 1309);
      idusex(idx) = iduse(idx) + 7 - 1306;
      idx = find(iduse >= 1 & iduse <= 713);
      idusex(idx) = iduse(idx) + 10;
      idx = find(iduse >= 1310 & iduse <= 1313);
      idusex(idx) = iduse(idx) + 724 - 1310;
      r1(1:6,:) = r1(idusex(1:6),:).*(rmult(1:6)*ones(1,nobs));
      r1(728:733,:) = r1(idusex(7:12),:).*(rmult(7:12)*ones(1,nobs));
   else
      % Compute and then plug in fake matched channels
      idusex = iduse_m10(:,1) + 10;
      rmult = rmult_m10(:,1);
      r1(1:10,:) = r1(idusex(1:10),:).*(rmult(1:10)*ones(1,nobs));
      r1(724:733,:) = r1(idusex(11:20),:).*(rmult(11:20)*ones(1,nobs));
   end
else
   r1 = [];
end


% Pull out data for band2
%
% Look for required channels
[idfound, ind, indreq] = intersect(id,714:1146);
if (length(idfound) == 433)
   r2 = zeros(453,nobs);
   ind(indreq) = ind; % Re-order to 714:1146
   r2(11:443,:) = rad(ind,:);
   %
   % Look for g4 channels
   idg4 = 1314:1321; % g4 channels in desired order
   [idfound, indg, indgreq] = intersect(id,idg4);
   if (length(idfound) == 8)
      % Plug in data for found g4 channels
      indg(indgreq) = indg; % Re-order to idg4
      r2(7:10,:) = rad(indg(1:4),:);
      r2(444:447,:) = rad(indg(5:8),:);
      %
      % Compute and then plug in fake matched channels
      iduse = iduse_g4m6(:,2);
      rmult = rmult_g4m6(:,2);
      idusex = iduse;
      idx = find(iduse >= 1314 & iduse <= 1317);
      idusex(idx) = iduse(idx) + 7 - 1314;
      idx = find(iduse >= 714 & iduse <= 1146);
      idusex(idx) = iduse(idx) + 10 - 713;
      idx = find(iduse >= 1318 & iduse <= 1321);
      idusex(idx) = iduse(idx) + 444 - 1318;
      r2(1:6,:) = r2(idusex(1:6),:).*(rmult(1:6)*ones(1,nobs));
      r2(448:453,:) = r2(idusex(7:12),:).*(rmult(7:12)*ones(1,nobs));
   else
      % Compute and then plug in fake matched channels
      idusex = iduse_m10(:,2) + 10;
      rmult = rmult_m10(:,2);
      r2(1:10,:) = r2(idusex(1:10),:).*(rmult(1:10)*ones(1,nobs));
      r2(444:453,:) = r2(idusex(11:20),:).*(rmult(11:20)*ones(1,nobs));
   end
else
   r2 = [];
end


% Pull out data for band3
%
% Look for required channels
[idfound, ind, indreq] = intersect(id,1147:1305);
if (length(idfound) == 159)
   r3 = zeros(179,nobs);
   ind(indreq) = ind; % Re-order to 1:159
   r3(11:169,:) = rad(ind,:);
   %
   % Look for g4 channels
   idg4 = 1322:1329; % g4 channels in desired order
   [idfound, indg, indgreq] = intersect(id,idg4);
   if (length(idfound) == 8)
      % Plug in data for found g4 channels
      indg(indgreq) = indg; % Re-order to idg4
      r3(7:10,:) = rad(indg(1:4),:);
      r3(170:173,:) = rad(indg(5:8),:);
      %
      % Compute and then plug in fake matched channels
      iduse = iduse_g4m6(:,3);
      rmult = rmult_g4m6(:,3);
      idusex = iduse;
      idx = find(iduse >= 1322 & iduse <= 1325);
      idusex(idx) = iduse(idx) + 7 - 1322;
      idx = find(iduse >= 1147 & iduse <= 1305);
      idusex(idx) = iduse(idx) + 10 - 1146;
      idx = find(iduse >= 1326 & iduse <= 1329);
      idusex(idx) = iduse(idx) + 170 - 1326;
      r3(1:6,:) = r3(idusex(1:6),:).*(rmult(1:6)*ones(1,nobs));
      r3(174:179,:) = r3(idusex(7:12),:).*(rmult(7:12)*ones(1,nobs));
   else
      % Compute and then plug in fake matched channels
      idusex = iduse_m10(:,3) + 10;
      rmult = rmult_m10(:,3);
      r3(1:10,:) = r3(idusex(1:10),:).*(rmult(1:10)*ones(1,nobs));
      r3(170:179,:) = r3(idusex(11:20),:).*(rmult(11:20)*ones(1,nobs));
   end
else
   r3 = [];
end

%%% end of function %%%
