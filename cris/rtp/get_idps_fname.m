function flist = get_idps_fname(stime, etime, path)
% function flist = get_idps_fname(stime, etime, path)
%
%   Find IDPS CrIS file names.
%
%   stime - start mtime 
%   etime - end mtime
%   path  - path to the data set
%
%   Search the 'path' for file names of the form:
%
%     /asl/data/cris/sdr60/hdf/
%     path/yyyy/ddd/SCRIS_npp_dyyyymmdd_tHHMMSSF_eHHMMSSF_b06121_cyyyymmddHHMMSS638444_noaa_ops.h5
%     (In the case of repeated dates and times, will use the latest "c" time)
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
    loc = [path '/' yyyy '/' ddd '/SCRIS_npp_d*_t*_e*_b*_c*_noaa_ops.h5'];
    files = dir(loc);

    % Compute data time based on file name string
    fmtime0 = [];

    for iff=1:numel(files)
       rname = files(iff).name;
       [data nread] = sscanf(rname,'SCRIS_npp_d%08s_t%07s_e%07s_b%05s_c%20s_noaa_ops.h5');
       fmtime0(iff) = datenum([data(1:15) '00'],'yyyymmddHHMMSSFFF');

    end     

    [fmtime indx] = sort(fmtime0);

    % check for non unique results
    [uniq_t iaa icc] = unique(fmtime);

    if(numel(uniq_t)~=numel(fmtime))
      % There are repeated files! 
      % Compute "This and next are repeated" logical vector
      irep = find(diff(icc)==0);

      % loop over these repetitions
      for ii=1:numel(irep)
   	% Find old end mark for removal
	[~,imrm0] = min(fctime(irep(ii)+[0 1]));
	imrm(ii) = irep(ii)+imrm0-1;
      end
      
      % Remove these file names:
      fmtime(imrm) = [];
      indx(imrm) = [];

    end

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

