function rtp_run(dates,  dataset, model, emis, sst, output, cleartype, fovsset, freqsset, fpd)
% function rtp_run(dates,  dataset, model, emis, sst, output, cleartype, fovsset, freqsset, fpd)
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
%                 '' (empty) for nothing, 'dsst' for Sergio's diurnal code.
%
%
%       output    Root directory for saving the product. Usually (for cris):
%
%                 /asl/data/rtprod_cris/
%
%	cleartype Define whith type of clear detection algorithm should be used:
%		  "uc" (is the only one, and is the default)
%
%       fovsset   Text  string  for  which  FoV  subsetting  to use: 
%                 "clear subset" 
%
%
%       freqsset  Cell array with a frequency subset and label: {[channel  num‐
%                 bers],"label"}
%
%	fpd	  Number of files per day - usuall numbers are:
%                 hourly files - 24
%                 AIRS allfovs - 240
%                 CrIS allfovs - 144
%                 IASI allfovs - 144 (or something like that!)
%
% Paul Schou, Breno Imbiriba  - 2013.06.11
% (C) ASL/UMBC Group 2013 - Under GPL3.


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1 - Setup 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.0 - Basic Checks
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Enable or disable warnings if necessary
  % warninig('off','ASL:Warn');


  % 1.0.1 - Greetings
  rn = 'rtp_run';
  greetings(rn);


  % 1.0.2 - Acquire code version number
  version = version_number();


  % 1.0.2 - Check input arguments 
  %         before any work is done 
  %         (a local subroutine)

  [dates,  dataset, model, emis, sst, ...
          output, cleartype, fovsset, freqsset, fpd] = ...
             check_input_arguments_l(dates,  dataset, model, emis, sst, ...
                                     output, cleartype, fovsset, freqsset, fpd);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1.2 Compute time blocks
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %         tblocks - start time of a block
  %         idblocks - the "number" of the block
  [tblocks idblocks] = compute_tblocks_l(dates, fpd);
             nblocks = numel(tblocks);

  disp(['Processing t0=' datestr(dates(1),'yyyy/mm/dd - HH:MM:SS') ...
                  ' tf=' datestr(dates(2),'yyyy/mm/dd - HH:MM:SS') ]);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 2 - Loop over time blocks
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for iblock = 1:nblocks 


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.1. - Create output file name
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    output_fname = ...
              make_rtp_run_output_fname_l(tblocks(iblock), idblocks(iblock), ...
     	           dataset, model, emis, sst, output, cleartype, fovsset,...
	           freqsset, fdp,...
	           version);


    % 2.1.2 - Check if it already exists
    if(exist(output_fname,'file'))
      warining('ASL:Warn',['Output file ' output_fname ' already exists. Skipping']);
      continue
    end
 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.1. - Load Instrument data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    
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
	  get_iasi_l1c_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'airs_l1b'
      file_list = ...
	  get_airs_l1b_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    case 'airs_l1bcm'
      file_list = ...
	  get_airs_l1bcm_fname(tblock(iblock),tblock(iblock)+dt_block,data_path);

    otherwise
      error(['Wrong dataset']);
    end


    
    % 2.1.2 - Load and make RTP structures

    for ifile = 1:numel(file_list)    


      switch dataset
      case 'cris_ccast'
	[head hattr profi pattr] = sdr2rtp_bc(file_list{ifile});
      case 'cris_idps'
	[head hattr profi pattr] = sdr2rtp_h5(file_list{ifile});
      case 'iasi_l1c'
	[head hattr profi pattr] = iasi_uniform_and_allfov_func_list(file_list{ifile},true);
      case 'airs_l1b'
	[head hattr profi pattr] = rtpmake_airs_l1b_datafiles(file_list(ifile));
      case 'airs_l1bcm'
      otherwise
	error(['Wrong dataset']);
      end

      prof(ifile) = profi;

    end

    prof = structmerge(prof);

    % add version number on header attributes
    hattr = set_attr(hattr,'rev_rtp_core_hr',version);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2 - Add Model Information 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % 2.2.1 - Add surface topography
    [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.2.2 - Add atmospheric model
    switch model
    case 'ecmwf'
      [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
    case 'era'
      [head hattr prof pattr] = rtpadd_era(head,hattr,prof,pattr);
    case 'merra'
      [head hattr prof pattr] = rtpadd_merra(head,hattr,prof,pattr);
    case 'merra_cld'
      [head hattr prof pattr] = rtpadd_merra_cloudy(head,hattr,prof,pattr);

    otherwise
      error(['Wrong dataset']);
    end

    
    % 2.2.3 - Add SST model 
    switch sst
    case ''
      hattr = set_attr(hattr,'SST','model');
      % do nothing
    case 'dsst'
      [head hattr prof pattr] = driver_gentemann_dsst(head,hattr,prof,pattr);
    otherwise
      error(['Wrong sst command']);
    end

    
    % 2.2.4 - Add surface emissivity
    switch emis
    case 'dan'
      [head hattr prof pattr] = rtpadd_emis_DanZhou(head,hattr,prof,pattr);
    case 'wisc'
      [head hattr prof pattr] = rtpadd_emis_Wisc(head, hattr, prof, pattr);
    otherwise
      error(['Wrong emis command']);
    end

  



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.3 - Perform Clear Detection 
    %       And mark fov reason
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    switch cleartype
    case 'uc'
    otherwise 
      error('Bad clear type');
    end

    switch dataset
    case 'cris_ccast' | 'cris_idps'
      [head hattr prof pattr] = cris_clear_flag(head, hattr, prof, pattr);
    case 'iasi_l1c'
    case 'airs_l1b'
    case 'airs_l1bcm'
    otherwise
      error(['Wrong dataset']);
    end

% Adding solar?????


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.4 - Perform Subsetting
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(strcmp(fovsset,'clrset'))
    switch fovsset
    case 'clrset'
      [head hattr prof pattr] = subset_clear(head,hattr,prof,pattr);
    otherwise
      error(['Bad fov subset']);
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2.5 - Save data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   
  end % End time block loop


end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal Subroutines
% check_input_arguments_l
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [dates,  dataset, model, emis, sst, ...
          output, cleartype, fovsset, freqsset, fpd] = ...
             check_input_arguments_l(dates,  dataset, model, emis, sst, ...
                                     output, cleartype, fovsset, freqsset, fpd);

  
  if(numel(dates)==1)

    warning('ASL:Warn',...
    ['Input variable "dates" has no end date.',...
     'Setting it to the end of the day (to the last milisecond!)']);

    % To the last milisecond 0.999 999 988 425 926
    dates(2) = floor(dates(1))+0.99999998; 
  end  

  switch dataset
  case 'cris_ccast'
  case 'cris_idps'
  case 'iasi_l1c'
  case 'airs_l1b'
  case 'airs_l1bcm'
  otherwise
    error(['Wrong dataset value: ' dataset ]);
  end

  switch model
  case 'ecmwf'
  case 'era'
  case 'merra'
  case 'merra_cld'
  otherwise
    error(['Wrong model value: ' model]);
  end

  switch sst
  case ''
  case 'dsst'
  otherwise
    error(['Wrong sst value: ' sst]);
  end


  switch emis
  case 'dan'
  case 'wisc'
  otherwise
    error(['Wrong emis value: ' emis]);
  end


  switch cleartype
  case 'uc'
    otherwise
    error(['Wrong cleartype value: ' cleartype]);
  end

  if(strcmp(fovsset,'clear subset'))
  switch fovsset
  case 'clear subset'
  otherwise
    error(['Wrong fov subset: ' fovsset]);
  end

 
  %freqsset - nothing for it now
  
  switch fpd
  case 24
  case 144
  case 240
  otherwise
    warning('ASL:Warn',['Files per day (fpd) is unusuall: ' num2str(fpd)]);
  end


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal Subroutines
% compute_tblocks_l
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tblocks idbloks] = compute_tblocks_l(dates, fpd)
% function [tblocks idbloks] = compute_tblocks_l(dates, fpd)


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


  % fpd - blocks per block - is the number of blocks we will divide the day
  % dates - start/end matlab dates.
  % 
  % Will return the blocks that fall in the range span by dates, 
  % including the extreme points - 

   
  % Make a discrete time grid based on fpd, 
  % starting at the beginning of the date on dates(1)
  % and ending at the end of the day of dates(2) 
  % (one milisecond before midnight)

  nblocks  = fpd
  dt_block = 1./double(fpd);

  block_grid = floor(dates(1)):dt_block:(ceil(dates(2))-1e-8);

  % Select which of these blocks actually fall into the requeste dates:
  % Find the blocks that 
  % 1) start after dates(1) 
  % 2) end before dates(2)
  iokblock = find(block_grid>dates(1) & block_grid<dates(2));
  
  % To include dates(1), we must then add the previous block

  minblock = min(iokblock);
  if(minblock==1)
    warning('Something may be wrong with time block selection');
  end
  iokblock = [minblock-1 iokblock];

  % The final point, dates(2), is already guaranteed to be in because 
  % we already have all the blocks that begin before dates(2).
  % The only exception is that if dates(2) is exactly an integer number
  % (exactly midnight). In that case we will miss it by a millisecond.

  tblocks = block_grid(iokblock);
  idbloks = mod(iokblock-1,fpd)+1;

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal Subroutines
% make_rtp_run_output_fname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function fname = make_rtp_run_output_fname_l(tblock, index,...
     		   dataset, model, emis, sst, output, cleartype, fovsset,...
		   freqsset, fdp,...
		   version);

