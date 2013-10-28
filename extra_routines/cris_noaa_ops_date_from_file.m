function [scris_mtime scris_etime scris_fstr scris_ctime] = cris_noaa_ops_date_from_file(scris_fstr)
% function [sdate edate file_list cdate] = cris_noaa_ops_date_from_file(flist)
%
% Take the list of CrIS's NOAA files (flist) and parse the start date, 
% end date, and if there are repetitions, choose the newest one 
% (from an also parsed creation time (ctime) field in the file name)
%
% INPUTS
%   flist - cell array of CrIS Noaa files:
%           Eg.:
%           {'SCRIS_npp_d20120920_t1821059_e1829037_b04659_c20130715193739522802_ssec_dev.h5'}
% OUTPUT
%   sdate - array of start dates (matlab time)
%   edate - array of end dates (matlab time)
%   file_list - cell array of file names - this is *the same* as flist
%               unless there are repetitions.
%   cdate - array of creation dates (matlab time)
%
% Breno Imbiriba - 2013.10.26


  scris_mtime = [];
  scris_etime = [];
  scris_ctime = [];

  for ifile = 1:numel(scris_fstr)
    [~, fn] = fileparts(scris_fstr{ifile});
    Dyyyymmdd = fn(12:19);
    Thhmmss = fn(22:28);
    Ehhmmss = fn(31:37);
    Cyyyymmddhhmmss = fn(47:60);

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

    scris_fstr = scris_fstr{ifile}
    scris_mtime = scris_mtime(ikeep);
    scris_ctime = scris_ctime(ikeep);
    scris_etime = scris_etime(ikeep);
  end 

end
