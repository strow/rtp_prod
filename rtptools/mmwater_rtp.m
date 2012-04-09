function [mm] = mmwater_rtp(head, prof);
%
% function [mm] = mmwater_rtp(head, prof);
%
% RTP utility program to calculate the equivalent total column of
% liquid water (in millimeters) from the sum of the profile layer
% water vapor amounts.  The profile must be a "layers" profile, the
% gases must include water, and the gas units must be molecules/cm^2.
% This revised version includes the adjustment for a fractional
% bottom layer.
%
% Input:
%    head = {structure} RTP "head" with fields: ptype, glist, & gunit
%    prof = {structure} RTP "prof" with fields: nlevs, gas_1
%
% Output:
%    mm = {1 x nprof} equivalent total column of liquid water (millimeters)
%

% Created: 7 February 2002, Scott Hannon
% Updated: 28 July 2003, Scott Hannon - bug fix: sum should be 1 to nlevs-1.
%          Add adjust for bottom fractional layer.
% Update: 2 Jun 2005, S.Hannon - bug fix for ptype=2 (nlay=nlevs not nlevs-1)
% Update: 05 May 2009, S.Hannon - partial re-write to search for spres
%    in plevs rather than trust the bottom layer is nlay. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Avagadro's number (molecules per mole)
navagadro=6.02214199E+23;

% Approximate mass of water per molecule (AMU)
mass=18.015;


% Check ptype
if (~isfield(head,'ptype'))
   error('head field ptype not found')
else
   if (head.ptype < 1)
      error('head field ptype must be a "layers" profile (ptype=1 or 2)')
   end
end


% Check glist
if (~isfield(head,'glist'))
   error('head field glist not found')
else
   iwat=find( head.glist == 1 );
   if (length(iwat) > 1)
      error('head field glist must contain only one entry for water (ID=1)')
   end
   if (length(iwat) == 0)
      error('head field glist does not contain an entry for water (ID=1)')
   end
end


% Check gunit
if (~isfield(head,'gunit'))
   error('head field gunit not found')
else
   ii=head.gunit( iwat );
   if (ii ~= 1)
      error('head field gunit must have code=1 (molecules/cm^2) for water')
   end
end


% Check nlevs
if (~isfield(prof,'nlevs'))
   error('prof field nlevs not found')
end


% Check spres
if (~isfield(prof,'spres'))
   error('prof field spres not found')
end


% Check plevs
if (~isfield(prof,'plevs'))
   error('prof field plevs not found')
end


% Conversion factor (equivalent mm of liquid water per molecules/cm^2)
% cfac = 1 (cm^3/gram) * ~18/Navadagro (grams/molecule) * 10 (mm/cm)
cfac=10*mass/navagadro;


% Check plevs are top-down
if (prof.plevs(2,1) < prof.plevs(1,1))
   error('code only works with top-down plevs')
end


% Check gas_1
if (isfield(prof,'gas_1'))
   [nlev,nprof]=size(prof.gas_1);
   mm=zeros(1,nprof);
else
   error('prof must contain field gas_1')
end


for ii=1:nprof
   indlev = 1:prof.nlevs(ii);
   mlev = min( find(prof.plevs(indlev,ii) > prof.spres(ii)) );
   if (length(mlev) == 0)
      mlev = prof.nlevs(ii);
   end
   if (head.ptype == 1)
      blay = mlev-1;
   else
      blay = mlev;
   end
   water=prof.gas_1(1:blay,ii);

   % Calc bottom (fractional) layer multiplier
   blmult=( prof.spres(ii)      - prof.plevs(mlev-1,ii) ) / ...
          ( prof.plevs(mlev,ii) - prof.plevs(mlev-1,ii) );
   water(blay)=water(blay)*blmult;

   mm(ii)=cfac*sum( water );
end

%%% end of file %%%
