function filename = make_rtprod_filename(instr, sat_data, atm_model, surfflags, calc, subset, mdate, ver, file_type, root);
%function filename = make_rtprod_filename(instr,sat_data, atm_model, surfflags, calc, subset, mdate, file_type, root);
%
% Create a systematic RTP Prod file name
%
% Example:
%   instr = Instrument name (case insensitive) 	- 'cris'
%   sat_data = Satelite data label             	- 'sdr60_noaa_ops'
%   atm_model = Atm Model name                 	- 'merra'
%   surfflags = Surface flags                  	- 'udz'
%                      1. Topography: 'u' - usgs      / '_' - none
%                      2. Stemp     : 'd' - diurnal   / 'm' - model default
%                      3. Emissivity: 'z' - DanZhou's / 'w' - Wiscounsin
%   calc = Calculation string 			- 'calc'
%   subset = Subsetting string 			- 'subset'
%   mdate(:)  =  matlab [start end] time for the data (end time is optional).
%                				- datenum(2012,09,20,[0 1],0,0)
%   ver = Version string 			- 'Rv1.A-Mv1.2'
%   file_type = File extension 			- 'rtp'
%   root = Root data location 			- '/asl'
% 
% This routine will evolve - Breno Imbiriba - 2013.07.30 


  % Construct timestamp and data strings
  [yyyy mm dd HH MM SS] = timestring(mdate(1));
  gg = [HH MM SS];

  if(numel(mdate)>1)
    [yyy2 m2 d2 H2 M2 S2] = timestring(mdate(2));
    gg = [HH MM SS '_' H2 M2 S2];
  end


  % Set up output directory
  if(strcmpi(instr,'cris'))

    %sdr60_noaa_ops.merra.subset.2012.09.29.21.Rv2.0-Mv2.0.rtp
    %sdr60_noaa_ops.merra.calc.subset.yyyy.mm.dd.gg.RvTag-MvTag.rtpZ

    dirname = [root '/data/rtprod_cris/' yyyy '/' mm '/' dd '/'];
    

  elseif(strcmpi(instr,'airs'))

    dirname = [root '/data/rtprod_airs/' yyyy '/' mm '/' dd '/'];
    
  elseif(strcmpi(instr,'iasi'))

    dirname = [root '/data/rtprod_iasi/' yyyy '/' mm '/' dd '/'];
    
  else
    error(['Unknow instrument name: ' instr '.']);
  end

%    filename = [dirname concatdot(sat_data, atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];
%    filename = [dirname concatdot([lower(instr) '_' sat_data], atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];

    filename = [dirname concatdot([lower(instr) '_' sat_data], atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];


end

function [yyyy mm dd HH MM SS] = timestring(mdate)
% Return the string of the time components.

    [yyyy mm dd HH MM SS] = datevec(mdate);
    yyyy = num2str(yyyy,'%04d');
    mm = num2str(mm,'%02d');
    dd = num2str(dd,'%02d');
    HH = num2str(HH,'%02d');
    MM = num2str(MM,'%02d');
    SS = num2str(SS,'%02d');
end


function str=concatdot(varargin)
  str='';
  for ic=1:nargin-1
    if(length(varargin{ic})>0)
      str=[str varargin{ic} '.'];
    end
  end
  str=[str varargin{ic+1}];
  if(length(str)>0)
    if(str(end:end)=='.')
      str=str(1:end-1);
    end
  end
end

