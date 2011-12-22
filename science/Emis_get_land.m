function [land_nemis, land_efreq, land_emis]=Emis_get_land(loc, dat, idx, mode, dia)
% function [land_nemis, land_efreq, land_emis]=emis_get_land(loc, dat, idx, dia)
% 
% Return the emissivity for the series of geographycal locations 
% given by loc (vector)
%
% loc(N,2) : vector of lat/lon. 
% dat      : the land emissivity data table to be used (Wisconsin iremis).
% idx      : the corresponding index table (Wisconsin iremis).
% mode     : 'nearest'
%            'averaged'
% dia      : diameter (in Km) of the FoV - AIRS=13.5Km  (default, optional)
%
% Returns 
% land_nemis(N)   : number of emissivity frequency points in each gridpoint.
% land_efreq(M,N) : wavenumbers used in each gridpoint 
%                   (valid entries match the nemis field above)
% land_emis(M,N)  : actuall emissivity coeficient in each wavenumber 
%                   in each gridpoint.
%                   NaNs are returned if there is no data present!
%
% Breno Imbiriba - 2007.09.14

% Update:  18 Aug 2011 - Added a search function to look for scale_factor in emis_attr

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Setup
if(nargin<3)
  error('Needs at least 3 arguments.');
elseif(nargin==3)
  mode='nearest';
  dia=13.5;
elseif(nargin==4)
  dia=13.5; 
end

%if(nargin==6)
%  if(isfield(wstr,'landfrac'))
%    if(length(wstr.landfrac)~=length(loc(:,1)))
%      error('wstr.landfrac must have the same length as loc.');
%    end
%  else
%    warning('No wstr.landfrac !');
%  end
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1a. Get nearest emissivity datapoint. 
if(strcmp(mode,'nearest'))

  bxlat=loc(:,1);
  bxlon=loc(:,2);


% 1b. Make an average of all emissivity datapoints that fit on a 
%     FoV sized square. 
elseif(strcmp(mode,'averaged')) 

% 1b.1 Compute the angular diameter. (usually 6.068711e-2 rad)

  R_earth=6372795; %in meter
  dia_rd = ((dia*1000)/R_earth)/2*180/pi;

% 1b.2 Over the North Pole, set a angular square. 
  NPlat=90-dia_rd; 
  NPlon=[0 90 180 270];

% 1b.3 Perform a rotation from N pole to the desired loc.
  trans(:,1)=90-loc(:,1);
  trans(:,2)=loc(:,2);
  nloc=size(trans,1);

  NPlon2=kron(NPlon,ones(nloc,1));
  Rlat=kron(ones(1,4),trans(:,1));
  Rlon=kron(ones(1,4),trans(:,2));

  [bxlat bxlon]=MathSphericalRotation(NPlat, NPlon2, Rlat,Rlon);

% This will give us the same spacial region 
% but expressed in the angular coordinates.

else
  error('Invalid mode entry');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Transform from lat/lon to ilat/ilon (2D grid).

%ibxlat = 3600-nearest((bxlat+90 )*20+.5)+1;
%ibxlon = nearest((bxlon+180)*20+.5);
ibxlat = 3600-round((bxlat+90 )*20+.5)+1;
ibxlon = round((bxlon+180)*20+.5);

% Fix the limitting cases:
ilatmax=find(ibxlat(:)==0); 
ibxlat(ilatmax)=1;
ilonmax=find(ibxlon(:)==7201);
ibxlon(ilonmax)=7200;

% 2.1 Get linear index.
ibxidx = ibxlat + (ibxlon-1)*3600;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Extract the emmisivity: WISCONSIN TABLE
%
%
% emis_1(iloc1,iloc2,nemis)
%                             If using nearest, iloc2=1:1
%                                          else iloc2=1:4. 
%                             loc1 matches loc.

i_scalefactor = find(strcmp(arrayfun(@(x) x{1}{1},dat.wn_atr,'UniformOutput',0),'scale_factor'));
efreq = dat.wavenumber.*dat.wn_atr{i_scalefactor}{2};
nemis = length(efreq);

offset=dat.offset;

% order emissivity in acending order:
[efreq ii]=sort(efreq);

if(numel(dat.emis)<offset*(nemis-1)+max(idx(:)) | numel(idx(:))<max(ibxidx(:)))
  errstr=sprintf('Error: numel(dat.emis)=%d, offset=%d, nemis=%d, max(idx(:))=%d, numel(idx(:))=%d, max(ibxidx(:))=%d\n', numel(dat.emis), offset, nemis, max(idx(:)), numel(idx(:)), max(ibxidx(:)));
  error(errstr);
end

for i=1:nemis
  emis_1(:,:,ii(i))=dat.emis(offset*(i-1)+idx(ibxidx));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Multiply by the scale factor:
i_scalefactor = find(strcmp(arrayfun(@(x) x{1}{1},dat.emis_atr,'UniformOutput',0),'scale_factor'));
emis_2=double(emis_1).*dat.emis_atr{i_scalefactor}{2};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Average the FoVs:
%   
% I want to ignore FoVs that have zero emissivity data.
ize=find(emis_2(:)==0);
emis_2(ize)=NaN;
land_emis=permute(nanmean(emis_2,2),[1 3 2]);
ize=find(isnan(land_emis(:)));
%land_emis(ize)=0;
land_emis=land_emis';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Set up output structures:

nfovs = size(land_emis,2);
land_nemis = zeros(1,nfovs);
land_nemis(:) = nemis;

land_efreq=zeros(nemis,nfovs);
for i=1:nfovs
  land_efreq(:,i) = efreq(:);
end

end
