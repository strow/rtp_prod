function flist = get_ccast_fname(stime, etime, path)
% function flist = get_ccast_fname(stime, etime, path)
%
%   stime - start mtime 
%   etime - end mtime
%   path  - path to the data set
%
%   Search the 'path' for file names of the form:
%
%     path/yyyy/ddd/SDR_dyyyymmdd_tHHMMSSF.mat
%
%   that span the requested time interval (up to but not including etime).
%   
% 
% Breno Imbiriba - 2013.06.12

  flist = {};
  % Howard's cris data files have the following name convention:
  % SDR_dyyyymmdd_tHHMMSSF.mat

  % Loop over days 
  for iday = 0:(floor(etime)-floor(stime))
   
    yyyy = datestr(floor(stime)+iday,'yyyy');
    ddd  = num2str(doy(floor(stime)+iday),'%03d');


    % Grab all files for that day 
    loc = [path '/' yyyy '/' ddd '/SDR_d*_t*.mat'];

    files = dir(loc);

    % Compute data time based on file name string
    fmtime0 = [];

    for iff=1:numel(files)
       rname = files(iff).name;
       [data nread] = sscanf(rname,'SDR_d%08s_t%07s');
       fmtime0(iff) = datenum([data '00'],'yyyymmddHHMMSSFFF');
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

