function create_rtp_l1b(dates, granules, overwrite, output_dir)
% Create AIRS L1b RTP structures
%
% function create_rtp_l1b(dates, granules, overwrite, output_dir)
% 
% date - a particular data in matlab format (range)
% granule - (optional) the desired granule number array (empty means all)
% overwrite - (optional) 0-don't, 1-do.
% output_dir - (optional) overide the default dump directory.
%
% Eg.: create_rtp_l1b(datenum(2012,09,20)); % all grans
%      create_rtp_l1b(datenum(2012,09,20:22),[]);  % two days, all grans
%      create_rtp_l1b(datenum(2012,09,20),[16:24]); % grans 16-24
%
% Breno Imbiriba
% Paul Schou

 
% External routines:
% readl1b_all
% rtpwrite_all
% usgs_deg10_dem
% findfiles
% fixedsites
% say

  rn = 'create_rtp_l1b';
  say('Start');

  if(~exist('granules','var'))
    granules=[];
  end
  if(~exist('overwrite','var'))
    overwrite=0;
  end
  if(~exist('output_dir','var'))
    output_dir='';
  end

   
  [rtp_files, hdf_files, fetch_dates] = get_needed_files_l(dates, granules, overwrite, output_dir);

  hdf_files = fetch_l1b_data_l(hdf_files,fetch_dates);

  for iff=1:numel(hdf_files)
    [eq_x_tai, f, gdata] = readl1b_all(hdf_files{iff});
    prof = make_prof_structure_l(eq_x_tai, f, gdata);

    [head hattr pattr] = make_head_structure_l(prof,f);

    summary = make_summary_structure_l(rtp_files, hdf_files, fetch_dates);

    save_data_l(rtp_files{iff}, head,hattr,prof,pattr,summary);
  end

  say('End');
end



function [rtp_files, hdf_files, fetch_dates]= get_needed_files_l(dates, granules, overwrite, override_output_dir)

  % This subroutine construct the name of the GOAL files
  % by looking at the desired dates and granules
  % Then checks if they already exist or if we should
  % just overwrite them.

  input_dir_root = '/asl/data/airs/AIRIBRAD/';
  output_dir_root = '/asl/data/rtprod_airs/';

  % Goal file.
  datatype = 'airs_l1b';

  if(isempty(granules))
    granules=[1:240];
  end
      
  ik=0; 
  for idates=1:numel(dates)
    for igran=1:numel(granules)

      [yyyy mm dd] = datevec(dates(idates));
      ggg = granules(igran);
      jday = dates(idates) - datenum(yyyy,1,1,0,0,0) + 1;


      syyyy = sprintf('%04d',yyyy);
      smm = sprintf('%02d',mm);
      sdd = sprintf('%02d',dd);
      sjday = sprintf('%03d',jday);

      input_dir = [input_dir_root '/' syyyy '/' sjday '/'];
      output_dir = [output_dir_root '/' syyyy '/' smm '/' sdd '/'];

      if(~isempty(override_output_dir))
        output_dir = override_output_dir;
      end

      datelabel = sprintf('%04d.%02d.%02d.%03d',yyyy,mm,dd,ggg);

      hdf_files_t = [ input_dir '/AIRS.' datelabel '.L1B.AIRS_Rad.v5.*.hdf' ];
      rtp_files_t = [ output_dir '/' datatype '.' datelabel '.rtp' ];

      if(~exist(rtp_files_t,'file') || overwrite)
        ik=ik+1;
	rtp_files{ik} = rtp_files_t;
        hdf_files{ik} = hdf_files_t;
        fetch_dates(ik,:) =  [datenum(yyyy,mm,dd), ggg 0];
 
        % if file doesn't exist OR set to overwrite set it to download
        if(isempty(findfiles(hdf_files_t)) || overwrite)
	  fetch_dates(ik,:) = [datenum(yyyy,mm,dd), ggg 1*overwrite];
        end

      end

    end
  end

end


