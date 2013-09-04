function file_list = airs_l1b_filenames(sdate,edate,asldata)
% function file_list = airs_l1b_filenames(sdate,edate,asldata)
%
%   Look for the AIRS L1B files that span the time interval between 
%   sdate and edate (matlab times) in the asldata/yyyy/ddd path format.
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


    % For a day in the middle of the range, we have:
    g0 = mtime2airs_gran(day);
    g1 = mtime2airs_gran(day+.999999);

    % And now check if they fall off the actual range:
    if(day<sdate)
      g0 = mtime2airs_gran(sdate);
    end
    if(day == floor(edate))
      g1 = mtime2airs_gran(edate);
    end

    % If last granule start time IS the end time, we don't need this granule
    % Say .001 accuracy.
    if( (airs_gran2mtime(g1) - (edate-floor(edate)))<.001)
      g1 = g1 - 1;
    end

    for ig=g0:g1

      sgg = num2str(ig,'%03d');

      nfile = nfile + 1;

      file_glob{nfile} = [asldata '/AIRIBRAD/' syyy '/' sm '/' sd '/AIRS.' syyy '.' sm '.' sd '.' sgg '.L1B.AIRS_Rad.*.hdf'];
    end

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

