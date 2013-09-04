function file_list = airs_l1bcm_filenames(sdate,edate,asldataairs)
% function file_list = airs_l1bcm_filenames(sdate,edate,asldataairs)
%
%   Look for the AIRS L1bCM files that span the time interval between 
%  
%   sdate, edate - start/end dates (matlab format)
%   asldataairs = '/asl/data/airs/'  (data location)
%
%
% Breno Imbiriba - 2013.07.10



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

    nfile = nfile + 1;

    file_glob{nfile} = [asldataairs '/AIRXBCAL/' syyy '/' sm '/' sd '/AIRS.' syyy '.' sm '.' sd '.L1B.Cal_Subset.*.hdf'];

  end

  % Now test if the files exist - and only keep the ones that do:


  nfile = 0;
  for iglob = 1:numel(file_glob)
    ddir = dir(file_glob{iglob});
    if(numel(ddir)==1)
      nfile = nfile + 1;
      file_list{nfile} =  [dirname(file_glob{iglob}) '/' ddir.name];
     end
   end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end

