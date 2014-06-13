function rtp_run(dates,  dataset, model, emis, sst, output, cleartype, fovsset, freqsset)
% function rtp_run(dates,  dataset, model, emis, sst, output, cleartype, fovsset, freqsset)
%
% Creates the basic RTP matchup for the requested instrument data 
% with model data.  
% Optionaly perform clear sunseting or a frequence subseting. 
%
%        dates     Matlab time for the start and end  (on  the  optional  second
%                 dimension)  of  the process.  If only one number is provided,
%                 end_date will be the end last milisecond  of  the  day  where
%                 start_date is.  Usually
%
%                         start_date = datenum(yyyy,mm,dd,00,00,00);
%                         end_date = datenum(yyyy,mm,dd,59,59,59.999);
%
%                 but any other interval could be used.
%
%
%       dataset   Text  string  for  the  possible satellite dataset: airs_l1b,
%                 airs_l1bcm, iasi_l1c, cris_idps, cris_ccast.
%
%
%       model     Text string for which model data to use: merra, ecmwf, era.
%
%
%       emis      Text string for which surface emissivity to use: dan, wisc
%
%
%       sst       Text string to select the ocean  surface  temperature  model:
%                 default (defailt from the model), sergio
%
%
%       output    Root directory for saving the product. Usually (for cris):
%
%                 /asl/data/rtprod_cris/
%
%	cleartype Define whith type of clear detection algorithm should be used:
%		  "uniform clear" (is the only one, and is the default)
%
%       fovsset   Text  string  for  which  FoV  subsetting  to use: 
%                 "clear subset" 
%
%
%       freqsset  Cell array with a frequency subset and label: {[channel  num‐
%                 bers],"label"}
%
%
% Paul Schou, Breno Imbiriba  - 2013.06.11
% (C) ASL/UMBC Group 2013 - Under GPL3.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 - Setup 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
  % HELLO
  rn='rtp_run'
  greetings(rn);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Enable or disable warnings if necessary
  % warninig('off','ASL:Warn');


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Check input arguments
  if(numel(dates)==1)
    warning('ASL:Warn','Input variable "dates" has no end date. Setting it to the end of the day (to the last milisecond!)');
    dates(2) = floor(dates(1))+0.99999998; % To the last milisecond 0.999 999 988 425 926
  end  


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
  % Acquire code version number
  version = version_number();

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
  % Setup time blocks
  % Time blocks are the divisions of the day (24hr)
  % that we accumulate in.
  % 
  % nblocks	duration	instrument
  %
  % 240		6 mins		AIRS all fovs (no clear subset)
  % 180		8 mins		CRIS original granule break out
  % 144		10 mins		CRIS 10 mins/day files ( 103x )
  % 24		1 hr		clear subset files
  %
  % span == nblocks

  if(strcmp(fovsset,'uniform clear'))
    nblocks = 24;
  else 
    if(strcmp(instrument,'airs'))
      nblocks = 240;
    elseif(strcmp(instrument,'iasi'))
      nblocks = 144;
    elseif(strcmp(instrument,'cris'))
      nblocks = 144;
    else
      error('Cannot define nblocks');
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
  % time length (in days) of each block
  dt_block = 1./nblocks;

  %idx_block = [0:nblocks-1];  % span, nblock=day2span

  
  % Compute blocks - the start l

  % compute start 
  startday  = floor(dates(1));
  starttime = dates(1)-startday;
  endtime   = dates(2)-startday;

  % Make time block start times
  tblock = [startday:dt_block:dt_block.*nblocks];

     
  disp(['Processing t0=' datestr(dates(1),'yyyy/mm/dd - HH:MM:SS') ...
                  ' tf=' datestr(dates(2),'yyyy/mm/dd - HH:MM:SS') ]);


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
  % Find which entried of 'span' match these times:
  iokspan = find(idx_block>=floor(starttime*nblocks) & idx_block<ceil(endtime*nblocks));

   
  if(numel(iokspan)==0)
    disp(['No time block selected: ' datestr(starttime,'HH:MM:SS') ' - ' datestr(endtime,'HH:MM:SS') ]);
    disp(rtpset)
    disp(span);
    disp(starttime*day2span)
    disp(endtime*day2span);
  end

  idx_block = idx_block(iokspan);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 - Loop over time blocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for iblock = idx_block


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.1. - Load Instrument data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    % 2.1.1 - Get file names
    %         Each dateset has a 
    %         different file naming convention

    switch dataset
    case 'cris_ccast'
      % Get file list
      file_list = ... 
	   get_ccast_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'cris_idps'

      file_list = ...
	  get_idps_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'iasi_l1c'
      file_list = ...
	  %get_iasi_l1b_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'airs_l1b'
      file_list = ...
	  %get_airs_l1b_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'airs_l1bcm'
      file_list = ...
	  %get_airs_l1bcm_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    otherwise
      error(['Wrong dataset']);
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.1.2 - Load and make RTP structures
	
    switch dataset
    case 'cris_ccast'
      [head hattr prof pattr] = rtpmake_ccast_datafiles(file_list);
    case 'cris_idps'
      [head hattr prof pattr] = rtpmake_idps_datafiles(file_list);
    case 'iasi_l1c'
    case 'airs_l1b'
    case 'airs_l1bcm'
    otherwise
      error(['Wrong dataset']);
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2 - Add Model Information 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2.1 - Add surface topography
    [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2.2 - Add atmospheric model
    switch model
    case 'ecmwf'
      [head hattr prof pattr] = add_ecmwf_data(head,hattr,prof,pattr);
    case 'era'
    case 'merra'
    otherwise
      error(['Wrong dataset']);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2.3 - Add SST model 
    switch sst
    case 'original'
      % do nothing
    case 'sergio'
      [head hattr prof pattr] = add_sst_sergio(head,hattr,prof,pattr);
    otherwise
      error(['Wrong sst command']);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2.4 - Add surface emissivity
    switch emis
    case 'dan'
    case 'wisc'
    otherwise
      error(['Wrong emis command']);
    end

  



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.3 - Perform Clear Detection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(~strcmp(cleartype,'uniform clear'))
      error('Bad clear type');
    end

    switch dataste
    case 'cris_ccast' | 'cris_idps'
      [head hattr prof pattr] = cris_clear_flag(head, hattr, prof, pattr);
    case 'iasi_l1c'
    case 'airs_l1b'
    case 'airs_l1bcm'
    otherwise
      error(['Wrong dataset']);
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.4 - Perform Subsetting
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(strcmp(fovsset,'clear subset'))
    switch fovsset
    case 'clear subset'
      [head hattr prof pattr] = subset_clear(head,hattr,prof,pattr);
    otherwise
      error(['Bad fov subset']);
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.5 - Save data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   
  end % End time block loop


end 


