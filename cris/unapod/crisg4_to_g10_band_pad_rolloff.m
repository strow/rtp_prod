function [r1, r2, r3] = crisg4_to_g10_band_pad_rolloff(id, rad);

% function [r1, r2, r3] = crisg4_to_g10_band_pad_rolloff(id, rad);
%
% Split CrIS "g4" Hamming radiance spectra into bands and pad the
% channels to g10 using buddy channels, and then apply rolloff.
% The output radiance extends from 0 wavenumbers up to a few
% wavenumbers (10 channels) past the true upper band edge. 
% 
% Input:
%    id   - [1329 x 1] CrIS g4 channel IDs 
%    rad  - [1329 x nobs] Hamming radiance
%
% Output:
%    r1/r2/r3 - [1763/1411/1031 x nobs] padded and rolled off radiance
%

% Created: 07 July 2010, Scott Hannon
% Update: 09 Aug 2011, S.Hannon - partial rewrite to create "buddy" version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% "g10" buddy channels for padding the three bands.  Some of the "g10"
% channels are in "g4" channel set, and those buddys are not used except
% to compute an offset = mean(sarta_g4 - buddy_g4) applied to the non-g4
% buddys that are used.  Note some of the buddy channel pairs belong
% to different bands (eg band1 guard channel 1322 uses real buddy channel
% 714 from band2).
%
%    idg10  freq     idrep  BTbias
%    ----  --------  ----  ------
bc =[1306   643.750    70  -0.136 
     1307   644.375    71  -0.221 
     1308   645.000    67   0.094 
     1309   645.625    71   0.025 
     1310   646.250    69   0.102 
     1311   646.875    65   0.252 
     1312   647.500    63  -0.222 
     1313   648.125    58  -0.363 
     1314   648.750    33  -0.605 
     1315   649.375    28   0.216 
     1316  1095.625   710  -0.089 
     1317  1096.250   710  -0.098 
     1318  1096.875   710  -0.136 
     1319  1097.500   710  -0.056 
     1320  1098.125   710  -0.005 
     1321  1098.750   699   0.026 
     1322  1099.375   714  -0.416 
     1323  1100.000   714  -0.352 
     1324  1100.625   708   0.040 
     1325  1101.250   707   0.066
     1326  1197.500   722  -0.191 
     1327  1198.750   722   0.004 
     1328  1200.000   522   0.042 
     1329  1201.250   527  -0.033 
     1330  1202.500   530   0.002 
     1331  1203.750   511   0.025 
     1332  1205.000   531  -0.003 
     1333  1206.250   515   0.013 
     1334  1207.500   526   0.030 
     1335  1208.750   525  -0.032 
     1336  1751.250   969  -0.041 
     1337  1752.500   863  -0.479 
     1338  1753.750  1128  -0.198 
     1339  1755.000  1127  -0.087 
     1340  1756.250   894  -0.314 
     1341  1757.500   863  -0.425 
     1342  1758.750   892  -0.051 
     1343  1760.000   897   0.167 
     1344  1761.250   914   0.046 
     1345  1762.500   914  -0.185
     1346  2130.000  1154  -0.068 
     1347  2132.500  1148   0.008 
     1348  2135.000  1150  -0.344 
     1349  2137.500  1156   0.151 
     1350  2140.000  1149   0.044 
     1351  2142.500  1148  -1.002 
     1352  2145.000  1147  -0.086 
     1353  2147.500  1149  -0.251 
     1354  2150.000  1147  -0.226 
     1355  2152.500  1147   0.102 
     1356  2552.500  1305  -0.087 
     1357  2555.000  1305  -0.192 
     1358  2557.500  1302   0.060 
     1359  2560.000  1301  -0.382 
     1360  2562.500  1299  -0.615 
     1361  2565.000  1301  -0.686 
     1362  2567.500  1301  -0.063 
     1363  2570.000  1305  -0.140 
     1364  2572.500  1305   0.076 
     1365  2575.000  1305   0.074];

% CrIS g4 band frequencies and channel IDs
f1 = ( 647.5:0.625:1097.5)'; %'
f2 = (1205.0:1.250:1755.0)'; %'
f3 = (2145.0: 2.50:2560.0)'; %'
fg4 = [f1; f2; f3];
id1g4 = [1306:1309,    1:713,  1310:1313]'; %'
id2g4 = [1314:1317,  714:1146, 1318:1321]'; %'
id3g4 = [1322:1325, 1147:1305, 1326:1329]'; %'
idg4 = [id1g4; id2g4; id3g4];
idg4_guard = 1306:1329;

% CrIS g4 guard channel IDs as g10 IDs
idx_guard = [1312:1319, 1332:1339, 1352:1359];

% Number of guard channels and non-guard buddy channels at each
% end of each band
nguard = 4;
nbuddy = 10;
nbuddyonly = nbuddy - nguard;

% Expected number of channels for each of the three CrIS bands (including
% nguard=4 guard channels at each end)
nbin_all = [713+8, 433+8, 159+8];
%
% Corresponding number of output channels (for nguard=4 and nbuddyonly=6);
% nbout = max(f)/df + 1 + nbuddyonly
nbout_all = [1763, 1411, 1031];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 2)
   error('unexpected number of input arguments')
