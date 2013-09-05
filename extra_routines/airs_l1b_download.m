function airs_l1b_download(sdate, edate, asldata)
% function airs_l1b_download(sdate, edate, asldata)
% 
%   Downloads AIRS L1b data tha fits in the requested date range.
%
%   See also: airs_l1b_filenames.m  - this routine uses the same internal 
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

      % Let's check if the data is there:
      file_glob = [asldata '/AIRIBRAD/' syyy '/' sm '/' sd '/AIRS.' syyy '.' sm '.' sd '.' sgg '.L1B.AIRS_Rad.*.hdf'];
      ddir = dir(file_glob);
      if(numel(ddir)==0)
	% File does not exist.
	% Issue download command:
	dnldcmd = ['$RTPROD/bin/getairs ' syyy sm sd ' 1 AIRIBRAD.005 ' sgg ' ' asldata ];
	disp(dnldcmd);
	[status result] = system(dnldcmd);
      else
	disp(['File ' ddir.name ' already exists.']);
      end 

    end

  end

end

function ddd = doy(mdate)
  vec = datevec(mdate);
  ddd = floor(mdate - datenum(vec(1),1,1,0,0,0))+1;

end


