
function geo = geonav_ugly_hack(scTime,eng);

%
% function geo = geonav_ugly_hack(scTime,eng);
%


% Extract ES FORs 
scTimeES = scTime(1:30,:);
[nFORs,nScans] = size(scTimeES);

% Compute datenumbers
scDnumES = scTimeES/1e3/24/60/60 + datenum(1958,1,1);

% Pull cross track scan angles out of Eng packet and convert to degrees.
ctsa = rad2deg(-eng.MappingParam.CommandedCrTrk.ES/1e6);


% Test if last TLINSET time is later than firt valid time on scTime
% Get latest TLINSET time
fh=fopen('/asl/data/cris/TLINSET','r');
cline=fscanf(fh, '%80c');
cline=char(Sys_convert(cline,'nl','list'));
yy=str2num(cline(end-1,19:20));
ddd=str2num(cline(end-1,21:23));
ffffffff=str2num(cline(end-1,24:32));
maxTLtime = datenum(yy+2000,1,ddd,0,0,0)+ffffffff;

minSCtime=datenum(1958,1,1,0,0,nanmin(scTime(:))/1000);

lok_date = maxTLtime > minSCtime;
if(~lok_date)
  disp(['minSCtime = ' datestr(minSCtime)]);
  disp(['maxTLtime = ' datestr(maxTLtime)]);
  error(['TLINSET file ends before requested data.']);
end

%---------------------------------------------------
% Loop through each FOR and use when to get the lat/lon
%---------------------------------------------------
forLat = scDnumES*NaN;
forLon = scDnumES*NaN;
for fi = 1:nFORs
  for fj = 1:nScans
    if isfinite(scTimeES(fi,fj))
      jnk = datestr(scDnumES(fi,fj),31);
      yymmdd_hhmmss = [jnk([3 4 6 7 9 10]) ' ' jnk([12 13 15 16 18 19])];
      PWD=pwd;
      cd('/strowdata1/shared/imbiriba/projects/Cris/AddGeo');
      eval_string = ['./where npp ' yymmdd_hhmmss ' ' num2str(ctsa(fi))];
      [status output] = unix(eval_string);
      fid = fopen('fort.6');
      [w,s] = fscanf(fid,'%c');
      fclose(fid);
      cd(PWD);
      if s ~= 0
        ind1 = findstr(w,'Viewed Ground Point:')+20;
        ind2 = findstr(w,'Universal Time and Longitude')-3;
        eval(['jnk=[' w(ind1:ind2) '];'])
        forLat(fi,fj) = jnk(1);
        forLon(fi,fj) = jnk(2);
      end
    end
  end
end

%----------------------------------------------------
% Now interpolate FOR (aka FOV5) lat/lons to the FOVs
%----------------------------------------------------

% FOV lat/lons, and times
fovTimeES = zeros(nFORs*3,nScans*3);
geo.fovLat = fovTimeES*NaN;
geo.fovLon = fovTimeES*NaN;

% Out of a [90 x nScans*3] FOV array, the FOV5 indices are:
iFov5 = (2:3:nFORs*3-1)';
jFov5 = (2:3:nScans*3-1)';

% Loop through FOV5 scan lines and interpolate to all 90 FOVs in each scan line
for i = 1:length(jFov5)
  jnd = jFov5(i);
  geo.fovLon(:,jnd) = interp1(iFov5,forLon(:,i),1:90,[],'extrap');
  geo.fovLat(:,jnd) = interp1(iFov5,forLat(:,i),1:90,[],'extrap');
  fovTimeES(:,jnd)  = interp1(iFov5,scTimeES(:,i),1:90,[],'extrap');
end
% now fill in the missed
for i = 1:90
  geo.fovLon(i,:) = interp1(jFov5,geo.fovLon(i,jFov5),1:nScans*3,[],'extrap');
  geo.fovLat(i,:) = interp1(jFov5,geo.fovLat(i,jFov5),1:nScans*3,[],'extrap');
  fovTimeES(i,:)  = interp1(jFov5,fovTimeES(i,jFov5),1:nScans*3,[],'extrap');
end


% Compute datenumbers
geo.fovDnumES = fovTimeES/1e3/24/60/60 + datenum(1958,1,1);
geo.forLat = forLat;
geo.forLon = forLon;