% construct the output filename

  fname = '';

  % Add output location (path)
  if(numel(output)==0); 
    output = '.';
  end
  if(output(end)~='/')
    output = [output '/'];
  end

  fname = output 

  % Add dataset
  fname = [fname dataset ];

  % All other fields will have dots in between

  if(numel(model)>0)
    fname = [fname '.' model];
  end


  if(numel(sst)>0); 
    fname = [fname '.' sst];
  end

  if(numel(emis)>0); 
    fname = [fname '.' emis];
  end

  if(numel(fovsset)>0)
    fname = [fname '.' fovset];
  end

  if(numel(freqsset))
    fname = [fname '.' freqsset];
  end

  date = datevec(tblock);

  fname = [fname '.' sprintf('%04d.%02d.%02d',date(1),date(2),date(3))];

  if(fdp==24)
    fname = [fname '.' num2str(index,'%02d')];
  else
    fname = [fname '.' num2str(index,'%03d')];
  end

  fname = [fname '.' version ];

  fname = [fname '.rtp'];



end




function [head hattr prof pattr] = rtpmake_ccast_datafiles(file_list)

  head = []; hattr = [];
  prof = []; pattr = [];
  
  % Load files into an array
  for ifile=1:length(file_list)
    [head hattr profi pattr] = sdr2rtp_bc(file_list{ifile});

    if(ifile==1)
      prof = profi;
    else
      prof(ifile) = profi;
    end
  end
  % Check if there was any good read
  if(numel(prof)==0)
    disp('No prof structure (no SDR files loaded) !');
    return
  end
  % Flatten the array
  prof = structmerge(prof,2);
