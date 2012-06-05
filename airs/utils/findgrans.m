addpath ../rtp
airs_paths

%JOB=datenum(2007,2,24);
% JOB=datenum(2008,12,27)
load(['/strowdata1/s1/sergio/OMI_CALIPSO_AEROSOL_HEIGHT/MODIS_CALIPSO/modis_calipso_' datestr(JOB(1),'yyyymmdd') '.mat']);

airs_dir = ['/asl/data/rtprod_airs/raw_meta_data/' datestr(JOB(1),'yyyy') '/' num2str(jday(JOB(1)),'%03d')];
for gran = 1:240
  disp(gran)
  airs_file = [airs_dir '/meta_cdtssll.' num2str(gran,'%03d')];
  [cf df top sa sgd lat lon time] = getdata_opendap_file(airs_file);
  for j = 1:length(mclat)
    d = distance(lat,lon,mclat(j),mclon(j));
    if min(d(:)) < 1 & diff(lat(1,[1 135])) > 0
      [gran min(d(:))]
      %figure(1); plot(lon,lat,'.',mclon,mclat,'o')
      %figure(2);plot(sgd)
      %figure(3);plot((lat(1,135)-lat(1,1)),'o')
      %pause
      save(['/home/schou/MODIS_CALIPSO/' datestr(JOB(1),'yyyymmdd') '-' num2str(gran,'%03d')],'gran','time','lat','lon')
      break
    end
  end
  
end
