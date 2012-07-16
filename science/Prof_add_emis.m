function [prof_out Qflag models ]=Prof_add_emis(prof_in, year, month, day, interp, mode, kind, only )
% function [prof_out Qflag models ]=Prof_add_emis(prof_in, year, month, day, interp, mode, kind, only )
%
% Add the Land emissivity to the corresponding land FoVs.
%
% prof_in : RTP profile containing the FoVs.
% year    : Calendar year of observation
% month   :          month
% day     :          day
%
%  ****** optinal arguments ******
%  (but if you use one, you must fill them all)
%
% interp  : Temporal interpolation (0, 1, 2)
%           0 - nearest month. (default)
%           1 - linear interpolation of 2 surrounding months
%           (not impl.) 2 - quadratic interpolation of 3 surrounding months
% mode    : Spacital smoothing (averaging)
%           'nearest' - get the nearest data pixel (default)
%           'averaged' - average inside of an AIRS FoVs (not coded yet)
% kind    : Kind of water emissivity function.
%            1 - cal_seaemis(satzen)   (default)
%                    - used for the uniform_clear
%            2 - cal_seaemis2(satzen, wspeed) 
%                    - same as above except includes wind speed
%            3 - cal_seaemiswu(satzen, wspeed) 
%                    - this is based on what JPL/AIRS uses.
%            4 - cal_Tdep_seaemis(satzem, wspeed, Tskin) 
%                    - experimental; no not use.
% only     : 'land' - change only land.
%          : 'sea'  - change only sea.
%          : 'all'  - chage all. (default)
%          : 'seaall' - change all as if it were Sea.
%
% OUTPUT:
% prof_out : is the same as prof_in, but with the adjusted emissivities.
% Qflag    : a quality indicator.
%
% Qflag = 0000  : Ok
%         0001  : Bad Land emiss
%         0010  : Over Land
%         0100  : Over Water  
%
% check for: Qflag==3
%
% models - string with the name of the emissivity models used.
%
%----------------------------------------------------------------------------
% Coastal areas:
%        The Wisconsin data (and the MODIS products used for it) 
% have no coastal data.  But, regardless, there are FoVs with fractional
% landfrac. We deal with this by adding the correcponding proportions 
% of land and sea emissivity.   
%
%----------------------------------------------------------------------------
% IRemis data files located at: /carrot/s1/imbiriba/SPECIALRTPFILES/iremis
%
% Breno Imbiriba - 2007.09.11

% Updated: 8 Aug 2011  Paul Schou - updated the dates to be 0 padded
%         18 Aug 2011  Paul Schou - added wrapTo180 around the rlon values
%          1 Sep 2011  Paul Schou - added nrho and rho calculations at the end of the file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 0. Setup

if(nargin==4)
  interp=0;
  mode='nearest';
  kind=1;
  only='all'
elseif(nargin~=8)
  error('You must provide 4 or 8 input arguments');
end 

% AIRS FOV diameter
dia=13.5;

