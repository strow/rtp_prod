function [file_list nfiles] = cris_noaa_ops_filenames(sdate, edate, asldata, datatype)
% function [file_list nfiles] = cris_noaa_ops_filenames(sdate, edate, asldata, datatype)
%
%   Look for the CRIS "datatype" files that span the time interval between
%   sdate and edade (matlab times) in the $asldata/cris/$datatype/hdf/yyyy/ddd
%   Eg. asldata  = '/asl/data',
%       datatype = 'sdr60'            
%        
%
% Breno Imbiriba - 2013.07.29


  file_list = {};
  nfiles = 0;

  sday = floor(sdate);
  eday = floor(edate);

  % Loop over days
  for mdate = sday:eday
    [yyyy mm dd HH MM SS] = datevec(mdate);
    ddd = doy(mdate);
    path = [asldata '/cris/' datatype '/hdf/' num2str(yyyy,'%04d') '/' num2str(ddd,'%03d') ];

    % Load SCRIR file names for this day
    scris_fstr = dir([path '/SCRIS_npp_*_noaa_ops.h5']);

    if(numel(scris_fstr)==0)
      disp(['No files found at ' path '/SCRIS_npp_*_nooa_ops.h5'] );    
    end
    % Get file time stamps
%         1         2         3         4         5         6         7        
%1234567890123456789012345678901234567890123456789012345678901234567890123456789
%GCRSO_npp_d20120920_t0029139_e0037117_b04648_c20120920063710210374_noaa_ops.h5
%SCRIS_npp_d20120920_t0029139_e0037117_b04648_c20120920063710210774_noaa_ops.h5

    scris_mtime = [];
    scris_etime = [];
    scris_ctime = [];

    for ifile = 1:numel(scris_fstr)
      Dyyyymmdd = scris_fstr(ifile).name(12:19);
      Thhmmss = scris_fstr(ifile).name(22:28);
      Ehhmmss = scris_fstr(ifile).name(31:37);
      Cyyyymmddhhmmss = scris_fstr(ifile).name(47:60);

      scris_mtime(ifile) = datenum([Dyyyymmdd Thhmmss],'yyyymmddHHMMSS');
      scris_etime(ifile) = datenum([Dyyyymmdd Ehhmmss],'yyyymmddHHMMSS');

      % if end time is less than start time, it means this ends at the 
      % next day
      if(datenum(Ehhmmss,'HHMMSS')<datenum(Thhmmss,'HHMMSS'))
        scris_etime(ifile) = scris_etime(ifile) + 1;
      end

      scris_ctime(ifile) = datenum(Cyyyymmddhhmmss,'yyyymmddHHMMSS');
    end

    % If there are repetitions, take the newest created one
    if(numel(unique(scris_mtime))~=numel(scris_mtime))
      ikeep = [1:numel(scris_mtime)];

      for ifile = 1:numel(scris_mtime)
        irepeat = find(scris_mtime==scris_mtime(ifile));
        if(numel(irepeat)>1)
 	 idel = find(scris_ctime(irepeat)<max(scris_ctime(irepeat)));
          ikeep(irepeat(idel)) = 0;
        end
      end
      ikeep(ikeep==0) = [];
 
      scris_fstr = scris_fstr(ikeep);
      scris_mtime = scris_mtime(ikeep);
      scris_ctime = scris_ctime(ikeep);
      scris_etime = scris_etime(ikeep);
    end 


    % Select desired files in this day
    igood = find(scris_mtime >= sdate & scris_mtime <= edate);

    for ifile = 1:numel(igood)
      file_list{nfiles+ifile} = [path '/' scris_fstr(igood(ifile)).name];
    end
    nfiles = nfiles + numel(igood);
  end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end


