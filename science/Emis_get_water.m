function [sea_nemis, sea_efreq, sea_emis]=Emis_get_water(loc, mode, kind, wstr, dia)
% function [sea_nemis, sea_efreq, sea_emis]=Emis_get_water(loc, mode, kind, wstr, dia)
%
% Return the sea emissivity for a series of geographycal locations.
% As this is a calculated result a valid result will be provided 
% as if the World were made of water.
%
% loc(N,2) : vector of (lat,lon)
% mode     : 'nearest'
%          : 'averaged'  (not coded!!) 
% kind     : Kind of emissivity function.
%            1 - cal_seaemis(satzen)   
%                    - used for the uniform_clear
%            2 - cal_seaemis2(satzen, wspeed) 
%                    - same as above except includes wind speed
%            3 - cal_seaemiswu(satzen, wspeed) 
%                    - this is based on what JPL/AIRS uses.
%            4 - cal_Tdep_seaemis(satzem, wspeed, Tskin) 
%                    - experimental; no not use.
% wstr     : structure containing all the necessary data for the emissivity.
% dia      : diameter (in Km) of the FoV - AIRS=13.5Km (default, optional)
%
% Breno Imbiriba - 2007.09.25


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Setup

if(nargin<4)
  error('Need at least 4 arguments.');
elseif(nargin==4)
  dia=13.5;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1a. Get nearest emissivity datapoint. 
if(strcmp(mode,'nearest'))

  bxlat=loc(:,1);
  bxlon=loc(:,2);

else
  error('averaged mode not coded yet!');
end


if(kind==1)
  [sea_nemis, sea_efreq, sea_emis]=cal_seaemis(wstr.satzen);
elseif(kind==2)
  [sea_nemis, sea_efreq, sea_emis]=cal_seaemis2(wstr.satzen,wstr.wspeed);
elseif(kind==3)
  [sea_nemis, sea_efreq, sea_emis]=cal_seaemiswu(wstr.satzen,wstr.wspeed);
elseif(kind==4)
  [sea_nemis, sea_efreq, sea_emis]=cal_Tdep_seaemis(wstr.satzen,wstr.wspeed,wstr.Tskin);
else
  fprintf( [ namethisfunc ' Error: kind=' kind ' but it must be 1,2,3 or 4.\n']);
  error();
end

end
   
