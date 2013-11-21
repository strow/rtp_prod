function airs_l1bcm_download(sdate, edate, asldataairs)
% function airs_l1bcm_download(sdate, edate, asldataairs)
% 
%   Downloads AIRS L1bCM data tha fits in the requested date range.
%
%   sdate, edate - start/end dates (matlab format)
%   asldataairs = '/asl/data/airs/'  (data location)
%
%   This routine also produce AIRS metadata.
%
%   See also: airs_l1bcm_filenames.m  - this routine uses the same internal 
%                                     looping structure.
% Breno Imbiriba - 2013.08.01
% Breno Imbiriba - 2013.11.21 - Added fetch for metadata


  file_list={};
  file_glob={};
  nfile = 0;

  % Go day by day:
  for day = floor(sdate):floor(edate)
    ddd = doy(day);
    sdd = num2str(ddd,'%03d'); 

    [yyyy mm dd] = datevec(day);
    syyy = num2str(yyyy,'%04d');
    sm = num2str(mm,'%02d');
    sd = num2str(dd,'%02d');


    % One file per day.

    nfile = nfile + 1;

    % Let's check if the data is there:
    file_glob = [asldataairs '/AIRXBCAL/' syyy '/' sm '/' sd '/AIRS.' syyy '.' sm '.' sd '.L1B.Cal_Subset.*.hdf'];
    ddir = dir(file_glob);

    if(numel(ddir)==0)
      % File does not exist.
      % Issue download command:
      dnldcmd = ['$RTPROD/bin/getairs ' syyy sm sd ' 2 AIRXBCAL.005 ' asldataairs];
      disp(dnldcmd);
      [status result] = system(dnldcmd);
    else
      disp(['File ' ddir.name ' already exists.']);
    end 


    % Produce Meta data

    % Make metadata - using Paul's code: rtp_core_l1bcm.m
    % Load the last granule (240) of the Previous day
    [pyyy pm pd] = datevec(day-1);
    cmd = sprintf('$RTPROD/airs/utils/get_meta_data %04d%02d%02d 240 \n',pyyy, pm, pd);
    system(cmd)
  
    % Download all the granules of this day
    cmd = sprintf('$RTPROD/airs/utils/get_meta_data %04d%02d%02d \n',yyyy,mm,dd);   
    system(cmd)
  end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end


