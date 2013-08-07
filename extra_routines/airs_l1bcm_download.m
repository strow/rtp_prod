function airs_l1bcm_download(sdate, edate, asldataairs)
% function airs_l1bcm_download(sdate, edate, asldataairs)
% 
%   Downloads AIRS L1bCM data tha fits in the requested date range.
%
%   sdate, edate - start/end dates (matlab format)
%   asldataairs = '/asl/data/airs/'  (data location)
%
%   This routine also produce AIRS matadata.
%
%   See also: airs_l1bcm_filenames.m  - this routine uses the same internal 
%                                     looping structure.
% Breno Imbiriba - 2013.08.01



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


%    % Make metadata - using Paul's code:
%    cmd = ['$RTPROD/airs/utils/get_meta_data ' syyy sm sd ];
%    [status result] = system(cmd);


  end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end


