function [file_list nfiles] = iasi_l1c_filenames(sdate, edate, asldata, datatype)
% function [file_list nfiles] = iasi_noaa_ops_filenames(sdate, edate, asldata, datatype)
%
%   Look for the CRIS "datatype" files that span the time interval between
%   sdate and edade (matlab times) in the $asldata/iasi/$datatype/yyyy/mm/dd
%   Eg. asldata  = '/asl/data',
%       datatype = 'L1C'            
%        
%
% Breno Imbiriba - 2013.08.01


  file_list = {};
  nfiles = 0;

  sday = floor(sdate);
  eday = floor(edate);

  % Loop over days
  for mdate = sday:eday
    [yyyy mm dd HH MM SS] = datevec(mdate);

    if(strcmpi(datatype,'l1c'))
      %/asl/data/IASI/L1C/2012/09/20/
      path = [asldata '/IASI/L1C/' num2str(yyyy,'%04d') '/' num2str(mm,'%02d') '/' num2str(dd,'%02d') ];
    else
      error(['Unknown datatype ' datatype]);
    end

    % Load SCRIR file names for this day
    siasi_fstr = dir([path '/IASI_xxx_*.gz']);

    if(numel(siasi_fstr)==0)
      disp(['No files found at ' path '/IASI_xxx_*.gz'] );    
    end
    % Get file time stamps
%         1         2         3         4         5     
%1234567890123456789012345678901234567890123456789012345
%IASI_xxx_1C_M02_20120920220259Z_20120920220555Z.gz
%                yyyymmddHHMMSS  yyyymmddHHMMSS

    siasi_mtime = [];
    siasi_etime = [];

    for ifile = 1:numel(siasi_fstr)
      Dyyyymmdd = siasi_fstr(ifile).name(17:24);
      Thhmmss = siasi_fstr(ifile).name(25:30);
      Eyyyymmdd = siasi_fstr(ifile).name(33:40);
      Ehhmmss = siasi_fstr(ifile).name(41:46);

      siasi_mtime(ifile) = datenum([Dyyyymmdd Thhmmss],'yyyymmddHHMMSS');
      siasi_etime(ifile) = datenum([Eyyyymmdd Ehhmmss],'yyyymmddHHMMSS');

    end


    % Select desired files in this day
    igood = find(siasi_mtime >= sdate & siasi_mtime <= edate);

    for ifile = 1:numel(igood)
      file_list{nfiles+ifile} = [path '/' siasi_fstr(igood(ifile)).name];
    end
    nfiles = nfiles + numel(igood);
  end

end


