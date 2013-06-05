% Function to create rtp files for center track FOVs
%
% Written by Paul Schou  (Nov 2010)
%
% Updated:  11 Mar 2011 added data to calnum
%

airs_paths

mdate = JOB(1);

rtplist = findfiles(['/asl/data/rtprod_airs/' datestr(mdate,'yyyy/mm/dd') '/AIRS_L1B_CTR_' datestr(mdate,'yyyymmdd') '*.rtp']);
%if length(rtplist) > 16
%  disp(['  Over 16 files found, skipping day ' datestr(mdate)])
%  continue
%end

hattr={ {'header' 'fov' ['OPeNDAP AIRIBRAD center track ' datestr(mdate,'yyyy-mm-dd')]} };
hattr=set_attr(hattr,'pltfid','Aqua');
hattr=set_attr(hattr,'instid','AIRS');

pattr={ {'profiles' 'rtime' 'Seconds since 1 Jan 1993'}, ...
        {'profiles' 'udef(1,:)' 'Satellite Latitude {sat_lat}'}, ...
        {'profiles' 'udef(2,:)' 'Satellite Longitude {sat_lon}'}, ...
        {'profiles' 'udef(3,:)' 'NadirTAI - rtime {nadirTAI}'}, ...
        {'profiles' 'udef(4,:)' 'Equator crossing time - rtime {eq_x_tai}'} };

head = load('airs_vchan.mat','vchan');
head.pfields = 4;
head.nchan = length(head.vchan);
head.ichan = (1:head.nchan)';
head.ptype = 0;
head.ngas = 0;
head.instid = 800;
head.pltfid = -9999;
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

clear prof_all

[year month day] = datevec(mdate);
jday = floor(mdate - datenum(year,1,1))+1;
%http://airscal2u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBRAD.005/2010/121/AIRS.2010.05.01.001.L1B.AIRS_Rad.v5.0.0.0.G10123093206.hdf.rdf
date_path = [num2str(year) '/' num2str(jday,'%03d') '/'];
url = ['http://airscal' num2str(2-mod(year,2)) ...
            'u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBRAD.005/' date_path];


    dirlist = {};
    try
        dirlist = getdata_opendap_ls(url);
    catch
        pause(5 + rand(1)*30)
        dirlist = getdata_opendap_ls(url);
    end


    for k = 1:length(dirlist)
        fname = {dirlist{k}};
        disp([fname{1}])
        bn=basename(fname{1});
        gran = str2num(bn(17:19));
        rtpname = ['/asl/data/rtprod_airs/' datestr(mdate,'yyyy/mm/dd') '/airs_ctr.' datestr(mdate,'yyyy.mm.dd') '.' num2str(fix((gran-1)/10),'%02d') '.rtp'];
        if exist(rtpname,'file')
          disp('  skipping')
          continue
        end
        if k < length(dirlist)
          bn=basename(dirlist{k+1});
          next_gran = str2num(bn(17:19));
        else
          next_gran = inf;
        end

        vars = 'radiances[0:1:134][44:1:45][0:1:2377],scanang[0:1:134][44:1:45],satheight[0:1:134],nadirTAI[0:1:134],sat_lat[0:1:134],sat_lon[0:1:134],satzen[0:1:134][44:1:45],satazi[0:1:134][44:1:45],solzen[0:1:134][44:1:45],solazi[0:1:134][44:1:45],sun_glint_distance[0:1:134][44:1:45],topog[0:1:134][44:1:45],landFrac[0:1:134][44:1:45],state[0:1:134][44:1:45],CalChanSummary[0:1:2377],CalFlag[0:1:134][0:1:2377],NeN[0:1:2377],Latitude[0:1:134][44:1:45],Longitude[0:1:134][44:1:45],Time[0:1:134][44:1:45]';

        %disp([fname{1} ' ? ' vars])
        %disp('');
        %try
        [radiances scanang satheight nadirTAI sat_lat sat_lon satzen satazi ...
          solzen solazi sun_glint_distance topog landFrac state CalChanSummary CalFlag NeN Latitude Longitude Time] = getdata_opendap(fname{1},vars);
        %disp([fname{1} '.das']);
        ur = urlread([fname{1} '.das']);
        %catch e
        %  e
        %  keyboard
        %  disp(' fail');
        %  continue
        %end

        pos_eqtime = strfind(ur,'EQUATORCROSSINGTIME');
        pos_eqdate = strfind(ur,'EQUATORCROSSINGDATE');
        pos_value = strfind(ur,'VALUE "');
        pos_et_val = pos_value(find(pos_value > pos_eqtime(1),1))+7;
        pos_ed_val = pos_value(find(pos_value > pos_eqdate(1),1))+7;
        
        %eqtime = regexprep(ur(pos_et_val(1):pos_et_val(2)),'.*>"(.*)"<.*','$1');
        %eqdate = regexprep(ur(pos_ed_val(1):pos_ed_val(2)),'.*>"(.*)"<.*','$1');
        eqtime = ur(pos_et_val:pos_et_val+14);
        eqdate = ur(pos_ed_val:pos_ed_val+9);

        eq_x_tai = mattime2tai(datenum(eqdate)) + str2num(eqtime(1:2))*3600+str2num(eqtime(4:5))*60+str2num(eqtime(7:end-1));

