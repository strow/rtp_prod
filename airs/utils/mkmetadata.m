function mkmetadata(JOB)

to_plot = 0;
product_path = '/data/s4pa/Aqua_AIRS_Level1/AIRIBQAP.005';

if exist('JOB','var')
  years=datevec(JOB(1));
  years=years(1);
  jdays=JOB(1)-datenum(years,1,1)+1;
end

if ~isempty(getenv('JOB'))
  JOB = datenum(getenv('JOB'),'yyyymmdd');
  years=datevec(JOB);
  years=years(1);
  jdays=JOB-datenum(years,1,1)+1;
end

for year = years
year;

%temp_file = tempname

d = struct;
load /asl/data/airs/airs_freq
for day = jdays
    day
    mdate = datenum(year,1,day);
    if ~exist(['/asl/data/airs/META_DATA/' num2str(year)],'dir'); mkdirs(['/asl/data/airs/META_DATA/' num2str(year)]); end
    output_file=['/asl/data/airs/META_DATA/' num2str(year) '/AIRS_' datestr(mdate,'yyyymmdd') '.mat'];
    %if exist(output_file,'file'); continue; end
    disp([' checking for output file: ' output_file])

    if exist(output_file,'file')
    %  [f fd]=findfiles(output_file);
    %  if ~isempty(whos('-file',output_file,'Time')) & ~isempty(whos('-file',output_file,'Latitude'))
    %    disp('date too new')
        continue
    %  end
    end
    
      date_path = ['/' num2str(year) '/' num2str(day,'%03d')];
      server = ['http://airscal' num2str(2-mod(year,2)) 'u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBQAP.005'];
