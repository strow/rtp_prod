function flist = get_airs_l1b_fname(stime, etime, path)
% function flist = get_airs_l1b_fname(stime, etime, path)
%
%   stime - start mtime 
%   etime - end mtime
%   path  - path to the data set
%
%   Search the 'path' for file names of the form:
%
%     /yyyy/ddd/AIRS.yyyy.mm.dd.ggg.L1B.AIRS_Rad.v5.0.21.0.G13015082558.hdf
%
%     path = /asl/data/airs/AIRIBRAD
%   that span the requested time interval (up to but not including etime).
%   
%  
% Breno Imbiriba - 2013.06.12

% Following some aspects of airs/rtp/rtp_core.m 

  

  flist = {};

  % AIRS file name  ----------------- * --- this number is the version number. 
  % AIRS.yyyy.mm.dd.ggg.L1B.AIRS_Rad.v5.0.21.0.G13015082558.hdf

  % Loop over days 
  for iday = 0:(floor(etime)-floor(stime))
  
    yyyy = datestr(floor(stime)+iday,'yyyy');
    nyyy = datevec(floor(stime)+iday); nyyy = nyyy(1);

    ddd  = num2str(doy(floor(stime)+iday),'%03d');
    ndd  = doy(floor(stime)+iday);


    % Grab all files for that day 
    locdir = [path '/' yyyy '/' ddd ];
    loc = [locdir '/AIRS.*.*.*.*.L1B.AIRS_Rad.v*.hdf'];

    files = dir(loc);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do we need to fetch data?
    % If number of files is less then expected, and if the modification
    % date of locdir is less than 3 days of NOW, attempt to fetch data.
    if(numel(files)<240)
    
      disp(['For date ' yyyy ddd ' there are only ' num2str(numel(files)) ' AIRS L1B files. Will attempt to download the rest...']);
      tdd = dir(locdir);
      if(now - tdd(1).datenum > 3)

	fetch_cmd = ['/asl/opt/bin/getairs ' yyyy ddd ' 1 AIRIBRAD.005 > /dev/null'];
	system(fetch_cmd);

	% Check listing again:
	files = dir(loc);
	if(numel(files)<240)
	  disp(['... Issued getairs command but still have only ' num2str(numel(files)) '. Will continue anyway.']);
	end 
      else
	disp(['... no, will wait at least 3 days before a new attempt.']);
      end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute data time based on file name string
    fmtime0 = [];

    for iff=1:numel(files)
       rname = files(iff).name;
       [data nread] = sscanf(rname,'AIRS.%*04d.%*02d.%*02d.%03d');
       fmtime0(iff) = datenum(nyyy,1,ndd+(data-1)./240,0,0,0);
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
      flist{n0+iff} = [locdir '/' files(indx(ifile(iff))).name];
    end
  end

end