end
%
d = size(id);
if (length(d) ~=2)
   error('Unexpected number of dimensions for id')
end
nchan = length(id);
if (nchan ~= length(fg4))
   error('unexpected number of channels');
end
%
d = size(rad);
if (length(d) ~=2)
   error('Unexpected number of dimensions for rad')
end
nobs  = d(2);
if (d(1) ~= 1329)
   errror('leading dimension of rad must match length of id')
end


% Buddy channel data
idbc = bc(:,1);
fbc  = bc(:,2);
idrep= bc(:,3);
bias = bc(:,4);


% Compute buddy channel BT
[junk, ind] = ismember(idrep, id);
ind = ind( find(ind > 0) );
if (length(ind) < length(idrep))
   error('did not find all required idrep channels in id')
end
r = rad(ind,:);
ibad = find(r < 1E-6);
r(ibad) = 1E-6;
[junk, ind] = ismember(idrep, idg4);
f = fg4(ind);
btbc = radtot(f, r) - bias*ones(1,nobs);
% Subset for g4 guard channels
[junk, ind] = ismember(idx_guard, idbc);
btbcg = btbc(ind,:);


% Compute g4 guard channel BT
[junk, ind] = ismember(idg4_guard, idg4);
f = fg4(ind);
[junk, ind] = ismember(idg4_guard, id);
r = rad(ind,:);
ibad = find(r < 1E-7);
r(ibad) = 1E-7;
btg = radtot(f, r);
% Replace any bad guard BT with buddy value
if (length(ibad) > 0)
   btg(ibad) = btbcg(ibad);
   rx = ttorad(f,btg);
   r(ibad) = rx(ibad);
   rad(ind,:) = r;
end
clear f r rx ibad


% Loop over the bands
for bnum = 1:3
   bstr = sprintf('%1d', bnum);
   nbin = nbin_all(bnum);
   nbout = nbout_all(bnum);

   % Index offsets for current band in buddy and guard BT matrices
   ioffsetb = round( (bnum-1)*nbuddy*2 ); % exact integer
   ioffsetg = round( (bnum-1)*nguard*2 ); % exact integer

   % Adjust lo edge buddy BT to match guard BT
   ind = ioffsetg + (1:nguard);
   dbt = mean( btg(ind,:)-btbcg(ind,:), 1);
   ind = ioffsetb + (1:nbuddy);
   btbc(ind,:) = btbc(ind,:) + ones(nbuddy,1)*dbt;

   % Adjust hi edge buddy BT to match guard BT
   ind = ioffsetg + nguard + (1:nguard);
   dbt = mean( btg(ind,:)-btbcg(ind,:), 1);
   ind = ioffsetb + nbuddy + (1:nbuddy);
   btbc(ind,:) = btbc(ind,:) + ones(nbuddy,1)*dbt;

   % Convert adjusted buddy BT to radiance
   ind = ioffsetb + (1:(2*nbuddy));
   rb = ttorad(fbc(ind), btbc(ind,:));

   % Declare output
   eval(['r' bstr '= zeros(nbout,nobs);']);

   % Indices of current band in id
   eval(['[junk, indg4] = ismember(id' bstr 'g4, id);']);

   % Copy input radiance to output array
   ilos = round(nbout - 2*nbuddyonly - nbin + 1); % exact integer
   iloe = ilos + nbuddyonly - 1;
   ihis = nbout - nbuddyonly + 1;
   ihie = nbout;
   ind = (iloe+1):(ihis-1);
   eval(['r' bstr '(ind,:) = rad(indg4,:);']);

   % Plug in lo edge buddy radiance
   ind = ilos:iloe;
   indb = (1:nbuddyonly);
   eval(['r' bstr '(ind,:) = rb(indb,:);']);

   % Plug in hi edge buddy radiance
   ind = ihis:ihie;
   indb = ((nbuddy + nguard + 1):(2*nbuddy));
   eval(['r' bstr '(ind,:) = rb(indb,:);']);


   % Apply rolloff
   nro = nbuddyonly + 2;
   irev = nro:-1:1;
   romult = ( 1 + cos(pi + pi*(0:(nro-1))/nro) )/2;
   romult = romult(:); % [nro x 1]
   ind = ilos:(ilos+nro-1);
   eval(['r' bstr '(ind,:)=r' bstr '(ind,:).*(romult*ones(1,nobs));']);
   ind = (ihie-nro+1):ihie;
   eval(['r' bstr '(ind,:)=r' bstr '(ind,:).*(romult(irev)*ones(1,nobs));']);


%%% uncomment for testing
%ix1 = ilos:ihie;
%ix2 = (ilos+nbuddyonly):(ihie - nbuddyonly);
%eval(['rx1=mean(r' bstr '(ix1,:), 2);']);
%rx2 = mean(rad(indg4,:), 2);
%plot(ix1,rx1,'b.-', ix2,rx2,'ro-'),grid,title(bstr)
%pause
%%%

end % end of loop over bands

%%% end of function %%%
