function [head hattr prof pattr] = rtpadd_merra(head,hattr,prof,pattr)
% function [head hattr prof pattr] = rtpadd_merra(head,hattr,prof,pattr)


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Fetch MERRA Data 
  % Fields 	description	RTP field name
  % t  - air temperature  	ptemp
  % qv - specific humidity	gas_1
  % o3 - ozone mixing ratio	gas_3
  % ps - surface pressure		spres
  % ts - surface temperature	stemp
  % u2m - eastward wind at 2 m above the displacement height
  % v2m - northward wind at 2 m above the displacement height
  %
  % Data is given on 3hr files, except 'ts' which is hourly
  %


  % Assumptions:
  % 1. All pressure grids are the same for all 3D variables
  % 2. Invalid bottom of atmosphere values happens on all 3D variables


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Basic checks
  if(head.ptype~=0)
    disp('You have an RTP file that is a level file. All previous layer information will be removed');
    while head.ngas>0
      if(isfield(prof,['gas_' num2str(head.glist(1))]))
	prof=rmfield(prof,['gas_' num2str(head.glist(1))]);
	head.ngas  = head.ngas-1;
	head.glist = head.glist(2:end,1);
	head.gunit = head.gunit(2:end,1);
	head.ptype = 0;
      else
	warning(['Non existing field gas_' num2str(head.glist(1)) ' indicated by headers. Fixing']);
	head.ngas  = head.ngas-1;
	head.glist = head.glist(2:end,1);
	head.gunit = head.gunit(2:end,1);
	head.ptype = 0;
      end
    end
  end
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get the data times:
  mtimes = AirsDate(prof.rtime); % [mtimes]=days

  threehours = round((mtimes-mtimes(1))*8); % [threehours]=3-hour long units
  u3hours = unique(threehours); % unique list of the used 3-hour intervals
  n3hours = numel(u3hours);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Loop over 
  
  for i3hours=1:n3hours

    % Select Fovs and subset them
    ifov=find(threehours==u3hours(i3hours));
    nfovs = numel(ifov);
    tprof = ProfSubset2(prof,ifov);

    % Get required 3hr time slot
    reqtime = mtimes(1) + u3hours(i3hours)/8; % [day]=[day]+[3hr]/8


    %%%%%%%%%%%%%%%%%%%% 
    % Set profile variables

    % ptime
    tprof.ptime = ones(1,nfovs).*AirsDate(reqtime,-1); % [sec]
    tprof.plat = tprof.rlat;
    tprof.plon = tprof.rlon;

    ptemp=[]; pgas_1=[]; pgas_3=[]; pps=[]; pts=[];


    %%%%%%%%%%%%%%%%%%%% 
    % Interpolate 3D variables for each layer
    % ATTENTION: Fill value is not consistent. Some times it is 1e15 (as
    % advertised, but some times it is -9.99e8. Go figure!
 
    % t  - air temperature  	ptemp
    [dat_t plevs lats lons]= getdata_merra(reqtime, 't');

    nlevs=numel(plevs);

    dat_t(dat_t>1e14 | dat_t<-1)=NaN;
    for ilev=1:nlevs
      ptemp(ilev,:) = interp2(lats, lons, dat_t(:,:,nlevs-ilev+1), tprof.rlat, tprof.rlon,'nearest');
    end
    
    % qv - specific humidity	gas_1
    [dat_q plevs lats lons]= getdata_merra(reqtime, 'qv');
    dat_q(dat_q>1e14 | dat_t<-1)=NaN;
    for ilev=1:nlevs
      pgas_1(ilev,:) = interp2(lats, lons, dat_q(:,:,nlevs-ilev+1), tprof.rlat, tprof.rlon,'nearest');
    end
   
    % o3 - ozone mixing ratio	gas_3
    [dat_o3 plevs lats lons]= getdata_merra(reqtime, 'o3');
    dat_o3(dat_o3>1e14 | dat_t<-1)=NaN;
    for ilev=1:nlevs
      pgas_3(ilev,:) = interp2(lats, lons, dat_o3(:,:,nlevs-ilev+1), tprof.rlat, tprof.rlon,'nearest');
    end

    plevs=plevs(end:-1:1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    % Compute Valid Levels
   
    % For each profile, find the last valid level. 
    % 
    tprof.plevs = plevs*ones(1, nfovs);
    tprof.nlevs = nlevs.*zeros(1, nfovs);
    tprof.nlevs(1,:) = nlevs-sum(isnan(ptemp));

    tprof.ptemp = ptemp;
    tprof.gas_1 = pgas_1;
    tprof.gas_3 = pgas_3;


    % ps - surface pressure	spres
    [dat_ps tmpx lats lons]= getdata_merra(reqtime, 'ps'); % It is in Pa, convert to mbar -> /100
    dat_ps(dat_ps>1e14)=NaN;
    pps = interp2(lats,lons,dat_ps/100, tprof.rlat, tprof.rlon, 'nearest');
    
    % ts - surface temperature	stemp
    [dat_ts tmpx lats lons merra_str]= getdata_merra(reqtime, 'ts');
    dat_ts(dat_ts>1e14)=NaN;
    pts = interp2(lats,lons,dat_ts, tprof.rlat, tprof.rlon, 'nearest');
   
    tprof.spres = pps;
    tprof.stemp = pts;  

    
    % wind speed at 2m
    [dat_u2m tmpx lats lons]= getdata_merra(reqtime, 'u2m');
    [dat_v2m tmpx lats lons]= getdata_merra(reqtime, 'v2m');
    dat_w2m = sqrt(dat_u2m.^2 + dat_v2m.^2);
    w2m = interp2(lats,lons,dat_w2m,tprof.rlat, tprof.rlon,'nearest'); 

    tprof.wspeed = w2m;


    tprof_arr(i3hours) = tprof;

  end

  tprof = Prof_join_arr(tprof_arr);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Fix Header and Attributes


  % Set that the profile type is level.
  head.ptype=0;

  % Set the profile bit
  [ia ib ic]=pfields2bits(head.pfields);
  head.pfields = bits2pfields(1,ib,ic);

  % Add the new two gases - 1 and 3
  for ig=[1 3]
    if(~isfield(head,'glist'))
      head.glist=[];
      head.gunit=[];
      head.ngas=0;
    end
    ik=find(head.glist==ig); 
    if(numel(ik)==0)
      head.glist(end+1,1)=ig; % gad id
      head.gunit(end+1,1)=21; % gas unit (g/g) or something like that
      head.ngas=head.ngas+1;
    else
      head.gunit(ik)=21;
    end 
  end

  % Set pressures
  head.pmin = min(tprof.plevs(:));
  head.pmax = max(tprof.spres(:));

  hattr = set_attr(hattr,'profile',[merra_str ' Nearest']);

  prof=tprof;

end