%     try
%       ecs = ftp(['airscal' num2str(2-mod(year,2)) 'u.ecs.nasa.gov'])
%       cd(ecs,['/ftp' product_path date_path])
%       dirlist = dir(ecs,'*.hdf')
%       close(ecs)
%     catch
%       pause(1)
%       try
%         ecs = ftp(['airscal' num2str(2-mod(year,2)) 'u.ecs.nasa.gov'])
%         cd(ecs,['/ftp' product_path date_path])
%         dirlist = dir(ecs,'*.hdf')
%         close(ecs)
%       catch
%         continue
%       end
%     end
    
    %http://airscal1u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBRAD.005/2007/055/
    dirlist = {};
    try
        dirlist = getdata_opendap_ls(['http://airscal' num2str(2-mod(year,2)) ...
            'u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBQAP.005' date_path],[]);
    catch
      try
        dirlist = getdata_opendap_ls(['http://airscal' num2str(2-mod(year,2)) ...
          'u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBQAP.005' date_path],[]);
      catch
        disp('--failed')
      continue;
      end
    end

    if exist(output_file,'file') & ~isempty(whos('-file',output_file,'dirlist'))
      t = load(output_file,'dirlist');
      if isequal(t.dirlist,dirlist)
        continue
      end
    end

    d.dirlist = dirlist;
    start_time = now;
    tic
    clear AIRS
    d.solzen = ones(240,90,135,'single')*-9999;
    d.satzen = ones(240,90,135,'single')*-9999;
    d.scanang = ones(240,90,135,'single')*-9999;
    d.sun_glint_distance = ones(240,90,135,'single')*-9999;
    d.topog = ones(240,90,135,'single')*-9999;
    d.landFrac = ones(240,90,135,'single')*-9999;
    d.state = ones(240,90,135,'uint8')*255;
    d.CalChanSummary = ones(240,2378,1,'uint8')*255;
    d.CalScanSummary = ones(240,1,135,'uint8')*255;
    d.CalFlag = ones(240,2378,135,'uint8')*255;
    d.NeN = ones(240,2378,1,'single')*-9999;
    d.dust_flag = ones(240,90,135,'int8')*-128;
    d.dust_score= ones(240,90,135,'int16')*-9999;
    %d.dust_flag_LR = ones(240,90,135,'int16')*-9999;
    %d.num_dust_LR = ones(240,90,135,'int16')*-9999;
    d.spectral_clear_indicator = ones(240,90,135,'int8')*-128;
    d.Latitude = ones(240,90,135,'single')*-9999;
    d.Longitude = ones(240,90,135,'single')*-9999;
    if exist(output_file,'file') & ~isempty(whos('-file',output_file,'Latitude'))
      d=load(output_file);
    end
    d.Time = ones(240,90,135,'double')*-9999;

    for i = 1:length(dirlist)
        fname = [server '/' date_path '/' dirlist{i}];
        preurl = ['http://airscal' num2str(2-mod(year,2)) ...
            'u-ts1.ecs.nasa.gov/daac-bin/OTF/HTTP_services.cgi?SERVICE=HDF_SDS_BIN'];
        
        [fdir fbase] = fileparts(fname);
        used_time = now - start_time;
        if i > 1
            est_time = datestr(used_time / (i-1) * (length(dirlist) - i + 1),13);
        else;est_time = '';end
        if i > 1
            total_time = datestr(used_time / (i-1) * length(dirlist),13);
        else;total_time = '';end
        disp([fbase '  (' num2str(i) '/' num2str(length(dirlist)) ') ' est_time ' / ' total_time])
        
        gran = str2num(fbase(17:19));
        
        %disp(fname)
        if ~exist(output_file)
        [sa sz sgd t lf s ccs css] = getdata_opendap(fname,'scanang[0:1:134][0:1:89],solzen[0:1:134][0:1:89],sun_glint_distance[0:1:134][0:1:89],topog[0:1:134][0:1:89],landFrac[0:1:134][0:1:89],state[0:1:134][0:1:89],CalChanSummary[0:1:2377],CalScanSummary[0:1:134]');
        [satz cf n df ds sci lat lon] = getdata_opendap(fname,'satzen[0:1:134][0:1:89],CalFlag[0:1:134][0:1:2377],NeN[0:1:2377],dust_flag[0:1:134][0:1:89],dust_score[0:1:134][0:1:89],spectral_clear_indicator[0:1:134][0:1:89],Latitude[0:1:134][0:1:89],Longitude[0:1:134][0:1:89]');
        %[dfl nfl] = getdata_opendap(fname,'dust_flag_LR[0:1:134][0:1:89],num_dust_LR[0:1:134][0:1:89]');
        

        d.scanang(gran,:,:)=sa;
        d.satzen(gran,:,:)=satz;
        d.solzen(gran,:,:)=sz;
        d.sun_glint_distance(gran,:,:)=sgd;
        d.topog(gran,:,:)=t;
        d.landFrac(gran,:,:)=lf;
        d.state(gran,:,:)=s;
        d.CalChanSummary(gran,:,1)=ccs;
        d.CalScanSummary(gran,1,:)=css;
        d.CalFlag(gran,:,:)=cf;
        d.NeN(gran,:,1)=n;
        d.dust_flag(gran,:,:)=df;
        d.dust_score(gran,:,:)=ds;
        d.spectral_clear_indicator(gran,:,:)=sci;
        d.Latitude(gran,:,:)=lat;
        d.Longitude(gran,:,:)=lon;

        [cn, cstr] = data_to_calnum_l1b(mattime2tai(mdate),freq,n,double(ccs),squeeze(cf));
        d.CalNum(gran,:,:)=cn;
        d.cstr = cstr;

        end

	[time] = getdata_opendap(fname,'Time[0:1:134][0:1:89]');
        d.Time(gran,:,:)=time;

%        fh=fopen(temp_file,'rb');
        
%        fseek(fh,0,1);fsize=ftell(fh);
%        fseek(fh,0,-1);
        
%        tmp=fread(fh,2378*fsize/2558,'uint8');
%        CalFlag(gran,:,:)=reshape(tmp,2378,fsize/2558);
%        tmp=fread(fh,90*fsize/2558,'int16');
%        dust_flag(gran,:,:)=reshape(tmp,90,fsize/2558);
        
        %imagesc(double(squeeze(dust_flag(1,:,:))))
        %pause(0.2)
        
%        keyboard;
%        fclose(fh);
        %keyboard
        if(to_plot)
            load coast
            hold off
            scatter(Longitude,Latitude,10,dust_flag)
            orig_axis = axis;
            hold on
            plot(long,lat)
            axis(orig_axis)
        end
        %save([fbase '.mat'],'Latitude','Longitude','dust_flag','CalFlag');
    end % file loop
    
    toc
    disp([' saving output file: ' output_file])
    save(output_file,'-struct','d','-V7.3');
end

end

%if exist(temp_file,'file')
%  delete(temp_file)
%end