end


function [head hattr prof pattr] = rtpmake_idps_datafiles(file_list)

  head = []; hattr = [];
  prof = []; pattr = [];
  
  % Load files into an array
  for ifile=1:length(file_list)
    [head hattr profi pattr] = sdr2rtp_h5(file_list{ifile});

    if(ifile==1)
      prof = profi;
    else
      prof(ifile) = profi;
    end
  end
  % Check if there was any good read
  if(numel(prof)==0)
    disp('No prof structure (no SDR files loaded) !');
    return
  end
  % Flatten the array
  prof = structmerge(prof,2);
end



function [head hattr prof pattr] = rtpmake_iasi_l1c_datafiles(file_list)

  allfov = true;

  [head, hattr, prof, pattr, summary, isubset] = iasi_uniform_and_allfov_func_list(mask,allfov);

end





%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%   % time length (in days) of each block
%   dt_block = 1./nblocks;
% 
%   % compute start 
%   startday  = floor(dates(1));
%   starttime = dates(1)-startday;
%   endtime   = dates(2)-startday;
% 
%   % Make time block start times
%   tblock = [startday:dt_block:dt_block.*nblocks];
% 
%      
% 
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%   % Find which entried of 'span' match these times:
%   iokspan = find(idx_block>=floor(starttime*nblocks) & idx_block<ceil(endtime*nblocks));
% 
%    
%   if(numel(iokspan)==0)
%     disp(['No time block selected: ' datestr(starttime,'HH:MM:SS') ' - ' datestr(endtime,'HH:MM:SS') ]);
%     disp(rtpset)
%     disp(span);
%     disp(starttime*day2span)
%     disp(endtime*day2span);
%   end
% 
%   idx_block = idx_block(iokspan);
% 
%   
% end
% 
% 
% 
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   % Check input arguments
% 
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%   % Setup time blocks
%   % Time blocks are the divisions of the day (24hr)
%   % that we accumulate in.
%   % 
%   % nblocks	duration	instrument
%   %
%   % 240		6 mins		AIRS all fovs (no clear subset)
%   % 180		8 mins		CRIS original granule break out
%   % 144		10 mins		CRIS 10 mins/day files ( 103x )
%   % 24		1 hr		clear subset files
%   %
%   % span == nblocks
% 
%   if(strcmp(fovsset,'uniform clear'))
%     nblocks = 24;
%   else 
%     if(strcmp(instrument,'airs'))
%       nblocks = 240;
%     elseif(strcmp(instrument,'iasi'))
%       nblocks = 144;
%     elseif(strcmp(instrument,'cris'))
%       nblocks = 144;
%     else
%       error('Cannot define nblocks');
%     end
%   end
% 
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%   % time length (in days) of each block
%   dt_block = 1./nblocks;
% 
%   %idx_block = [0:nblocks-1];  % span, nblock=day2span
% 
%   
%   % Compute blocks - the start l
% 

