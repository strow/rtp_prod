function [nemis efreq emis Qflag]=Emis_get_all(loc, dat, idx, mode, kind, wstr, dia)
% function [nemis efreq emis Qflag]=Emis_get_all(loc, dat, idx, mode, kind, wstr, dia)
% 
% Obtains the Land and Sea surface emissivity.
% The Land is obtained using the Wisconsin emissivity table.
% The Sea  comes from Scott's series of routines (chosen by the kind parameter)
% In mixed regions we attempt to mix both emissivities, weighted by the land fraction. 
% 
% loc(N,2) : vector of (lat,lon)
% dat      : the land emissivity data table to be used (Wisconsin iremis).
% idx      : the corresponding index table (Wisconsin iremis).
% mode     : 'nearest'
%            'averaged'
% kind     : Kind of emissivity function.
%            1 - cal_seaemis(satzen)   
%                    - used for the uniform_clear
%            2 - cal_seaemis2(satzen, wspeed) 
%                    - same as above except includes wind speed
%            3 - cal_seaemiswu(satzen, wspeed) 
%                    - this is based on what JPL/AIRS uses.
%            4 - cal_Tdep_seaemis(satzem, wspeed, Tskin) 
%                    - experimental; no not use.
%
% wstr     : structure containing all the necessary data for the emissivity.
%            It must also contain the `landfrac' field. For example:
%
%            wstr.landfrac, wstr.satzen, wstr.wspeed
%
% dia      : diameter (in Km) of the FoV - AIRS=13.5Km (default, optional)
%
% The output is:
%
% nemis : number of emissivity points.
% efreq : wavenumber at each emissivity point at each location 
% emis  : emissivity at each emissivity point at each location 
% Qflag : A quality flag
%
% Qflag = 0000  : Ok
%         0001  : Bad Land emiss
%         0010  : Over Land
%         0100  : Over Water  
%
% check for: Qflag==3
%
% Breno Imbiriba.

nemis=0;
efreq=[];
emis=[];
Qflag=zeros(1,size(loc,1));

[lne lef lem]=Emis_get_land(loc, dat, idx);

[sne sef sem]=Emis_get_water(loc, 'nearest', kind, wstr);

iland=find(wstr.landfrac>.99);
isea=find(wstr.landfrac<.01);
imix=[1:length(wstr.landfrac)];
imix=setdiff(setdiff(imix, iland),isea);

% Set quality bits to basic configuration (land description)
Qflag(iland)=2;
Qflag(imix)=6;
Qflag(isea)=4;


% Sometimes the land emissivity may be bad. 
% In this case we will have a NaN.
% Similarly for the mixed regions (which frequently are bad).
ilbad=find(any(isnan(lem(:,iland)),1));
imbad=find(any(isnan(lem(:,imix)),1));

% Set the 'bad land' and 'bad mixed' quality flags.
Qflag(ilbad)=bitset(Qflag(ilbad),1);
Qflag(imbad)=bitset(Qflag(imbad),1);


% So, subtract thses bad point from the land/mix list and add them
% to the sea list.
isea =union(union(isea, iland(ilbad)),imix(imbad));
iland=setdiff(iland, iland(ilbad));
imix =setdiff(imix, imix(imbad));


nfovs=length(wstr.landfrac);
nemis_max=max(max(lne),max(sne));
nemis=zeros(1,nfovs);
efreq=zeros(nemis_max,nfovs);
emis =zeros(nemis_max,nfovs);

% Land
nemis(1,iland)=lne(1,iland);
for ie=1:length(iland)
  tfov=iland(ie);
  tlne=lne(tfov);
  efreq(1:tlne,tfov)=lef(1:tlne,tfov);
  emis (1:tlne,tfov)=lem(1:tlne,tfov);
  %Qflag(tfov)=bitor(Qflag(tfov),2);
end

% Sea
nemis(1,isea)=sne(1,isea);
for ie=1:length(isea)
  tfov=isea(ie);
  tsne=sne(tfov);
  efreq(1:tsne,tfov)=sef(1:tsne,tfov);
  emis (1:tsne,tfov)=sem(1:tsne,tfov);
  %Qflag(tfov)=bitor(Qflag(tfov),4);
end


%% replace the NaNs by zeros:
%inan=find(isnan(lem(:)));
%lem(inan)=0;

% Mixed regions:
% this piece is not going to be much efficient as I don't want to 
% expect 'nemis' to be the constant on land or sea.
for ie=1:length(imix)
  tfov=imix(ie);
  tsne=sne(tfov);
  tlne=lne(tfov);
  if(tlne<tsne)

    % Chosing the 'land' wavenamber grid:   
    tef =lef(1:tlne,tfov);
    tlem=lem(1:tlne,tfov);

    tsef=sef(1:tsne,tfov);
    tsem=sem(1:tsne,tfov);

    tsem=interp1(tsef, tsem, tef,'linear','extrap');

  else
    % Chosing the 'sea' wavenumber grid:
    tlef=lef(1:tlne,tfov);
    tlem=lem(1:tlne,tfov);
    tef =sef(1:tsne,tfov);
    tsem=sem(1:tsne,tfov);

    tlem=interp1(tlef, tlem, tef,'linear','extrap');
  end

  tne=min(tlne, tsne);
  nemis(1,tfov)=tne;
  efreq(1:tne,tfov)=tef;
  if(any(tlem==0)) 
    emis(1:tne,tfov) = tsem;
    %Qflag(tfov)=bitor(Qflag(tfov),1);
  else
    emis(1:tne,tfov) = tlem.*wstr.landfrac(tfov) + tsem.*(1-wstr.landfrac(tfov));
    %Qflag(tfov)=bitset(Qflag(tfov),1,0);
  end
end


end  