function hdf_files = fetch_l1b_data_l(hdf_files, fetch_dates)

  % Here we will fetch the needed files
  % Fix the hdf_file names

  for iff=1:size(fetch_dates,1)
    yyyymmdd=datestr(fetch_dates(iff,1));
    sggg=num2str(fetch_dates(iff,2));
    cmd=['/asl/opt/bin/getairs ' yyyymmdd ' 1 AIRIBRAD.005 ' sggg  '> /dev/null '];
    if(fetch_dates(iff,3))
      system(cmd);
    end
    ctmpfile = findfiles(hdf_files{iff});
    hdf_files{iff} = ctmpfile{1};
  end
end

function prof = make_prof_structure_l(eq_x_tai, f, gdata)
  % Fixed site matchup range {km} 
  site_range = 55.5;  % we 55.5 km for AIRS

  % Default CO2 ppmv
  co2ppm_default = 385.0;

  % No data value
  nodata = -9999;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Construct PROFILE structure
  prof.rtime = gdata.rtime(:)';  %'
  nok = length(prof.rtime);

  prof.rlat = gdata.rlat(:)';  %'
  prof.rlon = gdata.rlon(:)';  %'
  prof.satazi = gdata.satazi(:)'; %'
  prof.satzen = gdata.satzen(:)'; %'
  prof.zobs = gdata.zobs(:)'; %'
  prof.solazi = gdata.solazi(:)'; %'
  prof.solzen = gdata.solzen(:)'; %'
  prof.robs1 = gdata.robs1;

  prof.atrack = gdata.atrack(:)'; %'
  prof.xtrack = gdata.xtrack(:)'; %'

  prof.calflag = gdata.calflag;

  % default CO2 values
  prof.co2ppm = co2ppm_default*ones(1,nok);

  % write out the file index number for which file the data came from
  %   note: file names & dates are only available in the summary file
  prof.findex = gdata.findex(:)'; %'

  s = abs(prof.rlat) <= 90 & abs(prof.rlon) <= 180;
  prof.salti = ones(1,nok)*nodata;
  [prof.salti(s) prof.landfrac(s)] = usgs_deg10_dem(prof.rlat(s),prof.rlon(s));

  % fill out the iudef values
  prof.iudef = nodata*ones(10,nok);

  % Check for fixed sites
  [isiteind, isitenum] = fixedsite(prof.rlat(s), prof.rlon(s), site_range);
  if (isempty(isiteind))
    prof.iudef(2,s(isiteind)) = isitenum;
  end

  % fill out the iudef values
  prof.udef = nodata*ones(20,nok);
  prof.udef(1,:) = eq_x_tai(:)' - gdata.rtime(:)';

end

function [head hattr pattr] = make_head_structure_l(prof,f)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Making HEADER/ATTR structures
  nchan = size(prof.robs1,1);
  ichan = (1:nchan)';

  % Determine channel freqs
  vchan = f(:);

  %%%%%%%%%  Make a HEADER structure
  head = struct;
  head.pfields = 4;
  head.ptype = 0;
  head.ngas = 0;

  % Assign RTP attribute strings
  hattr={ {'header' 'pltfid' 'Aqua'}, ...
	  {'header' 'instid' 'AIRS'} };
  %
  pattr={ {'profiles' 'rtime' 'seconds since 1 Jan 1993'}, ...
	  {'profiles' 'robsqual' '0=good, 1=bad'}, ...
	  {'profiles' 'udef(1,:)' 'eq_x_tai - rtime'} };

  % PART 1
  head.instid = 800; % AIRS 
  head.nchan = length(ichan);
  head.ichan = ichan;
  head.vchan = vchan(ichan);

end


function summary = make_summary_structure_l(rtp_files, hdf_files, fetch_dates)

  summary.gran_files = hdf_files;
  summary.gran_dates = fetch_dates;
  summary.rtp_files = rtp_files;

end



function save_data_l(rtp_file, head, hattr, prof,pattr,summary)

  rtpwrite_all(rtp_file, head, hattr, prof, pattr);

  [a b ~] = fileparts(rtp_file);
  smfile = [a '/summary.' b '.mat'];

  save(smfile, 'summary');

end