%iremisdir='/carrot/s1/imbiriba/SPECIALRTPFILES/iremis';
%iremisdir=[ Sys_HOME() '/asl/iremis' ];
iremisdir='/asl/data/iremis/CIMSS/';
models='Land(Wisconsin:/asl/data/iremis/CIMSS/); ';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Find data file names:
  [iremis_files_ndate]=iremis_filedates();

  if(datenum(year,month,day)>=max(iremis_files_ndate) + 31)
    fprintf(['You requested year %d, but data base only goes till ' datestr(max(iremis_files_ndate)) '. Setting year to ' datestr(max(iremis_files_ndate),'yyyy') '.\n'],year);
    [year x x x x x]=datevec(max(iremis_files_ndate));
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.1 Compute the matlab integer date number
  ndate=datenum([ num2str(year) '.' num2str(month) '.' num2str(day) ],'yyyy.mm.dd');
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.2 Load the IREMIS file table (which is an index based on this matlab date number

  iremis_file_n=1:length(iremis_files_ndate);

  iclosest_date=interp1(iremis_files_ndate, iremis_file_n, ndate, 'linear','extrap');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.3 - We want to be able to perform a quadratic fitting, if needed.
  %       We will save three dates, and three coeficients, for the interpolation:

  % Do I want two ahead or two behind?
  %idates=[nearest(iclosest_date)-1 nearest(iclosest_date) nearest(iclosest_date)+1]; 
  idates=[round(iclosest_date)-1 round(iclosest_date) round(iclosest_date)+1]; 

  % if I got out of range, set it to invalid -0-
  ioutofrange=find(idates<1 | idates>max(iremis_file_n));

  idates(ioutofrange)=0;
  if(all(idates==0))
    warning('Date is beyond limits. Using nearest.');
    interp=0;
    idates=[0, interp1(iremis_files_ndate, iremis_file_n, ndate, 'nearest','extrap'), 0];
  end   
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.4 Compute the mixing coeficients:
  if(interp>1)
    error('Sorry but only can do interp 0 or 1 for now');
  elseif(interp==1)
  %if(iclosest_date-nearest(iclosest_date)>=0)
  if(iclosest_date-round(iclosest_date)>=0)
    if(idates(3)~=0)
      % .   . * .
      %      x y
      x=1-(iclosest_date-idates(2));
      y=1-(-iclosest_date+idates(3));
      lin_coef=[0 x y];
    else
      % .   .   0
      %     x *
      x=1;
      lin_coef=[0 x 0];
      interp=0;
     end
  else
    if(idates(1)~=0)
      % . * .   .
      %  x y 
      x=1-(iclosest_date-idates(1));
      y=1-(-iclosest_date+idates(2));
      lin_coef=[x y 0];
    else
      % 0 * .   .
      %     x
      x=1;
      lin_coef=[0 x 0];
      interp=0;
    end
  end
  else
    if(idates(2)~=0)
      lin_coef=[0 1 0];
    elseif(idates(3)~=0)
      lin_coef=[0 0 1];
    else 
      lin_coef=[1 0 0];
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.5 Load the required files:
  if(strcmp(only,'land') | strcmp(only,'all'))
    ineed=find(lin_coef~=0);
    for iload=1:numel(ineed);
      yyyy=datestr(iremis_files_ndate(idates(ineed(iload))),'yyyy');
      ddd=iremis_files_ndate(idates(ineed(iload)))-datenum(yyyy,'yyyy')+1;
      filedate=[yyyy num2str(ddd,'%03d')];
      filename=[iremisdir '/iremis_' filedate '.mat'];
      if(exist(filename,'file'))
	dat(iload)=load(filename);
      else
        disp(['Prof_add_emis: The emissivity file ' filename 'is missing! Will look for a file of another year...']);
        for itt1=[-1 1];
	  filedate=[num2str(str2num(yyyy)+itt1) num2str(ddd,'%03d')];
	  filename=[iremisdir '/iremis_' filedate '.mat'];
          if(~exist(filename))
            disp(['Attempt: file ' filename ' does not exist...']);
            filename='';
            continue;
          else
            disp(['Using file ' filename '.']);
            dat(iload)=load(filename);
            break  
          end
          % Find use an arbitrary existing file
          filedate='2006001';
	  filename=[iremisdir '/iremis_' filedate '.mat'];
          dat(iload)=load(filename);
        end
      end
      idxname=[iremisdir '/iremis_' filedate '_idx.mat'];
      idx(iload)=load(idxname);
    end
  end
  %ifovs=length(prof_in.rlat);

  loc(:,1)=prof_in.rlat; %(ifovs);
  loc(:,2)=wrapTo180(prof_in.rlon); %(ifovs);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Get Emissivity:

wstr.landfrac=prof_in.landfrac;
switch kind
  case 1 
    wstr.satzen=prof_in.satzen;
    models=[models 'Water(cal_seaemis:' which('cal_seaemis') ')'];
  case 2
    wstr.satzen=prof_in.satzen;
    wstr.wspeed=prof_in.wspeed;
    models=[models 'Water(cal_seaemis2:' which('cal_seaemis2') ')'];
  case 3 
    wstr.satzen=prof_in.satzen;
    wstr.wspeed=prof_in.wspeed;
    models=[models 'Water(cal_seaemiswu:' which('cal_seaemiswu') ')'];
  otherwise 
  error('Prof_add_emis: not ready for kind=4');
end

if(strcmp(only,'land') | strcmp(only,'all'))
  if(interp==0)
     [nemis efreq emis Qflag] = Emis_get_all(loc, dat(1).land, idx(1).index_table, mode, kind, wstr, dia);
  elseif(interp==1)
     [nemis efreq emis Qflag] = Emis_get_all(loc, dat(1).land, idx(1).index_table, mode, kind, wstr, dia);
     [nemis2 efreq2 emis2 Qflag2] = Emis_get_all(loc, dat(2).land, idx(2).index_table, mode, kind, wstr, dia);
     emis = emis.*x + emis2.*y;
  end
else
  [nemis efreq emis]=Emis_get_water(loc, 'nearest', kind, wstr);
  Qflag=4*ones(size(loc(:,1)));
end

  % 2.1 Copy only the desired portion of data:
  if(strcmp(only,'land'))
    ifovs=find(wstr.landfrac>.99);
  elseif(strcmp(only,'sea'))
    ifovs=find(wstr.landfrac<.01);
  elseif(strcmp(only,'all'))
    ifovs=[1:length(wstr.landfrac)];
  elseif(strcmp(only,'seaall'))
    ifovs=[1:length(wstr.landfrac)];
  else
    warning(['Prof_add_emis: argument `only`==' only '. It must be land, sea, all, or seaall. Setting to `all`.']);
    ifovs=[1:length(estr.landfrac)];
  end

prof_out=prof_in;

prof_out.nemis(1,ifovs)=nemis(1,ifovs);

prof_out.emis=NaN(max(nemis), length(ifovs));
prof_out.efreq=NaN(max(nemis), length(ifovs));

% Copy emissivity to the profile structure.
% To speed up processes, we look for equal nemis, and do it as a chunk.

nemis_s=unique(nemis);
for i=1:length(nemis_s)
  inemis=find(nemis(ifovs(:))==nemis_s(i));
  prof_out.efreq(1:nemis_s(i),ifovs(inemis))=efreq(1:nemis_s(i),ifovs(inemis));
  prof_out.emis(1:nemis_s(i),ifovs(inemis))=emis(1:nemis_s(i), ifovs(inemis));
end


prof_out.nrho= prof_out.nemis;
prof_out.rho = (1.0 - prof_out.emis)/pi;


%for ic=1:length(ifovs)
%  prof_out.efreq(1:nemis(ifovs(ic)),ifovs(ic))=efreq(1:nemis(ifovs(ic)),ifovs(ic));
%  prof_out.emis(1:nemis(ifovs(ic)) ,ifovs(ic))= emis(1:nemis(ifovs(ic)),ifovs(ic));
%end

end




