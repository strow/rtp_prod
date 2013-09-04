function [file_list nfiles] = cris_ccast_filenames(sdate, edate, asldata, datatype)
% function [file_list nfiles] = cris_ccast_filenames(sdate, edate, asldata, datatype)
%
%   Look for the CRIS "datatype" files that span the time interval between
%   sdate and edade (matlab times) in the $asldata/cris/$datatype/hdf/yyyy/ddd
%   Eg. asldata  = '/asl/data',
%       datatype = 'sdr60'            
%                  'ccast_sdr60' 
%                  'ccast_sdr60_dt1' 
%                  'ccast_sdr60_dt2' 
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

    if(strcmpi(datatype, 'ccast_sdr60_dt1'))
      path = [asldata '/cris/ccast/sdr60_dt1/' num2str(yyyy,'%04d') '/' num2str(ddd,'%03d') ];
    elseif(strcmpi(datatype, 'ccast_sdr60_dt2'))
      path = [asldata '/cris/ccast/sdr60_dt2/' num2str(yyyy,'%04d') '/' num2str(ddd,'%03d') ];
    elseif(strcmpi(datatype, 'ccast_sdr60'))
      path = [asldata '/cris/ccast/sdr60/' num2str(yyyy,'%04d') '/' num2str(ddd,'%03d') ];
    else
      error(['Unknonw data type ' datatype '.']);
    end

    % Load SDR file names for this day
    sdr_fstr = dir([path '/SDR_*.mat']);

    if(numel(sdr_fstr)==0)
      disp(['No files found at ' path '/SDR_*.mat'] );    
    end
    % Get file time stamps
%         1         2         3
%1234567890123456789012345678901
%SDR_d20120919_t1437126.mat

    sdr_mtime = [];

    for ifile = 1:numel(sdr_fstr)
      Dyyyymmdd = sdr_fstr(ifile).name(6:13);
      Thhmmss = sdr_fstr(ifile).name(16:22);

      sdr_mtime(ifile) = datenum([Dyyyymmdd Thhmmss],'yyyymmddHHMMSS');

    end

    % Select desired files in this day
    igood = find(sdr_mtime >= sdate & sdr_mtime <= edate);

    for ifile = 1:numel(igood)
      file_list{nfiles+ifile} = [path '/' sdr_fstr(igood(ifile)).name];
    end
    nfiles = nfiles + numel(igood);
  end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end