r = floor(1:0.5:135.5);

prof = struct;
prof.xtrack = reshape(repmat([45 46]',1,135),1,270);
prof.atrack = reshape(repmat(1:135,2,1),1,270);

prof.robs1 = reshape(radiances,2378,270);

prof.scanang = reshape(scanang,1,270);
prof.zobs = reshape(satheight(r),1,270)*1000;

prof.udef = zeros(10,270);
prof.udef(1,:) = sat_lat(r);
prof.udef(2,:) = sat_lon(r);
prof.udef(3,:) = nadirTAI(r)-reshape(Time,1,270);
prof.udef(4,:) = eq_x_tai-reshape(Time,1,270);
prof.satzen = reshape(satzen,1,270);
prof.satazi = reshape(satazi,1,270);

prof.solzen = reshape(solzen,1,270);
prof.solazi = reshape(solazi,1,270);
prof.glint = reshape(sun_glint_distance,1,270);
prof.salti = reshape(topog,1,270);
prof.landfrac = reshape(landFrac,1,270);

prof.robsqual = reshape(state,1,270);

prof.rlat = reshape(Latitude,1,270);
prof.rlon = reshape(Longitude,1,270);
prof.rtime = reshape(Time,1,270);

% Replacing calnum for the calflag field
[prof.calflag, cstr] = data_to_calnum(mean(Time(:)), head.vchan, NeN', ...
   CalChanSummary', reshape(CalFlag(r,:)',2378,270));
%prof.calflag = reshape(CalFlag(:,r),2378,270);
pattr = set_attr(pattr,'calflag',cstr);

if exist('prof_all','var');
  [head prof_all] = cat_rtp(head,prof_all,head,prof);
else
  prof_all = prof;
end
%prof_all

if fix((gran-1)/10) < fix((next_gran-1)/10) | k == length(dirlist)
  %rtpname = ['/asl/data/rtprod_airs/' datestr(mdate,'yyyy/mm/dd') 'AIRIBRAD_CTR_' datestr(mdate,'yyyymmdd') '.rtp'];
  disp(['GRAN # ' num2str(gran) ' -> ' rtpname])
  salti = prof.salti;
  hattr = set_attr(hattr,'rtpfile',rtpname);
  %[head2,hattr2,prof_all,pattr2]=rtpadd_era_data(head,hattr,prof_all,pattr);
  prof.salti = salti;
  rtpwrite(rtpname,head,hattr,prof_all,pattr);
  clear prof_all
end

    end

if ~exist('prof_all','var'); prof_all = []; end


