function flist = get_iasi_l1b_fname(stime, etime, path)
% function flist = get_iasi_l1b_fname(stime, etime, path)
%
%   stime - start mtime 
%   etime - end mtime
%   path  - path to the data set
%
%   Search the 'path' for file names of the form:
%
%     path/yyyy/mm/dd/IASI_xxx_1C_M02_yyyymmddHHMMSSZ_yyyymmddHHMMSSZ.gz
%
%   that span the requested time interval (up to but not including etime).
%   
%  See also: get_ccast_fname
%
% Breno Imbiriba - 2013.06.24

% Based on get_ccast_fname.m


  flist = {};
  % IASI data files have the following name convention:
  %                 12356478901235  
  % IASI_xxx_1C_M02_yyyymmddHHMMSSZ_yyyymmddHHMMSSZ.gz

  % Loop over days 
  for iday = 0:(floor(etime)-floor(stime))
   
    [yyyy mm dd] = datevec(floor(stime)+iday);
    yyyy = num2str(yyyy,'%04d');
    mm = num2str(mm,'%02d');
    dd = num2str(dd,'%02d'); 

    % Grab all files for that day 
    loc = [path '/' yyyy '/' mm '/' dd '/IASI_xxx_1C_M02_*.gz'];

    files = dir(loc);

    % Compute data time based on file name string
    fmtime0 = [];

    for iff=1:numel(files)
       rname = files(iff).name;
       [data nread] = sscanf(rname,'IASI_xxx_1C_M02_%15s_%15s');
       fmtime0(iff) = datenum(data, 'yyyymmddHHMMSS');
    end     

    [fmtime indx] = sort(fmtime0);

    % Choose which files fit in the requested time interval
    %   1    2    3    4	file index 
    % |....|....|....|....	fmtime - file duration (fmtime is at '|' marks)
    %         sxxxxxxxe		stime/etime - requested data range (stime,xxx,etime)
    %           |----|---- 
    %      |....|....|....|     selected files

    % Find files that start after stime and also start before etime.
    ifile = find(fmtime>stime & fmtime<etime);
   
    % Go back one to include stime. Etime is already included on the last one.
    if(min(ifile)~=1)
      ifile = [min(ifile)-1 ifile];
    end

    % Grab the file names for this day
    n0=numel(flist);
    for iff=1:numel(ifile)
      flist{n0+iff} = files(indx(ifile(iff))).name;
    end
  end

end


